import XCTest
@testable import TweetComposerKit

// MARK: - TweetLengthCalculator Tests

final class TweetLengthCalculatorTests: XCTestCase {
    private var calculator: TweetLengthCalculator!

    override func setUp() {
        super.setUp()
        calculator = TweetLengthCalculator()
    }

    override func tearDown() {
        calculator = nil
        super.tearDown()
    }

    // MARK: - Plain ASCII Text (weight 1 per character)

    func testPlainText() {
        XCTAssertEqual(calculator.weightedLength(for: "hello"), 5)
    }

    func testSingleCharacter() {
        XCTAssertEqual(calculator.weightedLength(for: "a"), 1)
    }

    func testSpaces() {
        XCTAssertEqual(calculator.weightedLength(for: "hello world"), 11)
    }

    func testNewLine() {
        XCTAssertEqual(calculator.weightedLength(for: "hello\nworld"), 11)
    }

    func testDigitsAreWeightOne() {
        XCTAssertEqual(calculator.weightedLength(for: "12345"), 5)
    }

    // MARK: - Emoji (weight 2 per grapheme cluster)

    func testSingleEmoji() {
        XCTAssertEqual(calculator.weightedLength(for: "😀"), 2)
    }

    func testMultipleEmojis() {
        XCTAssertEqual(calculator.weightedLength(for: "😀🎉🔥"), 6)
    }

    func testFlagEmoji() {
        XCTAssertEqual(calculator.weightedLength(for: "🇺🇸"), 2)
    }

    func testFamilyEmoji() {
        XCTAssertEqual(calculator.weightedLength(for: "👨‍👩‍👧‍👦"), 2)
    }

    func testSkinToneEmoji() {
        XCTAssertEqual(calculator.weightedLength(for: "👍🏽"), 2)
    }

    func testTextAndEmoji() {
        // "Hi " = 3, "😀" = 2
        XCTAssertEqual(calculator.weightedLength(for: "Hi 😀"), 5)
    }

    // MARK: - CJK Characters (weight 2, above U+10FF)

    func testChineseText() {
        // 你(U+4F60) + 好(U+597D) = 2 × 2 = 4
        XCTAssertEqual(calculator.weightedLength(for: "你好"), 4)
    }

    func testJapaneseHiragana() {
        // こんにちは = 5 chars × 2 = 10
        XCTAssertEqual(calculator.weightedLength(for: "こんにちは"), 10)
    }

    func testKoreanText() {
        // 안(U+C548) + 녕(U+B155) = 2 × 2 = 4
        XCTAssertEqual(calculator.weightedLength(for: "안녕"), 4)
    }

    func testCJKExactlyMaxLength() {
        // 140 CJK chars × 2 = 280 (exactly the limit)
        let text = String(repeating: "你", count: 140)
        XCTAssertTrue(calculator.isValidTweet(text))
        XCTAssertEqual(calculator.weightedLength(for: text), 280)
    }

    func testCJKOverflow() {
        // 141 CJK chars × 2 = 282 (over limit)
        let text = String(repeating: "你", count: 141)
        XCTAssertFalse(calculator.isValidTweet(text))
    }

    // MARK: - Arabic (weight 1, in U+0600–U+06FF range ⊂ 0–4351)

    func testArabicText() {
        // مرحبا = 5 Arabic chars, each in 0–4351 range → weight 1 each = 5
        XCTAssertEqual(calculator.weightedLength(for: "مرحبا"), 5)
    }

    func testArabicSentence() {
        // 12 chars (including spaces) → 12
        XCTAssertEqual(calculator.weightedLength(for: "مرحبا بالعالم"), 13)
    }

    // MARK: - URLs (always 23)

    func testSingleURL() {
        XCTAssertEqual(
            calculator.weightedLength(for: "https://google.com/very/long/url/path"),
            TwitterTextConfiguration.urlLength
        )
    }

    func testHTTPURL() {
        XCTAssertEqual(
            calculator.weightedLength(for: "http://example.com"),
            TwitterTextConfiguration.urlLength
        )
    }

    func testMultipleURLs() {
        let text = "https://example.com https://google.com"
        // URL(23) + space(1) + URL(23) = 47
        XCTAssertEqual(calculator.weightedLength(for: text), 47)
    }

    func testTextWithURL() {
        let text = "Check this https://example.com"
        // "Check this " = 11, URL = 23
        XCTAssertEqual(calculator.weightedLength(for: text), 34)
    }

    // MARK: - Mixed Content

    func testEmojiAndURL() {
        let text = "Hello 😀 https://google.com/very/long/url"
        // "Hello "(6) + 😀(2) + " "(1) + URL(23) = 32
        XCTAssertEqual(calculator.weightedLength(for: text), 32)
    }

    func testEmojiAndASCIIAndURL() {
        let text = "I love 🍕! Check out https://pizza.com"
        // "I love "(7) + 🍕(2) + "! Check out "(12) + URL(23) = 44
        XCTAssertEqual(calculator.weightedLength(for: text), 44)
    }

    func testAllLanguagesMixed() {
        let text = "Hello 😀 مرحبا https://google.com"
        // "Hello "(6) + 😀(2) + " "(1) + "مرحبا"(5) + " "(1) + URL(23) = 38
        XCTAssertEqual(calculator.weightedLength(for: text), 38)
    }

    func testCJKWithURL() {
        let text = "你好 https://example.com"
        // 你(2) + 好(2) + " "(1) + URL(23) = 28
        XCTAssertEqual(calculator.weightedLength(for: text), 28)
    }

    // MARK: - Edge Cases

    func testEmptyText() {
        XCTAssertEqual(calculator.weightedLength(for: ""), 0)
    }

    func testOnlySpaces() {
        XCTAssertEqual(calculator.weightedLength(for: "   "), 3)
    }

    func testRemainingForEmpty() {
        XCTAssertEqual(calculator.remainingCharacters(for: ""), 280)
    }

    func testRemainingForPlainText() {
        XCTAssertEqual(calculator.remainingCharacters(for: "hello"), 275)
    }

    func testRemainingGoesNegative() {
        let text = String(repeating: "a", count: 300)
        XCTAssertEqual(calculator.remainingCharacters(for: text), -20)
    }

    // MARK: - Validation

    func testExactlyMaxLengthIsValid() {
        let text = String(repeating: "a", count: 280)
        XCTAssertTrue(calculator.isValidTweet(text))
    }

    func testOneOverMaxLengthIsInvalid() {
        let text = String(repeating: "a", count: 281)
        XCTAssertFalse(calculator.isValidTweet(text))
    }

    func testEmptyIsInvalid() {
        XCTAssertFalse(calculator.isValidTweet(""))
    }

    func testWhitespaceOnlyIsValidByCalculator() {
        XCTAssertTrue(calculator.isValidTweet("   "))
    }
}

// MARK: - TweetValidator Tests

final class TweetValidatorTests: XCTestCase {
    private var validator: TweetValidator!

    override func setUp() {
        super.setUp()
        validator = TweetValidator(calculator: TweetLengthCalculator())
    }

    override func tearDown() {
        validator = nil
        super.tearDown()
    }

    func testValidTweet() {
        XCTAssertTrue(validator.canSendTweet("Hello world"))
    }

    func testEmptyTweet() {
        XCTAssertFalse(validator.canSendTweet(""))
    }

    func testWhitespaceOnlyTweet() {
        XCTAssertFalse(validator.canSendTweet("   \n  "))
    }

    func testTooLongTweet() {
        let text = String(repeating: "a", count: 281)
        XCTAssertFalse(validator.canSendTweet(text))
    }

    func testExactMaxLengthTweet() {
        let text = String(repeating: "a", count: 280)
        XCTAssertTrue(validator.canSendTweet(text))
    }

    func testEmojiOnlyTweet() {
        XCTAssertTrue(validator.canSendTweet("😀"))
    }

    func testURLOnlyTweet() {
        XCTAssertTrue(validator.canSendTweet("https://example.com"))
    }

    func testCJKMaxLength() {
        let text = String(repeating: "你", count: 140)
        XCTAssertTrue(validator.canSendTweet(text))
    }

    func testCJKOverMax() {
        let text = String(repeating: "你", count: 141)
        XCTAssertFalse(validator.canSendTweet(text))
    }
}

// MARK: - EmojiDetector Tests

final class EmojiDetectorTests: XCTestCase {
    private let detector = EmojiDetector()

    func testSimpleEmoji() {
        XCTAssertTrue(detector.isEmoji("😀"))
    }

    func testFlagEmoji() {
        XCTAssertTrue(detector.isEmoji("🇺🇸"))
    }

    func testFamilyEmoji() {
        XCTAssertTrue(detector.isEmoji("👨‍👩‍👧‍👦"))
    }

    func testSkinTone() {
        XCTAssertTrue(detector.isEmoji("👍🏽"))
    }

    func testRegularLetter() {
        XCTAssertFalse(detector.isEmoji("A"))
    }

    func testDigit() {
        XCTAssertFalse(detector.isEmoji("5"))
    }

    func testPunctuation() {
        XCTAssertFalse(detector.isEmoji("."))
    }

    func testSpace() {
        XCTAssertFalse(detector.isEmoji(" "))
    }

    func testArabicLetter() {
        XCTAssertFalse(detector.isEmoji("م"))
    }

    func testCJKCharacter() {
        XCTAssertFalse(detector.isEmoji("你"))
    }
}
