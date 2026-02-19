import Foundation

/// Describes an API endpoint: path, method, optional body/query and headers.
public protocol APIEndPoint: Sendable {
    var path: String { get }
    var httpMethod: HTTPMethod { get }
    var parameters: [String: Any]? { get }
    var headers: [String: String]? { get }
}
