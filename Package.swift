// swift-tools-version: 6.0
// CoworkersNative — Full Native iOS App
// iOS 18.0, Swift 6 strict concurrency
// Backend: coworkers-agent Worker at agentknowledgeworkers.com
// Model: @cf/meta/llama-3.1-8b-instruct via Workers AI (no Anthropic API key)

import PackageDescription

let package = Package(
    name: "CoworkersNative",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(name: "CoworkersNative", targets: ["CoworkersNative"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime",   from: "1.4.0"),
        .package(url: "https://github.com/apple/swift-openapi-urlsession",from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser",   from: "1.5.0"),
    ],
    targets: [
        .target(
            name: "CoworkersNative",
            dependencies: [
                .product(name: "OpenAPIRuntime",    package: "swift-openapi-runtime"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
            ],
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator"),
            ]
        ),
        .testTarget(name: "CoworkersNativeTests", dependencies: ["CoworkersNative"]),
    ]
)