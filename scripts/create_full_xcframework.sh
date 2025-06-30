#!/bin/bash
set -e

echo "🔨 Creating EdgeLLM XCFramework with all dependencies..."

# Configuration
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MLC_ROOT="$(cd "$PROJECT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build_xcframework"
OUTPUT_DIR="$PROJECT_DIR/dist"

# Clean and create directories
rm -rf "$BUILD_DIR" "$OUTPUT_DIR"
mkdir -p "$BUILD_DIR/Frameworks" "$OUTPUT_DIR"

# Step 1: Copy MLCSwift framework
echo "📋 Copying MLCSwift..."
mkdir -p "$BUILD_DIR/MLCSwift"
cp -r "$MLC_ROOT/ios/MLCSwift/Sources" "$BUILD_DIR/MLCSwift/"
cp -r "$MLC_ROOT/ios/MLCSwift/Package.swift" "$BUILD_DIR/MLCSwift/"
cp -r "$MLC_ROOT/ios/MLCSwift/README.md" "$BUILD_DIR/MLCSwift/" 2>/dev/null || true

# Step 2: Create a combined static library
echo "🔗 Creating combined static library..."
cd "$MLC_ROOT/ios/MLCChat/dist/lib"

# Combine all MLC libraries into one
libtool -static -o "$BUILD_DIR/libMLCRuntime.a" \
    libmlc_llm.a \
    libtvm_runtime.a \
    libmodel_iphone.a \
    libsentencepiece.a \
    libtokenizers_cpp.a

# Step 3: Create MLCRuntime.xcframework
echo "📦 Creating MLCRuntime XCFramework..."
mkdir -p "$BUILD_DIR/MLCRuntime.framework"

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
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
</dict>
</plist>
EOF

cp "$BUILD_DIR/libMLCRuntime.a" "$BUILD_DIR/MLCRuntime.framework/MLCRuntime"

# Create module map
mkdir -p "$BUILD_DIR/MLCRuntime.framework/Modules"
cat > "$BUILD_DIR/MLCRuntime.framework/Modules/module.modulemap" << EOF
framework module MLCRuntime {
    umbrella header "MLCRuntime.h"
    export *
}
EOF

# Create dummy header
mkdir -p "$BUILD_DIR/MLCRuntime.framework/Headers"
cat > "$BUILD_DIR/MLCRuntime.framework/Headers/MLCRuntime.h" << EOF
// MLCRuntime Framework
EOF

# Create XCFramework for MLCRuntime
xcodebuild -create-xcframework \
    -framework "$BUILD_DIR/MLCRuntime.framework" \
    -output "$OUTPUT_DIR/MLCRuntime.xcframework"

# Step 4: Update EdgeLLM Package.swift for bundling
echo "📝 Creating bundled Package.swift..."
cat > "$OUTPUT_DIR/Package.swift" << 'EOF'
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
            path: "Sources/EdgeLLM",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx),
                .unsafeFlags(["-enable-bare-slash-regex"])
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

# Step 5: Copy EdgeLLM sources
echo "📂 Copying EdgeLLM sources..."
mkdir -p "$OUTPUT_DIR/Sources"
cp -r "$PROJECT_DIR/Sources" "$OUTPUT_DIR/"

# Step 6: Create archive
echo "📦 Creating distribution archive..."
cd "$OUTPUT_DIR"
zip -r EdgeLLM-Bundle.zip Package.swift Sources MLCRuntime.xcframework
CHECKSUM=$(swift package compute-checksum EdgeLLM-Bundle.zip)

# Print summary
BUNDLE_SIZE=$(du -sh EdgeLLM-Bundle.zip | cut -f1)

echo ""
echo "✅ EdgeLLM bundle created successfully!"
echo "┌──────────────────────────────────────────────┐"
echo "│ 📦 Bundle: $OUTPUT_DIR/EdgeLLM-Bundle.zip"
echo "│ 📊 Size: $BUNDLE_SIZE"
echo "│ 🔐 Checksum: $CHECKSUM"
echo "└──────────────────────────────────────────────┘"
echo ""
echo "📝 To use this bundle:"
echo "1. Upload EdgeLLM-Bundle.zip to GitHub Releases"
echo "2. Users can add to their project with:"
echo "   .package(url: \"https://github.com/john-rocky/EdgeLLM/releases/download/v0.1.0/EdgeLLM-Bundle.zip\","
echo "            checksum: \"$CHECKSUM\")"