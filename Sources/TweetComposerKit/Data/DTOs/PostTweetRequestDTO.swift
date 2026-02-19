import Foundation

/// Request body for Twitter API v2 POST /2/tweets.
struct PostTweetRequestDTO: Encodable, Sendable {
    let text: String

    enum CodingKeys: String, CodingKey {
        case text
    }
}
