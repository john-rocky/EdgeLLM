#!/bin/bash

# EdgeLLM XCFramework作成スクリプト（MLCSwiftブリッジ付き）
set -e

echo "🚀 EdgeLLM XCFramework Creation Script (with MLCSwift Bridge)"

# パスの設定
MLC_LLM_ROOT="/Users/agmajima/Downloads/mlc-llm"
EDGELLM_ROOT="$MLC_LLM_ROOT/EdgeLLM"
LIBS_PATH="$MLC_LLM_ROOT/ios/MLCChat/dist/lib"
OUTPUT_DIR="$EDGELLM_ROOT/XCFrameworks"
MLCSWIFT_PATH="$MLC_LLM_ROOT/ios/MLCSwift"
BUILD_DIR="$EDGELLM_ROOT/build"

# 出力ディレクトリを作成
mkdir -p "$OUTPUT_DIR"
mkdir -p "$BUILD_DIR"

echo "📦 Building MLCSwift Bridge..."

# MLCSwiftのObjective-C++ブリッジをビルド
cd "$BUILD_DIR"

# ヘッダーサーチパスを設定
HEADER_PATHS=(
    "-I$MLC_LLM_ROOT/ios/MLCSwift/Sources/ObjC/include"
    "-I$MLC_LLM_ROOT/3rdparty/tvm/include"
    "-I$MLC_LLM_ROOT/3rdparty/tvm/ffi/include"
    "-I$MLC_LLM_ROOT/3rdparty/tvm/3rdparty/dmlc-core/include"
    "-I$MLC_LLM_ROOT/3rdparty/tvm/3rdparty/dlpack/include"
)

# Objective-C++ファイルをコンパイル
echo "🔨 Compiling LLMEngine.mm..."
clang++ -c \
    -arch arm64 \
    -isysroot $(xcrun --sdk iphoneos --show-sdk-path) \
    -std=c++17 \
    -fobjc-arc \
    -fmodules \
    -mios-version-min=14.0 \
    "${HEADER_PATHS[@]}" \
    -DTVM_USE_LIBBACKTRACE=0 \
    -DDMLC_USE_LOGGING_LIBRARY="<tvm/runtime/logging.h>" \
    "$MLC_LLM_ROOT/ios/MLCSwift/Sources/ObjC/LLMEngine.mm" \
    -o LLMEngine.o

# スタティックライブラリを作成
echo "📚 Creating bridge library..."
ar rcs libmlcbridge.a LLMEngine.o

echo "📱 Building framework structure..."

# フレームワーク構造を作成
FRAMEWORK_NAME="MLCRuntime"
FRAMEWORK_DIR="$OUTPUT_DIR/${FRAMEWORK_NAME}.framework"

rm -rf "$FRAMEWORK_DIR"
mkdir -p "$FRAMEWORK_DIR/Headers"
mkdir -p "$FRAMEWORK_DIR/Modules"

# ヘッダーファイルをコピー
echo "📁 Copying headers..."
cp "$MLC_LLM_ROOT/ios/MLCSwift/Sources/ObjC/include/LLMEngine.h" "$FRAMEWORK_DIR/Headers/"

# メインヘッダーを作成
cat > "$FRAMEWORK_DIR/Headers/MLCRuntime.h" << 'EOF'
// MLCRuntime Framework Header
#import <Foundation/Foundation.h>

FOUNDATION_EXPORT double MLCRuntimeVersionNumber;
FOUNDATION_EXPORT const unsigned char MLCRuntimeVersionString[];

// Import public headers
#import "LLMEngine.h"
EOF

# ライブラリを統合
echo "🔧 Combining static libraries..."
cd "$BUILD_DIR"

# libtoolを使用してすべてのライブラリを統合（ブリッジライブラリを含む）
libtool -static -o "$FRAMEWORK_DIR/$FRAMEWORK_NAME" \
    libmlcbridge.a \
    "$LIBS_PATH/libmlc_llm.a" \
    "$LIBS_PATH/libmodel_iphone.a" \
    "$LIBS_PATH/libsentencepiece.a" \
    "$LIBS_PATH/libtokenizers_c.a" \
    "$LIBS_PATH/libtokenizers_cpp.a" \
    "$LIBS_PATH/libtvm_runtime.a"

echo "  ✅ Combined library created: $(du -h "$FRAMEWORK_DIR/$FRAMEWORK_NAME" | cut -f1)"

# Info.plistを作成
echo "📄 Creating Info.plist..."
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
</dict>
</plist>
EOF

# module.modulemapを作成
echo "📋 Creating module.modulemap..."
cat > "$FRAMEWORK_DIR/Modules/module.modulemap" << EOF
framework module MLCRuntime {
    umbrella header "MLCRuntime.h"
    export *
    module * { export * }
    
    requires objc
}
EOF

# XCFrameworkを作成
echo "📦 Creating XCFramework..."
XCFRAMEWORK_PATH="$OUTPUT_DIR/${FRAMEWORK_NAME}.xcframework"
rm -rf "$XCFRAMEWORK_PATH"

xcodebuild -create-xcframework \
    -framework "$FRAMEWORK_DIR" \
    -output "$XCFRAMEWORK_PATH"

echo "✅ XCFramework created at: $XCFRAMEWORK_PATH"

# XCFrameworkをzip圧縮
echo "🗜️ Compressing XCFramework..."
cd "$OUTPUT_DIR"
rm -f "${FRAMEWORK_NAME}.xcframework.zip"
zip -r "${FRAMEWORK_NAME}.xcframework.zip" "${FRAMEWORK_NAME}.xcframework"

# チェックサムを計算
echo "🔐 Calculating checksum..."
CHECKSUM=$(swift package compute-checksum "${FRAMEWORK_NAME}.xcframework.zip" 2>/dev/null || \
           shasum -a 256 "${FRAMEWORK_NAME}.xcframework.zip" | cut -d' ' -f1)

echo "✅ Checksum: $CHECKSUM"
echo "$CHECKSUM" > "${FRAMEWORK_NAME}.xcframework.checksum"

# サイズ情報
ZIP_SIZE=$(du -h "${FRAMEWORK_NAME}.xcframework.zip" | cut -f1)

echo ""
echo "🎉 XCFramework creation complete!"
echo "📁 Framework: $XCFRAMEWORK_PATH"
echo "📦 ZIP: ${FRAMEWORK_NAME}.xcframework.zip ($ZIP_SIZE)"
echo "🔐 Checksum: $CHECKSUM"
echo ""
echo "💡 Next steps:"
echo "   1. Upload ${FRAMEWORK_NAME}.xcframework.zip to GitHub Releases"
echo "   2. Update Package.swift with checksum: $CHECKSUM"
echo "   3. Test EdgeLLM with real MLC inference"

# クリーンアップ
rm -rf "$BUILD_DIR"