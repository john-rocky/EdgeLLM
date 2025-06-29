// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EdgeLLM",
    platforms: [
        .iOS(.v14),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "EdgeLLM",
            targets: ["EdgeLLM"]
        ),
    ],
    dependencies: [
        // MLCSwift dependency for source distribution (v0.1.x)
        // For local development
        .package(path: "../ios/MLCSwift")
        
        // For release version, use:
        // .package(url: "https://github.com/mlc-ai/mlc-llm", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "EdgeLLM",
            dependencies: [
                .product(name: "MLCSwift", package: "MLCSwift")
            ],
            path: "Sources/EdgeLLM",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx),
                .unsafeFlags(["-enable-bare-slash-regex"])
            ]
        ),
        .testTarget(
            name: "EdgeLLMTests",
            dependencies: ["EdgeLLM"],
            path: "Tests/EdgeLLMTests"
        ),
    ]
)

// ============================================
// Binary Distribution Configuration (v0.2.0+)
// ============================================
// When releasing XCFramework version, replace above with:
/*
let package = Package(
    name: "EdgeLLM",
    platforms: [
        .iOS(.v14),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "EdgeLLM",
            targets: ["EdgeLLM"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "EdgeLLM",
            url: "https://github.com/yourusername/EdgeLLM/releases/download/v0.2.0/EdgeLLM.xcframework.zip",
            checksum: "GENERATED_CHECKSUM_HERE"
        )
    ]
)
*/