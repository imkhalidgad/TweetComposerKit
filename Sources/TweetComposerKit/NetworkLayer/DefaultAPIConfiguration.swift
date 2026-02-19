import Foundation

/// Default implementation of `APIConfiguration`.
public struct DefaultAPIConfiguration: APIConfiguration, Sendable {
    public let baseURL: URL
    public let defaultHeaders: [String: String]
    public let timeoutInterval: TimeInterval

    public init(
        baseURL: URL,
        defaultHeaders: [String: String] = [:],
        timeoutInterval: TimeInterval = 30
    ) {
        self.baseURL = baseURL
        self.defaultHeaders = defaultHeaders
        self.timeoutInterval = timeoutInterval
    }
}
