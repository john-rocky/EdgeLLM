# EdgeLLM XCFramework戦略（MLCSwiftラップ版）

## 📦 Phase 2実現の可能性

### ✅ YES、実現可能です！

MLCSwiftをラップしたままでも、以下の方法でXCFramework化できます：

## 🏗️ アーキテクチャ

```
EdgeLLM.xcframework/
├── ios-arm64/
│   └── EdgeLLM.framework/
│       ├── EdgeLLM (バイナリ)
│       ├── Headers/
│       ├── Modules/
│       └── Resources/
│           └── MLCBundle.bundle/
│               ├── libmlc_llm.a
│               ├── libtvm_runtime.a
│               ├── libmodel_iphone.a
│               ├── libsentencepiece.a
│               └── libtokenizers_cpp.a
└── ios-arm64-simulator/
    └── EdgeLLM.framework/
```

## 🔧 実装方法

### 方法1: 静的ライブラリを埋め込む（推奨）

```bash
#!/bin/bash
# build_xcframework.sh

# 1. EdgeLLMフレームワークをビルド
xcodebuild archive \
    -scheme EdgeLLM \
    -destination "generic/platform=iOS" \
    -archivePath "archives/EdgeLLM-iOS.xcarchive" \
    SKIP_INSTALL=NO

# 2. MLCライブラリを結合
cd archives/EdgeLLM-iOS.xcarchive/Products/Library/Frameworks/EdgeLLM.framework

# 全てのMLCライブラリを1つに結合
libtool -static -o libMLCBundle.a \
    /path/to/libmlc_llm.a \
    /path/to/libtvm_runtime.a \
    /path/to/libmodel_iphone.a \
    /path/to/libsentencepiece.a \
    /path/to/libtokenizers_cpp.a

# 3. フレームワークに埋め込む
# EdgeLLMバイナリとMLCライブラリを結合
lipo -create EdgeLLM libMLCBundle.a -output EdgeLLM_combined
mv EdgeLLM_combined EdgeLLM

# 4. XCFramework作成
xcodebuild -create-xcframework \
    -framework archives/EdgeLLM-iOS.xcarchive/Products/Library/Frameworks/EdgeLLM.framework \
    -framework archives/EdgeLLM-Simulator.xcarchive/Products/Library/Frameworks/EdgeLLM.framework \
    -output EdgeLLM.xcframework
```

### 方法2: Bundle Resourceとして含める

```swift
// EdgeLLM Package.swift
targets: [
    .binaryTarget(
        name: "EdgeLLM",
        path: "EdgeLLM.xcframework"
    ),
    .binaryTarget(
        name: "MLCLibraries",
        path: "MLCLibraries.xcframework"
    ),
    .target(
        name: "EdgeLLMWrapper",
        dependencies: ["EdgeLLM", "MLCLibraries"]
    )
]
```

## 📋 Package.swift（配布用）

```swift
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
            targets: ["EdgeLLMTarget"]
        ),
    ],
    targets: [
        // XCFrameworkをラップするターゲット
        .target(
            name: "EdgeLLMTarget",
            dependencies: [
                "EdgeLLM",
                "EdgeLLMResources"
            ],
            linkerSettings: [
                .linkedFramework("Metal"),
                .linkedFramework("MetalPerformanceShaders"),
                .linkedFramework("MetalPerformanceShadersGraph")
            ]
        ),
        
        // バイナリターゲット
        .binaryTarget(
            name: "EdgeLLM",
            url: "https://github.com/yourusername/EdgeLLM/releases/download/v0.1.0/EdgeLLM.xcframework.zip",
            checksum: "abc123..."
        ),
        
        // リソースバンドル
        .target(
            name: "EdgeLLMResources",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
```

## 🎯 メリット

### 1. **完全な1行インストール**
```swift
dependencies: [
    .package(url: "https://github.com/yourusername/EdgeLLM", from: "0.1.0")
]
```

### 2. **ライブラリ管理不要**
- ユーザーは個別の.aファイルを扱う必要なし
- リンカー設定も自動

### 3. **MLCSwiftの更新に対応**
- 内部実装はMLCSwiftのまま
- APIの安定性を保証

## ⚠️ 考慮事項

### 1. **ファイルサイズ**
- 全ライブラリ含めて約200-300MB
- Git LFSまたはGitHub Releasesでホスト

### 2. **ビルド設定**
```swift
// ユーザー側で必要な設定
Other Linker Flags: -Wl,-all_load
Enable Bitcode: No
```

### 3. **署名とNotarization**
- XCFrameworkは署名が必要
- macOS版はNotarizationも必要

## 🔄 移行パス

### Phase 1 → Phase 2

1. **現在のソースコード版**
   ```swift
   // ユーザーが手動でMLCライブラリをリンク
   .package(path: "../EdgeLLM-Swift")
   ```

2. **XCFramework版へ移行**
   ```swift
   // 自動的に全て含まれる
   .package(url: "https://github.com/yourusername/EdgeLLM", from: "0.2.0")
   ```

## 📊 実装優先順位

1. **まずソースコード版をリリース**（1-2週間）
   - フィードバック収集
   - API安定化

2. **XCFrameworkビルドスクリプト作成**（1週間）
   - CI/CD設定
   - 自動ビルド

3. **XCFramework版リリース**（2-3週間後）
   - より簡単なインストール
   - 企業ユーザー向け

## 結論

MLCSwiftをラップしたままでも、XCFramework化は完全に可能です。むしろ、この方法の方が：
- 実装が早い
- メンテナンスが楽
- ユーザー体験が良い

という利点があります！