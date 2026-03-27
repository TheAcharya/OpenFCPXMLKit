// swift-tools-version: 6.0
// Pipeline Neo supports Swift 6 concurrency: Sendable protocols/implementations,
// async/await APIs, and builds with -strict-concurrency=complete (see CI).

import PackageDescription

let package = Package(
    name: "PipelineNeo",
    platforms: [
        .macOS(.v12),
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "PipelineNeo",
            targets: ["PipelineNeo"]),
        .executable(
            name: "pipeline-neo",
            targets: ["PipelineNeoCLI"]),
        .executable(
            name: "GenerateEmbeddedDTDs",
            targets: ["GenerateEmbeddedDTDs"]),
   ],
    // Dependencies used by core library and CLI targets.
    dependencies: [
        // CLI argument parsing
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.7.1"),
        // Timecode operations
        .package(url: "https://github.com/orchetect/swift-timecode", from: "3.1.0"),
        // Utility extensions
        .package(url: "https://github.com/orchetect/swift-extensions", from: "2.1.4"),
        // Explicit logging dependency (Xcode 26 dynamic linking compatibility)
        .package(url: "https://github.com/apple/swift-log.git", from: "1.10.1"),
        // Cross-platform XML parsing (AEXML backend for iOS and other non-macOS platforms)
        .package(url: "https://github.com/tadija/AEXML", from: "4.7.0"),
    ],
    // Targets: core library, tests, user CLI, and DTD generator utility.
    targets: [
        // Core framework target
        .target(
            name: "PipelineNeo",
            dependencies: [
                .product(name: "SwiftTimecode", package: "swift-timecode"),
                .product(name: "SwiftExtensions", package: "swift-extensions"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "AEXML", package: "AEXML"),
            ],
            resources: [
                .process("FCPXML DTDs")
            ]),
        // Package test suite
        .testTarget(
            name: "PipelineNeoTests",
            dependencies: ["PipelineNeo"],
            path: "Tests",
            exclude: ["README.md"],
            sources: ["PipelineNeoTests"],
            resources: [.process("FCPXML Samples/FCPXML")]),
        // End-user CLI target
        .executableTarget(
            name: "PipelineNeoCLI",
            dependencies: [
                "PipelineNeo",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            exclude: ["README.md"]),
        // Internal tool to generate embedded DTD source
        .executableTarget(
            name: "GenerateEmbeddedDTDs",
            path: "Sources/GenerateEmbeddedDTDs",
            swiftSettings: [.unsafeFlags(["-parse-as-library"])]),
    ]
)
