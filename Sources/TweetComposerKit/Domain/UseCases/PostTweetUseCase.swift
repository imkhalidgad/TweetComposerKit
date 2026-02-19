import Foundation

/// Use case: post a tweet. Depends on the Twitter posting repository (Domain protocol).
public final class PostTweetUseCase: Sendable {
    private let twitterPosting: any TwitterPosting

    public init(twitterPosting: any TwitterPosting) {
        self.twitterPosting = twitterPosting
    }

    public func execute(text: String) async throws {
        try await twitterPosting.postTweet(text: text)
    }
}
