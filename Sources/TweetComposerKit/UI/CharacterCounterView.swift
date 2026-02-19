import SwiftUI

/// Displays tweet character statistics as two side-by-side stat cards.
///
/// - **Characters Typed**: weighted count out of the maximum (e.g. "42/280")
/// - **Characters Remaining**: countdown that turns orange then red near the limit
public struct CharacterCounterView: View {
    private let typed: Int
    private let remaining: Int
    private let maxLength: Int

    public init(
        typed: Int,
        remaining: Int,
        maxLength: Int = TwitterTextConfiguration.maxLength
    ) {
        self.typed = typed
        self.remaining = remaining
        self.maxLength = maxLength
    }

    private var remainingColor: Color {
        switch remaining {
        case 21...: .primary
        case 0...20: .orange
        default: .red
        }
    }

    public var body: some View {
        HStack(spacing: 12) {
            statCard(
                title: "Characters Typed",
                value: "\(typed)/\(maxLength)",
                valueColor: .primary
            )
            statCard(
                title: "Characters Remaining",
                value: "\(remaining)",
                valueColor: remainingColor
            )
        }
    }

    // MARK: - Private

    private func statCard(title: String, value: String, valueColor: Color) -> some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.footnote)
                .fontWeight(.regular)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(TweetComposerColors.babyBlue)

            Divider()

            Text(value)
                .font(.system(size: 26, weight: .medium, design: .rounded))
                .foregroundStyle(valueColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(TweetComposerColors.babyBlue, lineWidth: 1.5)
        )
    }
}
