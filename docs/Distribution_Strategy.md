# EdgeLLM Distribution Strategy

## 問題
- XCFrameworkのサイズ: 200-300MB
- GitHubのファイルサイズ制限: 100MB
- Swift Package Managerでの配布が必要

## 解決策

### Option 1: GitHub Releases (推奨)
```swift
.binaryTarget(
    name: "EdgeLLM",
    url: "https://github.com/yourusername/EdgeLLM/releases/download/v0.2.0/EdgeLLM.xcframework.zip",
    checksum: "..."
)
```

**メリット:**
- 2GBまでアップロード可能
- バージョン管理が簡単
- ダウンロード統計が見れる

**デメリット:**
- GitHubのレート制限あり

### Option 2: モジュール分割
```
EdgeLLM-Core (10MB) - 基本機能のみ
EdgeLLM-Runtime (200MB) - MLCランタイム
EdgeLLM-Models - モデルは別途ダウンロード
```

### Option 3: ダイナミックダウンロード
```swift
// 初回起動時にランタイムをダウンロード
try await EdgeLLM.downloadRuntime()
let response = try await EdgeLLM.chat("Hello")
```

### Option 4: 軽量版の提供
- ソースコード版 (v0.1.x) - 開発者向け
- バイナリ版 (v0.2.x) - GitHub Releases
- クラウド版 (v0.3.x) - API経由

## 推奨アプローチ

1. **Phase 1**: ソースコード版をリリース（今すぐ可能）
   - ユーザーが自分でMLC-LLMをビルド
   - 上級開発者向け

2. **Phase 2**: GitHub Releasesでバイナリ配布
   - XCFrameworkをzip圧縮
   - Package.swiftでURL指定

3. **Phase 3**: インテリジェントなランタイム管理
   - 必要な部分だけダウンロード
   - キャッシュ管理
   - アップデート機能

## 実装例

### 軽量なPackage.swift
```swift
let package = Package(
    name: "EdgeLLM",
    products: [
        .library(name: "EdgeLLM", targets: ["EdgeLLM"]),
        .library(name: "EdgeLLMRuntime", targets: ["EdgeLLMRuntime"])
    ],
    targets: [
        // コアライブラリ（軽量）
        .target(
            name: "EdgeLLM",
            dependencies: []
        ),
        // ランタイム（別途ダウンロード）
        .binaryTarget(
            name: "EdgeLLMRuntime",
            url: "https://cdn.example.com/EdgeLLMRuntime.xcframework.zip",
            checksum: "..."
        )
    ]
)
```

### ランタイムローダー
```swift
public class EdgeLLMRuntimeLoader {
    static func ensureRuntimeAvailable() async throws {
        if !isRuntimeInstalled() {
            try await downloadRuntime()
        }
    }
    
    private static func downloadRuntime() async throws {
        // GitHub ReleasesやCDNからダウンロード
        let url = URL(string: "https://github.com/.../EdgeLLMRuntime.zip")!
        // ダウンロードとインストール処理
    }
}
```