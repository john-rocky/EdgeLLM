#!/bin/bash

# EdgeLLM XCFramework作成スクリプト
set -e

echo "🚀 EdgeLLM XCFramework Creation Script"

# パスの設定
MLC_LLM_ROOT="/Users/agmajima/Downloads/mlc-llm"
EDGELLM_ROOT="$MLC_LLM_ROOT/EdgeLLM"
LIBS_PATH="$MLC_LLM_ROOT/ios/MLCChat/dist/lib"
OUTPUT_DIR="$EDGELLM_ROOT/XCFrameworks"

# 出力ディレクトリを作成
mkdir -p "$OUTPUT_DIR"

echo "📦 Creating XCFramework for EdgeLLM..."

# ライブラリファイルの確認
echo "📋 Checking library files..."
if [ ! -d "$LIBS_PATH" ]; then
    echo "❌ Error: Library path not found: $LIBS_PATH"
    echo "Run prepare_libs.sh first to build MLC-LLM libraries"
    exit 1
fi

# 必要なライブラリファイルのリスト
REQUIRED_LIBS=(
    "libmlc_llm.a"
    "libmodel_iphone.a"
    "libsentencepiece.a"
    "libtokenizers_c.a"
    "libtokenizers_cpp.a"
    "libtvm_runtime.a"
)

# ライブラリファイルの存在確認
for lib in "${REQUIRED_LIBS[@]}"; do
    if [ -f "$LIBS_PATH/$lib" ]; then
        echo "  ✅ $lib: $(du -h "$LIBS_PATH/$lib" | cut -f1)"
    else
        echo "  ❌ $lib: Not found"
        exit 1
    fi
done

echo "📱 Building framework structure..."

# フレームワーク構造を作成
FRAMEWORK_NAME="MLCRuntime"
FRAMEWORK_DIR="$OUTPUT_DIR/${FRAMEWORK_NAME}.framework"

rm -rf "$FRAMEWORK_DIR"
mkdir -p "$FRAMEWORK_DIR/Headers"
mkdir -p "$FRAMEWORK_DIR/Modules"

# ヘッダーファイルをコピー
echo "📁 Copying headers..."
if [ -d "$MLC_LLM_ROOT/ios/MLCSwift/Sources/ObjC/include" ]; then
    cp "$MLC_LLM_ROOT/ios/MLCSwift/Sources/ObjC/include"/*.h "$FRAMEWORK_DIR/Headers/"
    echo "  ✅ Headers copied"
else
    echo "  ⚠️  Headers not found, creating minimal header"
    cat > "$FRAMEWORK_DIR/Headers/MLCRuntime.h" << 'EOF'
// MLCRuntime Framework Header
#import <Foundation/Foundation.h>

FOUNDATION_EXPORT double MLCRuntimeVersionNumber;
FOUNDATION_EXPORT const unsigned char MLCRuntimeVersionString[];

// Import public headers
EOF
fi

# ライブラリを統合（fat binaryを作成）
echo "🔧 Combining static libraries..."
cd "$LIBS_PATH"

# libtoolを使用してすべてのライブラリを統合
libtool -static -o "$FRAMEWORK_DIR/$FRAMEWORK_NAME" \
    libmlc_llm.a \
    libmodel_iphone.a \
    libsentencepiece.a \
    libtokenizers_c.a \
    libtokenizers_cpp.a \
    libtvm_runtime.a

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
    header "MLCRuntime.h"
    export *
    
    explicit module Private {
        header "LLMEngine.h"
        export *
    }
}
EOF

# XCFrameworkを作成（現在はdeviceのみ）
echo "📦 Creating XCFramework..."
XCFRAMEWORK_PATH="$OUTPUT_DIR/${FRAMEWORK_NAME}.xcframework"
rm -rf "$XCFRAMEWORK_PATH"

xcodebuild -create-xcframework \
    -framework "$FRAMEWORK_DIR" \
    -output "$XCFRAMEWORK_PATH"

echo "✅ XCFramework created at: $XCFRAMEWORK_PATH"
echo "📊 Size: $(du -sh "$XCFRAMEWORK_PATH" | cut -f1)"

# チェックサムを計算
echo "🔐 Calculating checksum..."
cd "$OUTPUT_DIR"
CHECKSUM=$(swift package compute-checksum "${FRAMEWORK_NAME}.xcframework.zip" 2>/dev/null || \
           shasum -a 256 "${FRAMEWORK_NAME}.xcframework.zip" | cut -d' ' -f1 2>/dev/null || \
           echo "Checksum calculation failed")

if [ "$CHECKSUM" != "Checksum calculation failed" ]; then
    echo "✅ Checksum: $CHECKSUM"
    echo "$CHECKSUM" > "${FRAMEWORK_NAME}.xcframework.checksum"
else
    echo "⚠️  Note: Install swift-tools to generate package checksum"
fi

echo ""
echo "🎉 XCFramework creation complete!"
echo "📁 Framework: $XCFRAMEWORK_PATH"
echo "💡 Next steps:"
echo "   1. Upload XCFramework to GitHub Releases"
echo "   2. Update EdgeLLM Package.swift with binary target"
echo "   3. Test EdgeLLM with real MLC inference"