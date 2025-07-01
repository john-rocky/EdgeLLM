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
            checksum: "5ca47adabfdd1b1606516ed53f8dc97ff1c3dc356f8b75de21bb379d356d8a4a"
        )
    ]
)
