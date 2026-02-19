import Foundation

/// Domain protocol for posting a tweet. Implemented by the Data layer.
public protocol TwitterPosting: Sendable {
    func postTweet(text: String) async throws
}
