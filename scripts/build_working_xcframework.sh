#!/bin/bash

# Build a working XCFramework with complete MLC-LLM support
set -e

echo "🚀 Building Working EdgeLLM XCFramework with Complete MLC-LLM"

# Paths
MLC_LLM_ROOT="/Users/agmajima/Downloads/mlc-llm"
EDGELLM_ROOT="$MLC_LLM_ROOT/EdgeLLM"
OUTPUT_DIR="$EDGELLM_ROOT/XCFrameworks"
BUILD_DIR="$EDGELLM_ROOT/build_working"

# Activate conda environment
echo "🐍 Activating conda environment..."
source ~/miniconda3/etc/profile.d/conda.sh
conda activate myenv

# Clean and create directories
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$OUTPUT_DIR"

# Use the pre-built libraries from MLCChat since they are known to work
echo "📚 Using pre-built libraries from MLCChat..."
LIBS_PATH="$MLC_LLM_ROOT/ios/MLCChat/dist/lib"

if [ ! -d "$LIBS_PATH" ]; then
    echo "❌ Error: MLCChat libraries not found at $LIBS_PATH"
    echo "Please run prepare_libs.sh in ios directory first"
    exit 1
fi

# Build the Objective-C++ bridge with the same configuration as MLCChat
echo "🔨 Building Objective-C++ bridge..."
cd "$BUILD_DIR"

# Header paths matching MLCChat configuration
HEADER_PATHS=(
    "-I$MLC_LLM_ROOT/ios/MLCSwift/Sources/ObjC/include"
    "-I$MLC_LLM_ROOT/3rdparty/tvm/include"
    "-I$MLC_LLM_ROOT/3rdparty/tvm/ffi/include"
    "-I$MLC_LLM_ROOT/3rdparty/tvm/3rdparty/dmlc-core/include"
    "-I$MLC_LLM_ROOT/3rdparty/tvm/3rdparty/dlpack/include"
    "-I$MLC_LLM_ROOT/include"
    "-I$MLC_LLM_ROOT/cpp"
)

# Compile LLMEngine.mm with the same settings as MLCChat
clang++ -c \
    -arch arm64 \
    -isysroot $(xcrun --sdk iphoneos --show-sdk-path) \
    -std=c++17 \
    -stdlib=libc++ \
    -fobjc-arc \
    -fmodules \
    -mios-version-min=14.0 \
    -O3 \
    "${HEADER_PATHS[@]}" \
    -DTVM_USE_LIBBACKTRACE=0 \
    -DDMLC_USE_LOGGING_LIBRARY="<tvm/runtime/logging.h>" \
    -DNDEBUG \
    "$MLC_LLM_ROOT/ios/MLCSwift/Sources/ObjC/LLMEngine.mm" \
    -o LLMEngine.o

# Create static library for the bridge
ar rcs libmlcbridge.a LLMEngine.o

echo "📱 Creating framework structure..."

# Framework configuration
FRAMEWORK_NAME="MLCRuntime"
FRAMEWORK_DIR="$BUILD_DIR/${FRAMEWORK_NAME}.framework"

rm -rf "$FRAMEWORK_DIR"
mkdir -p "$FRAMEWORK_DIR/Headers"
mkdir -p "$FRAMEWORK_DIR/Modules"

# Copy headers
echo "📁 Copying headers..."
cp "$MLC_LLM_ROOT/ios/MLCSwift/Sources/ObjC/include/LLMEngine.h" "$FRAMEWORK_DIR/Headers/"

# Create umbrella header
cat > "$FRAMEWORK_DIR/Headers/MLCRuntime.h" << 'EOF'
// MLCRuntime Framework Header
#import <Foundation/Foundation.h>

FOUNDATION_EXPORT double MLCRuntimeVersionNumber;
FOUNDATION_EXPORT const unsigned char MLCRuntimeVersionString[];

// Import public headers
#import "LLMEngine.h"
EOF

# Combine all libraries in the correct order
echo "🔧 Combining libraries..."
cd "$BUILD_DIR"

# Order matters: bridge first, then MLC libs
libtool -static -o "$FRAMEWORK_DIR/$FRAMEWORK_NAME" \
    libmlcbridge.a \
    "$LIBS_PATH/libmlc_llm.a" \
    "$LIBS_PATH/libtvm_runtime.a" \
    "$LIBS_PATH/libmodel_iphone.a" \
    "$LIBS_PATH/libsentencepiece.a" \
    "$LIBS_PATH/libtokenizers_cpp.a" \
    "$LIBS_PATH/libtokenizers_c.a"

echo "✅ Combined library size: $(du -h "$FRAMEWORK_DIR/$FRAMEWORK_NAME" | cut -f1)"

# Create Info.plist
cat > "$FRAMEWORK_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$FRAMEWORK_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>ai.edge.MLCRuntime</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$FRAMEWORK_NAME</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>iPhoneOS</string>
    </array>
    <key>MinimumOSVersion</key>
    <string>14.0</string>
    <key>UIDeviceFamily</key>
    <array>
        <integer>1</integer>
        <integer>2</integer>
    </array>
</dict>
</plist>
EOF

# Create module map
cat > "$FRAMEWORK_DIR/Modules/module.modulemap" << EOF
framework module MLCRuntime {
    umbrella header "MLCRuntime.h"
    export *
    module * { export * }
    
    requires objc
}
EOF

# Create XCFramework
echo "📦 Creating XCFramework..."
XCFRAMEWORK_PATH="$OUTPUT_DIR/${FRAMEWORK_NAME}.xcframework"
rm -rf "$XCFRAMEWORK_PATH"

xcodebuild -create-xcframework \
    -framework "$FRAMEWORK_DIR" \
    -output "$XCFRAMEWORK_PATH"

# Compress
echo "🗜️ Compressing XCFramework..."
cd "$OUTPUT_DIR"
rm -f "${FRAMEWORK_NAME}.xcframework.zip"
zip -r "${FRAMEWORK_NAME}.xcframework.zip" "${FRAMEWORK_NAME}.xcframework"

# Calculate checksum
CHECKSUM=$(swift package compute-checksum "${FRAMEWORK_NAME}.xcframework.zip" 2>/dev/null || \
           shasum -a 256 "${FRAMEWORK_NAME}.xcframework.zip" | cut -d' ' -f1)

echo "✅ Checksum: $CHECKSUM"
echo "$CHECKSUM" > "${FRAMEWORK_NAME}.xcframework.checksum"

# Clean up
rm -rf "$BUILD_DIR"

# Output results
ZIP_SIZE=$(du -h "${FRAMEWORK_NAME}.xcframework.zip" | cut -f1)

echo ""
echo "🎉 Working XCFramework created successfully!"
echo "📁 Framework: $XCFRAMEWORK_PATH"
echo "📦 ZIP: ${FRAMEWORK_NAME}.xcframework.zip ($ZIP_SIZE)"
echo "🔐 Checksum: $CHECKSUM"
echo ""
echo "💡 This XCFramework includes:"
echo "   ✅ Complete MLC-LLM runtime with json_ffi_engine"
echo "   ✅ Objective-C++ bridge (JSONFFIEngine)"
echo "   ✅ All necessary static libraries"
echo "   ✅ Metal support for GPU acceleration"
echo ""
echo "📝 Update Package.swift with:"
echo "   url: \"https://github.com/john-rocky/EdgeLLM/releases/download/v0.4.0/MLCRuntime.xcframework.zip\","
echo "   checksum: \"$CHECKSUM\""