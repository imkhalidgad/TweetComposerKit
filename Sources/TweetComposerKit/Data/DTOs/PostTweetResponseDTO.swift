import Foundation

/// Response from Twitter API v2 POST /2/tweets.
struct PostTweetResponseDTO: Decodable, Sendable {
    let data: TweetDataDTO

    struct TweetDataDTO: Decodable, Sendable {
        let id: String
        let text: String
    }
}
