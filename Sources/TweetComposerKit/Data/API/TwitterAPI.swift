import Foundation

/// Twitter API v2 endpoints. Used by the Data layer with the Network Layer.
enum TwitterAPI: APIEndPoint {
    case postTweet(text: String, bearerToken: String)

    var path: String {
        switch self {
        case .postTweet:
            return "2/tweets"
        }
    }

    var httpMethod: HTTPMethod {
        switch self {
        case .postTweet:
            return .post
        }
    }

    var parameters: [String: Any]? {
        switch self {
        case .postTweet(let text, _):
            return ["text": text]
        }
    }

    var headers: [String: String]? {
        switch self {
        case .postTweet(_, let bearerToken):
            return ["Authorization": "Bearer \(bearerToken)"]
        }
    }
}
