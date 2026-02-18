import Foundation

protocol URLDetecting: Sendable {
    func detectURLs(in text: String) -> [Range<String.Index>]
}

struct URLDetector: URLDetecting {
    private static let detector = try! NSDataDetector(
        types: NSTextCheckingResult.CheckingType.link.rawValue
    )

    func detectURLs(in text: String) -> [Range<String.Index>] {
        let nsRange = NSRange(text.startIndex..., in: text)
        return Self.detector
            .matches(in: text, options: [], range: nsRange)
            .compactMap { Range($0.range, in: text) }
    }
}
