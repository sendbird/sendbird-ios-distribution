// swift-tools-version:5.7

import PackageDescription

// SendbirdMarkdownUI / SendbirdNetworkImage 는 바이너리로 배포한다.
//
// Xcode 27 의 iOS SDK 는 최소 배포 타깃이 15.0 이라, 소스 패키지는 iOS 14 로
// 빌드되지 않는다. 그러면 SendbirdAIAgentCore 의 swiftinterface(ios14.0)를
// 재컴파일할 때 "module has a minimum deployment target of iOS 15.0" 으로 실패한다.
// xcframework 안의 swiftinterface 는 -target arm64-apple-ios14.0 으로 고정돼 있어
// 그 재컴파일을 통과한다.
//
// xcframework 는 scripts/build_xcframeworks.sh 가 Xcode 26 으로 만들고, 이 패키지의
// 릴리즈 태그(예: 1.0.0)에 zip 으로 올린다. Splash.xcframework.zip 도 같은 릴리즈에
// 올리지만, 그 binaryTarget 은 delight-ai-agent-core-ios 의 Package.swift 가 선언한다.
// cmark-gfm 은 SendbirdMarkdownUI 안에 정적으로 흡수돼 있어 별도 의존이 없다.
//
// CocoaPods 경로는 이 파일과 무관하다. Specs/ 의 podspec 은 계속 소스를 쓴다.

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
        )
    ],
    targets: [
        .binaryTarget(
            name: "SendbirdMarkdownUI",
            url: "https://github.com/sendbird/sendbird-ios-distribution/releases/download/1.0.0/SendbirdMarkdownUI.xcframework.zip",
            checksum: "29512d33ecd5c1044a6d145f8a2cf453b75892b4207cd2ea019c0e4b3643afc3"
        ),
        .binaryTarget(
            name: "SendbirdNetworkImage",
            url: "https://github.com/sendbird/sendbird-ios-distribution/releases/download/1.0.0/SendbirdNetworkImage.xcframework.zip",
            checksum: "6be354cd9abadc8c6ce596abde72fbd48cabb028426bcb4f28c305ef6e1b1271"
        )
    ]
)
