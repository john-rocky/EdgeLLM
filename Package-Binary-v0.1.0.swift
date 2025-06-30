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
    targets: [
        .binaryTarget(
            name: "EdgeLLM",
            url: "https://github.com/john-rocky/EdgeLLM/releases/download/v0.1.0/EdgeLLM-Bundle.zip",
            checksum: "bc9188ab45b36f6a071cce7e1c9196ccf84c2cdc2dfcd51c33518f10db4ed8e5"
        )
    ]
)