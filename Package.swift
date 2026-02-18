// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "TweetComposerKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "TweetComposerKit",
            targets: ["TweetComposerKit"]
        ),
    ],
    targets: [
        .target(
            name: "TweetComposerKit"
        ),
        .testTarget(
            name: "TweetComposerKitTests",
            dependencies: ["TweetComposerKit"]
        ),
    ]
)
