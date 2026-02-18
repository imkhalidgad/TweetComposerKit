import Foundation

// MARK: - Protocol

public protocol TwitterPosting: Sendable {
    func postTweet(text: String) async throws
}

// MARK: - Implementation

/// Posts tweets using the Twitter API v2 endpoint.
/// Requires an authenticated `TwitterAuthenticating` instance for bearer token access.
public final class TwitterAPIClient: TwitterPosting, @unchecked Sendable {
    private let authManager: any TwitterAuthenticating

    public init(authManager: any TwitterAuthenticating) {
        self.authManager = authManager
    }

    public func postTweet(text: String) async throws {
        let token = try await authManager.accessToken()

        let url = URL(string: "https://api.twitter.com/2/tweets")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body = ["text": text]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TweetComposerError.networkError("Invalid response")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw TweetComposerError.apiError(
                statusCode: httpResponse.statusCode,
                message: message
            )
        }
    }
}
