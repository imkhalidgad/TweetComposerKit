import Foundation

protocol EmojiDetecting: Sendable {
    func isEmoji(_ character: Character) -> Bool
}

struct EmojiDetector: EmojiDetecting {
    /// Determines if a character should be counted with emoji weight per Twitter rules.
    ///
    /// Single-scalar emoji with default emoji presentation (e.g. 😀) → true.
    /// Multi-scalar sequences where the first scalar is emoji (flags 🇺🇸,
    /// skin-tone variants 👍🏽, ZWJ families 👨‍👩‍👧‍👦, keycaps #️⃣) → true.
    /// Plain digits/ASCII (single scalar, no emoji presentation) → false.
    func isEmoji(_ character: Character) -> Bool {
        let scalars = character.unicodeScalars
        guard let first = scalars.first else { return false }
        if first.properties.isEmojiPresentation { return true }
        if scalars.count > 1 && first.properties.isEmoji { return true }
        return false
    }
}
