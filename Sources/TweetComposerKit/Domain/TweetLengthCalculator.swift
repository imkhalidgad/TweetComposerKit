import Foundation

// MARK: - Protocol

public protocol TweetLengthCalculating: Sendable {
    func weightedLength(for text: String) -> Int
    func remainingCharacters(for text: String) -> Int
    func isValidTweet(_ text: String) -> Bool
}

// MARK: - Implementation

/// Calculates tweet length following the official twitter-text v3 weighted rules:
///
/// 1. Text is NFC-normalized before processing.
/// 2. URLs (detected via `NSDataDetector`) always count as 23 regardless of length.
/// 3. Emoji grapheme clusters (flags, ZWJ sequences, skin tones) count as 2.
/// 4. Remaining characters are weighted per code point using the twitter-text v3
///    config ranges: most Latin/Arabic/Cyrillic = 1, CJK/Hangul/Katakana = 2.
public final class TweetLengthCalculator: TweetLengthCalculating, Sendable {
    private let urlDetector: URLDetector
    private let emojiDetector: EmojiDetector

    public init() {
        self.urlDetector = URLDetector()
        self.emojiDetector = EmojiDetector()
    }

    public func weightedLength(for text: String) -> Int {
        guard !text.isEmpty else { return 0 }

        let normalized = text.precomposedStringWithCanonicalMapping
        let urlRanges = urlDetector.detectURLs(in: normalized)

        var textWithoutURLs = normalized
        for range in urlRanges.sorted(by: { $0.lowerBound > $1.lowerBound }) {
            textWithoutURLs.removeSubrange(range)
        }

        var weight = 0
        for character in textWithoutURLs {
            weight += characterWeight(character)
        }

        weight += urlRanges.count * TwitterTextConfiguration.urlLength

        return weight
    }

    public func remainingCharacters(for text: String) -> Int {
        TwitterTextConfiguration.maxLength - weightedLength(for: text)
    }

    public func isValidTweet(_ text: String) -> Bool {
        let length = weightedLength(for: text)
        return length > 0 && length <= TwitterTextConfiguration.maxLength
    }

    // MARK: - Private

    /// Emoji clusters get a flat weight of 2.
    /// Non-emoji characters: sum the per-scalar weight from the config ranges.
    private func characterWeight(_ character: Character) -> Int {
        if emojiDetector.isEmoji(character) {
            return TwitterTextConfiguration.emojiWeight
        }
        var total = 0
        for scalar in character.unicodeScalars {
            total += TwitterTextConfiguration.weight(of: scalar)
        }
        return total
    }
}
