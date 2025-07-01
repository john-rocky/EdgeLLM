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
        )
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "EdgeLLM",
            dependencies: [],
            path: "Sources/EdgeLLM",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .unsafeFlags(["-enable-bare-slash-regex"])
            ]
        )
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