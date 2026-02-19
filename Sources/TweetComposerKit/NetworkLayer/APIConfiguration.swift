import Foundation

/// Configuration for the network layer: base URL, default headers, and timeout.
public protocol APIConfiguration: Sendable {
    var baseURL: URL { get }
    var defaultHeaders: [String: String] { get }
    var timeoutInterval: TimeInterval { get }
}
