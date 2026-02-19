import Foundation
import Combine

/// Drives the TweetComposerView by managing text state, character counting,
/// validation, and tweet posting through injected dependencies.
@MainActor
public final class TweetComposerViewModel: ObservableObject {
    @Published public var text: String = "" {
        didSet { recalculate() }
    }
    @Published public private(set) var charactersTyped: Int = 0
    @Published public private(set) var remainingCharacters: Int
    @Published public private(set) var isValid: Bool = false
    @Published public private(set) var isSending: Bool = false
    @Published public var didSendSuccessfully: Bool = false
    @Published public var error: TweetComposerError?

    private let calculator: any TweetLengthCalculating
    private let validator: any TweetValidating
    private let postTweetUseCase: PostTweetUseCase

    public init(
        calculator: any TweetLengthCalculating,
        validator: any TweetValidating,
        poster: any TwitterPosting
    ) {
        self.calculator = calculator
        self.validator = validator
        self.postTweetUseCase = PostTweetUseCase(twitterPosting: poster)
        self.remainingCharacters = TwitterTextConfiguration.maxLength
    }

    public init(
        calculator: any TweetLengthCalculating,
        validator: any TweetValidating,
        postTweetUseCase: PostTweetUseCase
    ) {
        self.calculator = calculator
        self.validator = validator
        self.postTweetUseCase = postTweetUseCase
        self.remainingCharacters = TwitterTextConfiguration.maxLength
    }

    // MARK: - Actions

    public func sendTweet() async {
        guard isValid, !isSending else { return }

        isSending = true
        error = nil
        didSendSuccessfully = false

        do {
            try await postTweetUseCase.execute(text: text)
            didSendSuccessfully = true
            text = ""
        } catch let tweetError as TweetComposerError {
            error = tweetError
        } catch {
            self.error = .networkError(error.localizedDescription)
        }

        isSending = false
    }

    public func clearText() {
        text = ""
    }

    // MARK: - Private

    private func recalculate() {
        let weighted = calculator.weightedLength(for: text)
        charactersTyped = weighted
        remainingCharacters = TwitterTextConfiguration.maxLength - weighted
        isValid = validator.canSendTweet(text)
    }
}
