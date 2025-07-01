// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SimpleChat",
    platforms: [
        .iOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/john-rocky/EdgeLLM", branch: "complete-package")
    ],
    targets: []
)