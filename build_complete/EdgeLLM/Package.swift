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
            targets: ["EdgeLLM", "MLCRuntime"]
        ),
    ],
    targets: [
        .target(
            name: "EdgeLLM",
            dependencies: ["MLCSwift"],
            path: "Sources/EdgeLLM",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .unsafeFlags(["-enable-bare-slash-regex"])
            ]
        ),
        .target(
            name: "MLCSwift",
            path: "Sources/MLCSwift",
            publicHeadersPath: "ObjC/include",
            cSettings: [
                .headerSearchPath("ObjC/include")
            ],
            linkerSettings: [
                .linkedFramework("Metal"),
                .linkedFramework("MetalKit"),
                .linkedFramework("MetalPerformanceShaders"),
                .linkedLibrary("c++")
            ]
        ),
        .binaryTarget(
            name: "MLCRuntime",
            path: "MLCRuntime.xcframework"
        )
    ]
)
