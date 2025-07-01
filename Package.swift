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
            checksum: "47f4ea10f42d870a7de2650012874a038f3d6cbb3feeb8249e0e22054be04d89"
        )
    ]
)
