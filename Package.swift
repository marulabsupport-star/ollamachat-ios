// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OllamaChatCore",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "OllamaChatCore",
            targets: ["OllamaChatCore"]
        )
    ],
    targets: [
        .target(
            name: "OllamaChatCore",
            path: "Sources/OllamaChatCore",
            exclude: ["Info.plist"]
        ),
        .testTarget(
            name: "OllamaChatCoreTests",
            dependencies: ["OllamaChatCore"],
            path: "Tests/Core"
        )
    ]
)