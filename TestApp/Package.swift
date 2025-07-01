// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EdgeLLMTestApp",
    platforms: [
        .macOS(.v14),
        .iOS(.v14)
    ],
    dependencies: [
        .package(path: "../") // EdgeLLMパッケージへの参照
    ],
    targets: [
        .executableTarget(
            name: "EdgeLLMTestApp",
            dependencies: [
                .product(name: "EdgeLLM", package: "EdgeLLM")
            ]
        )
    ]
)