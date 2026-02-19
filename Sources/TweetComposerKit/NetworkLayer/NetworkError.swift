import Foundation

/// Errors produced by the network layer.
public enum NetworkError: Error, LocalizedError, Sendable {
    case urlSessionError(Error)
    case invalidURL
    case decodingError(Error)
    case encodingError(Error)
    case invalidHTTPResponse
    case httpStatus(statusCode: Int, data: Data?)
    case timeout
    case unknown

    public var errorDescription: String? {
        switch self {
        case .urlSessionError(let error):
            return error.localizedDescription
        case .invalidURL:
            return "Invalid URL"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .invalidHTTPResponse:
            return "Invalid HTTP response"
        case .httpStatus(let code, _):
            return "HTTP error (\(code))"
        case .timeout:
            return "Request timeout"
        case .unknown:
            return "Something went wrong"
        }
    }
}
