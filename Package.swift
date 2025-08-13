// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "OpenAIChatLibrary",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(
            name: "OpenAIChatLibrary",
            targets: ["OpenAIChatLibrary"]),
    ],
    dependencies: [
        .package(url: "https://github.com/adamrushy/OpenAISwift.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "OpenAIChatLibrary",
            dependencies: ["OpenAISwift"]),
        .testTarget(
            name: "OpenAIChatLibraryTests",
            dependencies: ["OpenAIChatLibrary"]),
    ]
)
