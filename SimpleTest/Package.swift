// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SimpleEdgeLLMTest",
    platforms: [
        .macOS(.v14),
        .iOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "SimpleEdgeLLMTest",
            dependencies: []
        )
    ]
)