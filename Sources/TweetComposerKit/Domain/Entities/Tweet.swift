import Foundation

/// Domain entity representing a tweet to be posted (or that was posted).
public struct Tweet: Sendable {
    public let id: String?
    public let text: String

    public init(id: String? = nil, text: String) {
        self.id = id
        self.text = text
    }
}
