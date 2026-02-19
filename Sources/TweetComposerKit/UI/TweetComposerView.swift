import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A reusable, self-contained tweet composer component.
///
/// Includes character counting (matching Twitter's weighted algorithm),
/// validation, copy/clear actions, and tweet posting.
///
/// All dependencies are injected — the component carries no hardcoded
/// networking or credential references.
///
/// ```swift
/// let calculator = TweetLengthCalculator()
/// let validator  = TweetValidator(calculator: calculator)
/// let client     = TwitterAPIClient(authManager: authManager)
///
/// TweetComposerView(
///     calculator: calculator,
///     validator: validator,
///     poster: client
/// )
/// ```
@MainActor
public struct TweetComposerView: View {
    @StateObject private var viewModel: TweetComposerViewModel

    // MARK: - Initializers

    public init(
        calculator: any TweetLengthCalculating,
        validator: any TweetValidating,
        poster: any TwitterPosting
    ) {
        _viewModel = StateObject(
            wrappedValue: TweetComposerViewModel(
                calculator: calculator,
                validator: validator,
                poster: poster
            )
        )
    }

    public init(viewModel: TweetComposerViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            headerBar

            Divider()

            ScrollView {
                VStack(spacing: 24) {
                    twitterLogo
                        .padding(.top, 8)

                    CharacterCounterView(
                        typed: viewModel.charactersTyped,
                        remaining: viewModel.remainingCharacters
                    )

                    editorSection

                    actionButtons

                    postButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .alert("Tweet posted!", isPresented: $viewModel.didSendSuccessfully) {
            Button("OK", role: .cancel) {}
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            ),
            presenting: viewModel.error
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { error in
            Text(error.localizedDescription)
        }
    }

    // MARK: - Subviews

    private var headerBar: some View {
        HStack {
            Spacer()

            Text("Twitter character count")
                .font(.headline)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var twitterLogo: some View {
        #if canImport(UIKit)
        if let uiImage = UIImage(named: "Twitter logo") {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(height: 55)
        } else if #available(iOS 17.0, visionOS 1.0, *) {
            Image(systemName: "bird.fill")
                .resizable()
                .scaledToFit()
                .frame(height: 55)
                .foregroundStyle(TweetComposerColors.twitterBlue)
        } else {
            Image(systemName: "bubble.left.fill")
                .resizable()
                .scaledToFit()
                .frame(height: 55)
                .foregroundStyle(TweetComposerColors.twitterBlue)
        }
        #elseif canImport(AppKit)
        if let nsImage = NSImage(named: "Twitter logo") {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFit()
                .frame(height: 55)
        } else {
            Image(systemName: "bird.fill")
                .resizable()
                .scaledToFit()
                .frame(height: 55)
                .foregroundStyle(TweetComposerColors.twitterBlue)
        }
        #endif
    }

    private var editorSection: some View {
        ZStack(alignment: .topLeading) {
            if viewModel.text.isEmpty {
                Text("Start typing! You can enter up to 280 characters")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.top, 14)
            }

            TextEditor(text: $viewModel.text)
                .scrollContentBackground(.hidden)
                .font(.body)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
        }
        .frame(minHeight: 180)
        .background(.background)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }

    private var actionButtons: some View {
        HStack {
            Button {
                copyToClipboard()
            } label: {
                Text("Copy Text")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(TweetComposerColors.copyGreen))
            }
            .disabled(viewModel.text.isEmpty)

            Spacer()

            Button {
                viewModel.clearText()
            } label: {
                Text("Clear Text")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(TweetComposerColors.clearRed))
            }
            .disabled(viewModel.text.isEmpty)
        }
    }

    private var postButton: some View {
        Button {
            Task { await viewModel.sendTweet() }
        } label: {
            Group {
                if viewModel.isSending {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Post tweet")
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .foregroundStyle(.white)
        .background(
            RoundedRectangle(cornerRadius: 12).fill(TweetComposerColors.postBlue)
        )
        .disabled(!viewModel.isValid || viewModel.isSending)
        .opacity(viewModel.isValid && !viewModel.isSending ? 1.0 : 0.6)
    }

    // MARK: - Helpers

    private func copyToClipboard() {
        #if canImport(UIKit)
        UIPasteboard.general.string = viewModel.text
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(viewModel.text, forType: .string)
        #endif
    }
}
