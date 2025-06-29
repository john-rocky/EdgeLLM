# EdgeLLMライブラリ構築戦略

## 現状の分析

### ✅ 達成したこと
1. EdgeLLM Swift APIの設計と動作確認
2. MLCSwiftを使った実装が安定動作
3. シンプルな3行APIの実現

### ❌ 課題
1. カスタムブリッジ(`reload_func_`)がハング
2. MLCライブラリ(.a)の直接リンクが必要
3. モデルファイルの手動配置が必要

## 🚀 ライブラリ化の3つのアプローチ

### アプローチ1: MLCSwiftラッパー版（短期的・現実的）

```
EdgeLLM
├── Package.swift
├── Sources/
│   └── EdgeLLM/
│       ├── EdgeLLM.swift (MLCSwiftをラップ)
│       ├── ModelManager.swift (モデル管理)
│       └── Downloader.swift (モデルダウンロード)
└── README.md
```

**メリット:**
- すぐに実装可能
- 安定動作が保証される
- MLCSwiftのアップデートに追従しやすい

**実装手順:**
1. MLCSwiftを依存関係として追加
2. EdgeLLM APIでMLCSwiftをラップ
3. モデル自動ダウンロード機能を追加

### アプローチ2: XCFramework版（中期的）

```
EdgeLLM.xcframework/
├── ios-arm64/
│   ├── EdgeLLM.framework/
│   └── libmlc_bundle.a (全ライブラリを統合)
└── ios-arm64-simulator/
    └── EdgeLLM.framework/
```

**メリット:**
- 1つのバイナリで配布
- Swift Package Managerで簡単インストール
- ライブラリの詳細を隠蔽

**実装手順:**
1. 全MLCライブラリを1つの.aに統合
2. EdgeLLMフレームワークを作成
3. XCFrameworkとしてビルド

### アプローチ3: ブリッジ修正版（長期的）

**調査が必要:**
- `reload_func_`がハングする原因
- 初期化シーケンスの問題
- スレッド/メモリ管理の違い

## 📋 推奨実装計画

### Phase 1: MLCSwiftラッパー版（1-2週間）

1. **基本構造の作成**
```swift
// Package.swift
dependencies: [
    .package(path: "../MLCSwift")
]

// EdgeLLM.swift
import MLCSwift

public class EdgeLLM {
    private let engine = MLCEngine()
    
    public init(modelId: String) async throws {
        // モデル自動ダウンロードチェック
        if !ModelManager.isModelAvailable(modelId) {
            try await ModelManager.downloadModel(modelId)
        }
        // MLCEngineでロード
    }
}
```

2. **モデル管理機能**
```swift
public class ModelManager {
    static func downloadModel(_ modelId: String) async throws {
        // HuggingFaceからダウンロード
        // キャッシュディレクトリに保存
        // 進捗表示
    }
}
```

3. **配布準備**
- READMEとドキュメント作成
- サンプルアプリ作成
- テスト追加

### Phase 2: XCFramework化（2-3週間）

1. **ビルドスクリプト作成**
```bash
#!/bin/bash
# build_framework.sh

# 全ライブラリを結合
libtool -static -o libmlc_bundle.a \
    libmlc_llm.a \
    libmodel_iphone.a \
    libtvm_runtime.a \
    libsentencepiece.a \
    libtokenizers_cpp.a

# XCFrameworkビルド
xcodebuild -create-xcframework \
    -framework ios-arm64/EdgeLLM.framework \
    -framework ios-simulator-arm64/EdgeLLM.framework \
    -output EdgeLLM.xcframework
```

2. **Package.swift for バイナリ配布**
```swift
// Package.swift
targets: [
    .binaryTarget(
        name: "EdgeLLM",
        url: "https://github.com/yourusername/EdgeLLM/releases/download/v0.1.0/EdgeLLM.xcframework.zip",
        checksum: "..."
    )
]
```

### Phase 3: 完全な独立実装（将来）

ブリッジ問題を解決して、MLCSwiftに依存しない実装を作成。

## 🎯 次のアクション

### 今すぐ始められること:

1. **GitHubリポジトリ作成**
```bash
git init EdgeLLM
cd EdgeLLM
swift package init --type library
```

2. **MLCSwiftラッパー実装**
- EdgeLLM_Demo.swiftをベースに整理
- エラーハンドリング追加
- ドキュメント作成

3. **モデルダウンローダー実装**
- URLSessionでHuggingFaceから取得
- 進捗表示とキャッシュ管理

4. **サンプルアプリ作成**
- SwiftUIとUIKit両方のサンプル
- 使い方のベストプラクティス

## 🔑 成功のポイント

1. **段階的アプローチ**
   - まずMLCSwiftラッパーで早期リリース
   - ユーザーフィードバックを収集
   - 徐々に独立性を高める

2. **開発者体験を最優先**
   - インストール1行
   - 使用3行
   - エラーメッセージを分かりやすく

3. **コミュニティ構築**
   - 詳細なドキュメント
   - サンプルコード
   - 問題解決ガイド

これでEdgeLLMを実用的なライブラリとして公開できます！