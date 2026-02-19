import SwiftUI

public enum TweetComposerColors {
    public static let babyBlue    = Color(hex: 0xE6F6FE)
    public static let copyGreen   = Color(hex: 0x00A970)
    public static let clearRed    = Color(hex: 0xDC0125)
    public static let postBlue    = Color(hex: 0x1DA1F2)
    public static let twitterBlue = Color(hex: 0x1DA1F2)
}

extension Color {
    init(hex: UInt) {
        self.init(
            red:   Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8)  & 0xFF) / 255.0,
            blue:  Double( hex        & 0xFF) / 255.0
        )
    }
}
