// swift-tools-version: 6.3
// OpenFCPXMLKit supports Swift 6 concurrency: Sendable protocols/implementations,
// async/await APIs, and builds with -strict-concurrency=complete (see CI).

import PackageDescription

let package = Package(
    name: "OpenFCPXMLKit",
    platforms: [
        .macOS(.v26),
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "OpenFCPXMLKit",
            targets: ["OpenFCPXMLKit"]),
        .executable(
            name: "OpenFCPXMLKit-CLI",
            targets: ["OpenFCPXMLKitCLI"]),
        .executable(
            name: "GenerateEmbeddedDTDs",
            targets: ["GenerateEmbeddedDTDs"]),
   ],
    // Dependencies used by core library and CLI targets.
    dependencies: [
        // CLI argument parsing
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.8.2"),
        // Timecode operations
        .package(url: "https://github.com/orchetect/swift-timecode", from: "3.1.2"),
        // Utility extensions (String, Collection, Optional helpers)
        .package(url: "https://github.com/orchetect/swift-extensions", from: "3.0.0"),
        // Semantic versioning (extracted from swift-extensions 3.0.0)
        .package(url: "https://github.com/orchetect/swift-semantic-version", from: "1.0.0"),
        // Explicit logging dependency (Xcode 26 dynamic linking compatibility)
        .package(url: "https://github.com/apple/swift-log", from: "1.14.0"),
        // Cross-platform XML parsing (AEXML backend for iOS and other non-macOS platforms)
        .package(url: "https://github.com/tadija/AEXML", from: "4.7.0"),
        // Excel file creation
        .package(url: "https://github.com/TheAcharya/XLKit", from: "1.1.7"),
    ],
    // Targets: core library, tests, user CLI, and DTD generator utility.
    targets: [
        // Core framework target
        .target(
            name: "OpenFCPXMLKit",
            dependencies: [
                .product(name: "SwiftTimecode", package: "swift-timecode"),
                .product(name: "SwiftExtensions", package: "swift-extensions"),
                .product(name: "SwiftSemanticVersion", package: "swift-semantic-version"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "AEXML", package: "AEXML"),
                .product(name: "XLKit", package: "XLKit"),
            ],
            resources: [
                .process("FCPXML DTDs")
            ]),
        // Package test suite
        .testTarget(
            name: "OpenFCPXMLKitTests",
            dependencies: [
                "OpenFCPXMLKit",
                .product(name: "XLKit", package: "XLKit"),
            ],
            path: "Tests",
            exclude: ["README.md", "ExcelReportTest", "Submitted FCPXML"],
            sources: ["OpenFCPXMLKitTests"],
            resources: [.process("FCPXML Samples/FCPXML")]),
        // ExcelReportTest READMEs are docs only (not test sources/resources).
        .testTarget(
            name: "ExcelReportTest",
            dependencies: [
                "OpenFCPXMLKit",
                .product(name: "XLKit", package: "XLKit"),
            ],
            path: "Tests/ExcelReportTest",
            exclude: ["README.md", "Output/README.md"]),
        // End-user CLI target
        .executableTarget(
            name: "OpenFCPXMLKitCLI",
            dependencies: [
                "OpenFCPXMLKit",
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
