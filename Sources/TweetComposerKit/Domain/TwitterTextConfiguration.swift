import Foundation

/// Central configuration matching Twitter's text weighting rules.
///
/// Sourced from the official twitter-text v3 config:
/// https://github.com/twitter/twitter-text/blob/master/config/v3.json
///
/// Key insight: Twitter uses an *inverted* weighting model.
/// The **default** weight for any code point is 2 (200 at scale 100).
/// Only specific Unicode ranges are overridden to weight 1 (100 at scale 100).
public enum TwitterTextConfiguration {
    public static let maxLength = 280
    public static let urlLength = 23
    public static let emojiWeight = 2

    /// Unicode ranges where each code point weighs 1.
    /// Everything outside these ranges weighs 2 (the default).
    ///
    /// Range 0–4351 covers Latin, Greek, Cyrillic, Armenian, Hebrew,
    /// Arabic, Thai, Georgian, and many other scripts.
    /// CJK, Hangul syllables, Hiragana, Katakana, and emoji
    /// are all above this range → weight 2.
    static let weightOneRanges: [ClosedRange<UInt32>] = [
        0...4351,       // U+0000–U+10FF
        8192...8205,    // U+2000–U+200D (spaces, zero-width joiners)
        8208...8223,    // U+2010–U+201F (dashes, quotation marks)
        8242...8247,    // U+2032–U+2037 (prime marks)
    ]

    /// Returns the weight of a single Unicode scalar per twitter-text v3.
    static func weight(of scalar: UnicodeScalar) -> Int {
        let value = scalar.value
        for range in weightOneRanges where range.contains(value) {
            return 1
        }
        return 2
    }
}
