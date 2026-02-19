import Foundation

/// Twitter API v2 configuration for the Network Layer.
public enum TwitterAPIConfiguration {

    /// Default configuration for https://api.twitter.com with JSON content type.
    public static func `default`(
        timeoutInterval: TimeInterval = 30
    ) -> APIConfiguration {
        guard let baseURL = URL(string: "https://api.twitter.com") else {
            fatalError("Invalid Twitter API base URL")
        }
        return DefaultAPIConfiguration(
            baseURL: baseURL,
            defaultHeaders: ["Content-Type": "application/json"],
            timeoutInterval: timeoutInterval
        )
    }
}
