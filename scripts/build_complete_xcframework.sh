#!/bin/bash
set -e

echo "🔨 Building Complete EdgeLLM XCFramework with MLCSwift..."

# Configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MLC_ROOT="$(cd "$PROJECT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build_complete"
OUTPUT_DIR="$PROJECT_DIR/dist_complete"

# Clean
rm -rf "$BUILD_DIR" "$OUTPUT_DIR"
mkdir -p "$BUILD_DIR" "$OUTPUT_DIR"

# Step 1: Copy all necessary files
echo "📋 Copying sources..."
mkdir -p "$BUILD_DIR/EdgeLLM"
cp -r "$PROJECT_DIR/Sources" "$BUILD_DIR/EdgeLLM/"
cp "$PROJECT_DIR/Package.swift" "$BUILD_DIR/EdgeLLM/"

# Step 2: Create a standalone Package.swift
echo "📝 Creating standalone Package.swift..."
cat > "$BUILD_DIR/EdgeLLM/Package.swift" << 'EOF'
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
EOF

# Step 3: Copy MLCSwift sources
echo "📦 Copying MLCSwift..."
mkdir -p "$BUILD_DIR/EdgeLLM/Sources/MLCSwift"
cp -r "$MLC_ROOT/ios/MLCSwift/Sources"/* "$BUILD_DIR/EdgeLLM/Sources/MLCSwift/"

# Step 4: Create MLCRuntime.xcframework from static libraries
echo "🔗 Creating MLCRuntime.xcframework..."
mkdir -p "$BUILD_DIR/MLCRuntime.framework"

# Combine all static libraries
cd "$MLC_ROOT/ios/MLCChat/dist/lib"
libtool -static -o "$BUILD_DIR/MLCRuntime.framework/MLCRuntime" \
    libmlc_llm.a \
    libtvm_runtime.a \
    libmodel_iphone.a \
    libsentencepiece.a \
    libtokenizers_cpp.a

# Create framework structure
cat > "$BUILD_DIR/MLCRuntime.framework/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>ai.mlc.runtime</string>
    <key>CFBundleName</key>
    <string>MLCRuntime</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>MinimumOSVersion</key>
    <string>14.0</string>
</dict>
</plist>
EOF

# Create module map
mkdir -p "$BUILD_DIR/MLCRuntime.framework/Modules"
cat > "$BUILD_DIR/MLCRuntime.framework/Modules/module.modulemap" << EOF
framework module MLCRuntime {
    export *
}
EOF

# Create XCFramework
xcodebuild -create-xcframework \
    -framework "$BUILD_DIR/MLCRuntime.framework" \
    -output "$BUILD_DIR/EdgeLLM/MLCRuntime.xcframework"

# Step 5: Create final archive
echo "📦 Creating distribution..."
cd "$BUILD_DIR"
zip -r "$OUTPUT_DIR/EdgeLLM-Complete.zip" EdgeLLM

# Calculate checksum
cd "$OUTPUT_DIR"
CHECKSUM=$(swift package compute-checksum EdgeLLM-Complete.zip)

echo ""
echo "✅ Complete XCFramework build done!"
echo "📦 Output: $OUTPUT_DIR/EdgeLLM-Complete.zip"
echo "🔐 Checksum: $CHECKSUM"
echo ""
echo "Usage in Package.swift:"
echo ".binaryTarget("
echo "    name: \"EdgeLLM\","
echo "    url: \"https://github.com/john-rocky/EdgeLLM/releases/download/v0.1.1/EdgeLLM-Complete.zip\","
echo "    checksum: \"$CHECKSUM\""
echo ")"