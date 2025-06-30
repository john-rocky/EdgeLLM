#!/bin/bash
set -e

# EdgeLLM XCFramework Build Script for Swift Package
echo "🔨 Building EdgeLLM XCFramework (Swift Package version)..."

# Configuration
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
OUTPUT_DIR="$PROJECT_DIR/dist"
MLC_ROOT="$PROJECT_DIR/.."

# Clean previous builds
rm -rf "$BUILD_DIR" "$OUTPUT_DIR"
mkdir -p "$BUILD_DIR" "$OUTPUT_DIR"

# Step 1: Build for iOS
echo "📱 Building for iOS (arm64)..."
cd "$PROJECT_DIR"
swift build \
    --configuration release \
    --arch arm64 \
    --sdk iphoneos \
    --scratch-path "$BUILD_DIR/ios"

# Step 2: Build for iOS Simulator (x86_64)
echo "💻 Building for iOS Simulator (x86_64)..."
swift build \
    --configuration release \
    --arch x86_64 \
    --sdk iphonesimulator \
    --scratch-path "$BUILD_DIR/sim-x86"

# Step 3: Build for iOS Simulator (arm64)
echo "💻 Building for iOS Simulator (arm64)..."
swift build \
    --configuration release \
    --arch arm64 \
    --sdk iphonesimulator \
    --scratch-path "$BUILD_DIR/sim-arm64"

# Step 4: Create frameworks
echo "📦 Creating frameworks..."

# iOS framework
mkdir -p "$BUILD_DIR/ios-framework/EdgeLLM.framework/Modules"
cp -r "$BUILD_DIR/ios/release/EdgeLLM.swiftmodule" "$BUILD_DIR/ios-framework/EdgeLLM.framework/Modules/"
cp "$BUILD_DIR/ios/release/libEdgeLLM.a" "$BUILD_DIR/ios-framework/EdgeLLM.framework/EdgeLLM"

# Create Info.plist
cat > "$BUILD_DIR/ios-framework/EdgeLLM.framework/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>ai.edge.EdgeLLM</string>
    <key>CFBundleName</key>
    <string>EdgeLLM</string>
    <key>CFBundleVersion</key>
    <string>0.1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>iPhoneOS</string>
    </array>
</dict>
</plist>
EOF

# Simulator framework (combine architectures)
mkdir -p "$BUILD_DIR/sim-framework/EdgeLLM.framework/Modules"
lipo -create \
    "$BUILD_DIR/sim-x86/release/libEdgeLLM.a" \
    "$BUILD_DIR/sim-arm64/release/libEdgeLLM.a" \
    -output "$BUILD_DIR/sim-framework/EdgeLLM.framework/EdgeLLM"

cp -r "$BUILD_DIR/sim-arm64/release/EdgeLLM.swiftmodule" "$BUILD_DIR/sim-framework/EdgeLLM.framework/Modules/"

# Create Info.plist for simulator
sed 's/iPhoneOS/iPhoneSimulator/g' "$BUILD_DIR/ios-framework/EdgeLLM.framework/Info.plist" > "$BUILD_DIR/sim-framework/EdgeLLM.framework/Info.plist"

# Step 5: Create XCFramework
echo "🎁 Creating XCFramework..."
xcodebuild -create-xcframework \
    -framework "$BUILD_DIR/ios-framework/EdgeLLM.framework" \
    -framework "$BUILD_DIR/sim-framework/EdgeLLM.framework" \
    -output "$OUTPUT_DIR/EdgeLLM.xcframework"

# Step 6: Create zip and checksum
echo "🔐 Creating archive and checksum..."
cd "$OUTPUT_DIR"
zip -r EdgeLLM.xcframework.zip EdgeLLM.xcframework
CHECKSUM=$(swift package compute-checksum EdgeLLM.xcframework.zip)

# Print summary
FRAMEWORK_SIZE=$(du -sh "$OUTPUT_DIR/EdgeLLM.xcframework" | cut -f1)
ZIP_SIZE=$(du -sh "$OUTPUT_DIR/EdgeLLM.xcframework.zip" | cut -f1)

echo ""
echo "✅ XCFramework build complete!"
echo "┌──────────────────────────────────────────────┐"
echo "│ 📍 Output: $OUTPUT_DIR/EdgeLLM.xcframework"
echo "│ 📦 Archive: $OUTPUT_DIR/EdgeLLM.xcframework.zip"
echo "│ 📊 Framework size: $FRAMEWORK_SIZE"
echo "│ 📉 Compressed size: $ZIP_SIZE"
echo "│ 🔐 Checksum: $CHECKSUM"
echo "└──────────────────────────────────────────────┘"
echo ""
echo "📝 Next steps:"
echo "1. Upload EdgeLLM.xcframework.zip to GitHub Releases"
echo "2. Update Package.swift with the following:"
echo "   url: \"https://github.com/john-rocky/EdgeLLM/releases/download/v0.1.0/EdgeLLM.xcframework.zip\""
echo "   checksum: \"$CHECKSUM\""