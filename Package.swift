// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EdgeLLM",
    platforms: [
        .iOS(.v14),
        .macOS(.v13),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "EdgeLLM",
            targets: ["EdgeLLM-Complete"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "EdgeLLM-Complete",
            url: "https://github.com/john-rocky/EdgeLLM/releases/download/v0.1.1/EdgeLLM-Complete.zip",
            checksum: "54fda4b9cf88bc044435afab82e55a6d194be5a59aa60820b8d20635dbe457d6"
        )
    ]
)
