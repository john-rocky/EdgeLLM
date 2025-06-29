#!/bin/bash
set -e

# EdgeLLM XCFramework Build Script
# MLCSwiftをラップしたEdgeLLMをXCFramework化

echo "🔨 Building EdgeLLM XCFramework..."

# Configuration
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
OUTPUT_DIR="$PROJECT_DIR/dist"
MLC_LIBS_DIR="$PROJECT_DIR/../ios/MLCChat/dist/lib"

# Clean previous builds
rm -rf "$BUILD_DIR" "$OUTPUT_DIR"
mkdir -p "$BUILD_DIR" "$OUTPUT_DIR"

# Step 1: Build EdgeLLM for iOS
echo "📱 Building for iOS..."
xcodebuild archive \
    -scheme EdgeLLM \
    -destination "generic/platform=iOS" \
    -archivePath "$BUILD_DIR/EdgeLLM-iOS.xcarchive" \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# Step 2: Build EdgeLLM for iOS Simulator
echo "💻 Building for iOS Simulator..."
xcodebuild archive \
    -scheme EdgeLLM \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "$BUILD_DIR/EdgeLLM-Simulator.xcarchive" \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# Step 3: Combine MLC libraries
echo "🔗 Combining MLC libraries..."
cd "$MLC_LIBS_DIR"
libtool -static -o "$BUILD_DIR/libMLCBundle.a" \
    libmlc_llm.a \
    libtvm_runtime.a \
    libmodel_iphone.a \
    libsentencepiece.a \
    libtokenizers_cpp.a

# Step 4: Embed MLC libraries into frameworks
echo "📦 Embedding MLC libraries..."
for arch in iOS Simulator; do
    FRAMEWORK_PATH="$BUILD_DIR/EdgeLLM-$arch.xcarchive/Products/Library/Frameworks/EdgeLLM.framework"
    if [ -d "$FRAMEWORK_PATH" ]; then
        # Create Resources directory
        mkdir -p "$FRAMEWORK_PATH/Resources"
        
        # Copy MLC bundle
        cp "$BUILD_DIR/libMLCBundle.a" "$FRAMEWORK_PATH/Resources/"
        
        # Update binary to include MLC symbols
        cd "$FRAMEWORK_PATH"
        lipo -create EdgeLLM "$BUILD_DIR/libMLCBundle.a" -output EdgeLLM_combined
        mv EdgeLLM_combined EdgeLLM
    fi
done

# Step 5: Create XCFramework
echo "🎁 Creating XCFramework..."
xcodebuild -create-xcframework \
    -framework "$BUILD_DIR/EdgeLLM-iOS.xcarchive/Products/Library/Frameworks/EdgeLLM.framework" \
    -framework "$BUILD_DIR/EdgeLLM-Simulator.xcarchive/Products/Library/Frameworks/EdgeLLM.framework" \
    -output "$OUTPUT_DIR/EdgeLLM.xcframework"

# Step 6: Create checksum for Package.swift
echo "🔐 Generating checksum..."
cd "$OUTPUT_DIR"
zip -r EdgeLLM.xcframework.zip EdgeLLM.xcframework
CHECKSUM=$(swift package compute-checksum EdgeLLM.xcframework.zip)

# Step 7: Generate Package.swift for binary distribution
cat > "$OUTPUT_DIR/Package.swift" << EOF
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
            targets: ["EdgeLLM"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "EdgeLLM",
            url: "https://github.com/yourusername/EdgeLLM/releases/download/v0.2.0/EdgeLLM.xcframework.zip",
            checksum: "$CHECKSUM"
        )
    ]
)
EOF

# Step 8: Print summary
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
echo "2. Update Package.swift with the release URL"
echo "3. Tag and publish version 0.2.0"