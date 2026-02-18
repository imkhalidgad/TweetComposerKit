import Foundation

// MARK: - Protocol

public protocol TweetValidating: Sendable {
    func canSendTweet(_ text: String) -> Bool
}

// MARK: - Implementation

/// Validates whether a tweet can be sent by combining length checking
/// with content validation (e.g. rejecting whitespace-only tweets).
public final class TweetValidator: TweetValidating, Sendable {
    private let calculator: TweetLengthCalculator

    public init(calculator: TweetLengthCalculator) {
        self.calculator = calculator
    }

    public func canSendTweet(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && calculator.isValidTweet(text)
    }
}
