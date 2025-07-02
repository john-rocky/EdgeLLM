// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StandaloneSimpleChat",
    platforms: [
        .iOS(.v14),
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "StandaloneSimpleChat",
            targets: ["StandaloneSimpleChat"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/john-rocky/EdgeLLM", branch: "complete-package")
    ],
    targets: [
        .executableTarget(
            name: "StandaloneSimpleChat",
            dependencies: [
                .product(name: "EdgeLLM", package: "EdgeLLM")
            ]
        )
    ]
)