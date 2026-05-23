// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LLMChatCore",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "LLMChatCore",
            targets: ["LLMChatCore"]
        )
    ],
    targets: [
        .target(
            name: "LLMChatCore",
            path: "Sources/OllamaChatCore",
            exclude: ["Info.plist"]
        ),
        .testTarget(
            name: "LLMChatCoreTests",
            dependencies: ["LLMChatCore"],
            path: "Tests/Core"
        )
    ]
)