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
            url: "https://github.com/john-rocky/EdgeLLM/releases/download/v0.1.0/EdgeLLM-Bundle.zip",
            checksum: "bc9188ab45b36f6a071cce7e1c9196ccf84c2cdc2dfcd51c33518f10db4ed8e5"
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