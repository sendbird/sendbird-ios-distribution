// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "SendbirdUIComponents",
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
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-cmark", from: "0.4.0")
    ],
    targets: [
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
        )
    ]
)
