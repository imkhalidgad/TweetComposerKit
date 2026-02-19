import Foundation

/// Repository implementation: posts tweets via the Network Layer using Twitter API v2.
public final class TwitterAPIRepository: TwitterPosting, @unchecked Sendable {
    private let networkClient: NetworkClientProtocol
    private let authManager: any TwitterAuthenticating

    public init(
        networkClient: NetworkClientProtocol,
        authManager: any TwitterAuthenticating
    ) {
        self.networkClient = networkClient
        self.authManager = authManager
    }

    public func postTweet(text: String) async throws {
        let token: String
        do {
            token = try await authManager.accessToken()
        } catch {
            throw error is TweetComposerError ? error : TweetComposerError.notAuthenticated
        }

        do {
            _ = try await networkClient.request(
                TwitterAPI.postTweet(text: text, bearerToken: token),
                responseType: PostTweetResponseDTO.self
            )
        } catch let networkError as NetworkError {
            throw map(networkError)
        } catch {
            throw TweetComposerError.networkError(error.localizedDescription)
        }
    }

    private func map(_ error: NetworkError) -> TweetComposerError {
        switch error {
        case .httpStatus(let statusCode, let data):
            let message = data.flatMap { String(data: $0, encoding: .utf8) } ?? error.localizedDescription
            return .apiError(statusCode: statusCode, message: message)
        case .urlSessionError, .timeout:
            return .networkError(error.localizedDescription)
        case .decodingError, .encodingError, .invalidURL, .invalidHTTPResponse, .unknown:
            return .networkError(error.localizedDescription)
        }
    }
}
