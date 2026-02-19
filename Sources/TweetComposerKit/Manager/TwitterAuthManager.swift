import Foundation
import AuthenticationServices
import CryptoKit

// MARK: - Protocol

public protocol TwitterAuthenticating: Sendable {
    @MainActor func login() async throws
    func accessToken() async throws -> String
    func logout()
}

// MARK: - Implementation

/// Handles Twitter OAuth 2.0 PKCE authentication flow.
///
/// Flow: generate PKCE parameters → open authorization URL in system browser →
/// receive callback with authorization code → exchange code for access token →
/// store token securely in Keychain.
@MainActor
public final class TwitterAuthManager: NSObject, TwitterAuthenticating, @unchecked Sendable {
    private let credentials: TwitterCredentials
    private let keychain = KeychainManager()
    nonisolated(unsafe) private var authAnchor: ASPresentationAnchor?

    public init(credentials: TwitterCredentials) {
        self.credentials = credentials
        super.init()
    }

    // MARK: - Public API

    public func login() async throws {
        let codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(from: codeVerifier)
        let authURL = buildAuthorizationURL(codeChallenge: codeChallenge)

        #if os(iOS) || os(visionOS)
        authAnchor = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
        #endif

        let callbackURL = try await startAuthSession(url: authURL)
        let code = try extractAuthorizationCode(from: callbackURL)
        let token = try await exchangeCodeForToken(code: code, codeVerifier: codeVerifier)
        try keychain.save(token: token)
    }

    public nonisolated func accessToken() async throws -> String {
        guard let token = keychain.retrieveToken() else {
            throw TweetComposerError.notAuthenticated
        }
        return token
    }

    public nonisolated func logout() {
        keychain.deleteToken()
    }

    // MARK: - PKCE

    private nonisolated func generateCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        return Data(buffer).base64URLEncoded()
    }

    private nonisolated func generateCodeChallenge(from verifier: String) -> String {
        let hash = SHA256.hash(data: Data(verifier.utf8))
        return Data(hash).base64URLEncoded()
    }

    // MARK: - Authorization URL

    private func buildAuthorizationURL(codeChallenge: String) -> URL {
        var components = URLComponents(string: "https://twitter.com/i/oauth2/authorize")!
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: credentials.clientID),
            URLQueryItem(name: "redirect_uri", value: credentials.redirectURI),
            URLQueryItem(name: "scope", value: "tweet.read tweet.write users.read offline.access"),
            URLQueryItem(name: "state", value: UUID().uuidString),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
        ]
        return components.url!
    }

    // MARK: - Auth Session

    private func startAuthSession(url: URL) async throws -> URL {
        let callbackScheme = URL(string: credentials.redirectURI)?.scheme

        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackScheme
            ) { url, error in
                if let error {
                    continuation.resume(
                        throwing: TweetComposerError.authenticationFailed(error.localizedDescription)
                    )
                } else if let url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(
                        throwing: TweetComposerError.authenticationFailed("No callback received")
                    )
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
    }

    // MARK: - Code Extraction

    private nonisolated func extractAuthorizationCode(from url: URL) throws -> String {
        guard
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let code = components.queryItems?.first(where: { $0.name == "code" })?.value
        else {
            throw TweetComposerError.authenticationFailed(
                "Authorization code not found in callback"
            )
        }
        return code
    }

    // MARK: - Token Exchange

    private func exchangeCodeForToken(code: String, codeVerifier: String) async throws -> String {
        let url = URL(string: "https://api.twitter.com/2/oauth2/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let rawCredentials = "\(credentials.clientID):\(credentials.clientSecret)"
        let basicAuth = Data(rawCredentials.utf8).base64EncodedString()
        request.setValue("Basic \(basicAuth)", forHTTPHeaderField: "Authorization")

        let bodyParts = [
            "code": code,
            "grant_type": "authorization_code",
            "redirect_uri": credentials.redirectURI,
            "code_verifier": codeVerifier,
        ]
        request.httpBody = bodyParts
            .map { key, value in
                let escaped = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
                return "\(key)=\(escaped)"
            }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TweetComposerError.networkError("Invalid response")
        }
        guard httpResponse.statusCode == 200 else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw TweetComposerError.apiError(statusCode: httpResponse.statusCode, message: message)
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        return tokenResponse.accessToken
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension TwitterAuthManager: ASWebAuthenticationPresentationContextProviding {
    nonisolated public func presentationAnchor(
        for session: ASWebAuthenticationSession
    ) -> ASPresentationAnchor {
        // authAnchor is always assigned in login() before the session starts
        authAnchor!
    }
}

// MARK: - Token Response Model

private struct TokenResponse: Decodable, Sendable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int?
    let refreshToken: String?
    let scope: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case scope
    }
}

// MARK: - Base64 URL Encoding

extension Data {
    fileprivate func base64URLEncoded() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
