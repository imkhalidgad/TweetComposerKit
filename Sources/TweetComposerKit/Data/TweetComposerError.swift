import Foundation

public enum TweetComposerError: LocalizedError, Sendable {
    case notAuthenticated
    case invalidTweet
    case tweetTooLong
    case emptyTweet
    case networkError(String)
    case authenticationFailed(String)
    case apiError(statusCode: Int, message: String)

    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            "Not authenticated. Please log in first."
        case .invalidTweet:
            "Invalid tweet."
        case .tweetTooLong:
            "Tweet exceeds the \(TwitterTextConfiguration.maxLength)-character limit."
        case .emptyTweet:
            "Tweet cannot be empty."
        case .networkError(let reason):
            "Network error: \(reason)"
        case .authenticationFailed(let reason):
            "Authentication failed: \(reason)"
        case .apiError(let statusCode, let message):
            "API error (\(statusCode)): \(message)"
        }
    }
}
