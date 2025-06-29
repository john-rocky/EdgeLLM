// swift-tools-version: 5.9
// This is the Package.swift for binary distribution (v0.2.0+)
import PackageDescription

let package = Package(
    name: "EdgeLLM",
    platforms: [
        .iOS(.v14),
        .macOS(.v13)
    ],
    products: [
        // Core library (source code, < 1MB)
        .library(
            name: "EdgeLLM",
            targets: ["EdgeLLM"]
        ),
        // Optional: Runtime binary
        .library(
            name: "EdgeLLMRuntime",
            targets: ["EdgeLLMRuntime"]
        )
    ],
    targets: [
        // Core EdgeLLM (source)
        .target(
            name: "EdgeLLM",
            path: "Sources/EdgeLLM",
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        ),
        
        // Runtime binary from GitHub Releases
        .binaryTarget(
            name: "EdgeLLMRuntime",
            url: "https://github.com/yourusername/EdgeLLM/releases/download/v0.2.0/EdgeLLMRuntime.xcframework.zip",
            checksum: "CHECKSUM_HERE"
        ),
        
        // Alternative: Runtime from custom CDN
        /*
        .binaryTarget(
            name: "EdgeLLMRuntime",
            url: "https://cdn.yourcompany.com/edgellm/0.2.0/EdgeLLMRuntime.xcframework.zip",
            checksum: "CHECKSUM_HERE"
        )
        */
    ]
)