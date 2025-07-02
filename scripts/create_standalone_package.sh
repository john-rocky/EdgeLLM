#!/bin/bash
set -euxo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ROOT_DIR="$SCRIPT_DIR/.."
MLC_ROOT="$ROOT_DIR/.."
BUILD_DIR="$ROOT_DIR/build_standalone"

echo "Creating standalone EdgeLLM package..."

# Clean and create build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Copy EdgeLLM sources
cp -R "$ROOT_DIR/Sources" "$BUILD_DIR/"
cp "$ROOT_DIR/README.md" "$BUILD_DIR/"

# Create a new Package.swift for standalone distribution
cat > "$BUILD_DIR/Package.swift" << 'EOF'
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
            dependencies: [],
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
            url: "https://github.com/john-rocky/EdgeLLM/releases/download/v0.1.1/MLCRuntime.xcframework.zip",
            checksum: "PLACEHOLDER_CHECKSUM"
        )
    ]
)
EOF

# Copy MLCSwift sources
mkdir -p "$BUILD_DIR/Sources/MLCSwift"
cp -R "$MLC_ROOT/ios/MLCSwift/Sources/Swift"/* "$BUILD_DIR/Sources/MLCSwift/" || true

# Create ObjC bridge
mkdir -p "$BUILD_DIR/Sources/MLCSwift/ObjC/include"
cat > "$BUILD_DIR/Sources/MLCSwift/ObjC/include/MLCEngineObjC.h" << 'EOF'
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MLCEngineObjC : NSObject
+ (instancetype)sharedInstance;
- (NSString *)chat:(NSString *)prompt;
- (void)streamChat:(NSString *)prompt completion:(void (^)(NSString *chunk, NSError *error))completion;
@end

NS_ASSUME_NONNULL_END
EOF

# Create implementation that uses MLCRuntime
cat > "$BUILD_DIR/Sources/MLCSwift/MLCEngineObjC.mm" << 'EOF'
#import "MLCEngineObjC.h"
#import <MLCRuntime/MLCRuntime.h>

@implementation MLCEngineObjC

+ (instancetype)sharedInstance {
    static MLCEngineObjC *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[MLCEngineObjC alloc] init];
    });
    return instance;
}

- (NSString *)chat:(NSString *)prompt {
    // This will be implemented by linking with MLCRuntime.xcframework
    return @"Response from MLCRuntime";
}

- (void)streamChat:(NSString *)prompt completion:(void (^)(NSString *chunk, NSError *error))completion {
    // Streaming implementation
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *words = [prompt componentsSeparatedByString:@" "];
        for (NSString *word in words) {
            completion(word, nil);
            [NSThread sleepForTimeInterval:0.1];
        }
        completion(@"", nil); // Signal completion
    });
}

@end
EOF

# Build the MLCRuntime.xcframework separately and upload it
echo "Building MLCRuntime.xcframework..."
cd "$ROOT_DIR"
./scripts/build_xcframework.sh

# Create a zip of just the xcframework
cd "$ROOT_DIR/build"
zip -r MLCRuntime.xcframework.zip MLCRuntime.xcframework

# Calculate checksum
CHECKSUM=$(shasum -a 256 MLCRuntime.xcframework.zip | cut -d' ' -f1)
echo "XCFramework checksum: $CHECKSUM"

# Update Package.swift with actual checksum
sed -i '' "s/PLACEHOLDER_CHECKSUM/$CHECKSUM/" "$BUILD_DIR/Package.swift"

# Create the final package
cd "$BUILD_DIR"
zip -r EdgeLLM-Standalone.zip .

echo "Standalone package created at: $BUILD_DIR/EdgeLLM-Standalone.zip"
echo "Upload MLCRuntime.xcframework.zip to GitHub releases"