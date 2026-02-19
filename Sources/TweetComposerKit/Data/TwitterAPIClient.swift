import Foundation

/// Posts tweets via the shared Network Layer. Uses `TwitterAPIRepository` internally
/// so all Twitter API calls go through a single network stack.
public final class TwitterAPIClient: TwitterPosting, @unchecked Sendable {
    private let repository: TwitterAPIRepository

    public init(authManager: any TwitterAuthenticating) {
        let config = TwitterAPIConfiguration.default()
        let networkClient = NetworkClient(configuration: config)
        self.repository = TwitterAPIRepository(
            networkClient: networkClient,
            authManager: authManager
        )
    }

    public init(
        networkClient: NetworkClientProtocol,
        authManager: any TwitterAuthenticating
    ) {
        self.repository = TwitterAPIRepository(
            networkClient: networkClient,
            authManager: authManager
        )
    }

    public func postTweet(text: String) async throws {
        try await repository.postTweet(text: text)
    }
}
