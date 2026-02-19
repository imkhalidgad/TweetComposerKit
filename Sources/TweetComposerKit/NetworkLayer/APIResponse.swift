import Foundation

/// Generic API response wrapper (e.g. for APIs that return `{ data, message, success }`).
public struct APIResponse<T: Codable & Sendable>: Codable, Sendable {
    public let data: T
    public let message: String?
    public let success: Bool?

    public init(data: T, message: String? = nil, success: Bool? = nil) {
        self.data = data
        self.message = message
        self.success = success
    }
}
