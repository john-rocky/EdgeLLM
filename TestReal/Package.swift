// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EdgeLLMRealTest",
    platforms: [
        .iOS(.v14),
        .macOS(.v14)
    ],
    dependencies: [
        .package(path: "../") // Local EdgeLLM package
    ],
    targets: [
        .executableTarget(
            name: "EdgeLLMRealTest",
            dependencies: [
                .product(name: "EdgeLLM", package: "EdgeLLM")
            ],
            linkerSettings: [
                .linkedFramework("Metal"),
                .linkedFramework("MetalKit"),
                .linkedFramework("Accelerate")
            ]
        )
    ]
)