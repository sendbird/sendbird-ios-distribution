// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "SendbirdPackages",
    platforms: [
        .macOS(.v12),
        .iOS(.v14),
        .tvOS(.v14),
        .watchOS(.v7),
        .macCatalyst(.v15)
    ],
    products: [
        .library(
            name: "SendbirdMarkdownUI",
            targets: ["SendbirdMarkdownUI"]
        ),
        .library(
            name: "SendbirdNetworkImage",
            targets: ["SendbirdNetworkImage"]
        ),
        .library(
            name: "ExtensionKit",
            targets: ["ExtensionKit"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-cmark", from: "0.4.0")
    ],
    targets: [
        // ExtensionKit Target — cross-SDK shared interfaces (protocols and value
        // types only; no implementation code, no dependencies). VoiceProtocol
        // lives here so AIAgentMessenger and VoiceKit can interoperate without
        // knowing each other.
        .target(
            name: "ExtensionKit",
            path: "Sources/ExtensionKit"
        ),

        // NetworkImage Target
        .target(
            name: "SendbirdNetworkImage",
            path: "Sources/NetworkImage/Sources/NetworkImage"
        ),
        
        // MarkdownUI Target
        .target(
            name: "SendbirdMarkdownUI",
            dependencies: [
                .product(name: "cmark-gfm", package: "swift-cmark"),
                .product(name: "cmark-gfm-extensions", package: "swift-cmark"),
                "SendbirdNetworkImage"
            ],
            path: "Sources/MarkdownUI/Sources/MarkdownUI",
            exclude: [
                "Documentation.docc"
            ]
        ),

        // MarkdownUI Tests (SwiftPM-only; not part of any published product)
        .testTarget(
            name: "SendbirdMarkdownUITests",
            dependencies: ["SendbirdMarkdownUI"],
            path: "Sources/MarkdownUI/Tests/MarkdownUITests"
        )
    ]
)
