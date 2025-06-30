# EdgeLLM

iOSアプリで大規模言語モデル（LLM）を**たった1行**で使えるSwiftライブラリ

```swift
let response = try await EdgeLLM.chat("こんにちは！")
```

## 特徴

- 🚀 **超シンプル** - 1行でLLMとチャット
- 📱 **iOS最適化** - Metal GPU加速で高速動作
- 🔒 **プライバシー重視** - 全てデバイス上で処理
- 📦 **簡単インストール** - Swift Package Manager対応
- 🌊 **ストリーミング対応** - リアルタイムレスポンス

## インストール

### Swift Package Manager

Xcodeで以下の手順：

1. File → Add Package Dependencies
2. URLを入力: `https://github.com/john-rocky/EdgeLLM`
3. バージョンを選択して「Add Package」

または`Package.swift`に追加：

```swift
dependencies: [
    .package(url: "https://github.com/john-rocky/EdgeLLM", from: "0.1.0")
]
```

## 使い方

### 最もシンプルな使用例

```swift
import EdgeLLM

// 1行でチャット！
let response = try await EdgeLLM.chat("今日の天気はどうですか？")
print(response)
```

### ストリーミングレスポンス

```swift
// トークンごとにレスポンスを受信
for try await token in try await EdgeLLM.stream("物語を聞かせて") {
    print(token, terminator: "")
}
```

### カスタマイズ

```swift
// モデルとオプションを指定
let response = try await EdgeLLM.chat(
    "技術的な質問",
    model: .phi3_5_mini,  // 別のモデルを使用
    options: EdgeLLM.Options(
        temperature: 0.3,  // より確定的な回答
        maxTokens: 500
    )
)
```

### 高度な使用例

```swift
// LLMインスタンスを保持して会話を継続
let llm = try await EdgeLLM(model: .llama3_2)

// 複数回の会話
let response1 = try await llm.chat("私の名前は太郎です")
let response2 = try await llm.chat("私の名前を覚えていますか？")

// 会話履歴をリセット
await llm.reset()
```

## サポートモデル

| モデル | サイズ | 説明 |
|--------|--------|------|
| `.llama3_2` | 3B | Meta Llama 3.2 - バランスの取れた性能 |
| `.gemma2_2b` | 2B | Google Gemma 2 - 軽量で高速 |
| `.phi3_5_mini` | 3.8B | Microsoft Phi-3.5 - 技術的なタスクに最適 |

## サンプルアプリ

`Examples/SimpleChat`にサンプルアプリがあります：

```bash
cd Examples/SimpleChat
open SimpleChat.xcodeproj
```

## 必要環境

- iOS 14.0以上
- iPhone 12以降（Neural Engine搭載）
- Xcode 15.0以上

## パフォーマンス

iPhone 15 Proでの参考値：
- 初回ロード: 2-3秒
- トークン生成速度: 15-20 tokens/秒
- メモリ使用量: 2-3GB

## トラブルシューティング

### モデルが見つからない

初回実行時は自動的にモデルをダウンロードします（WiFi推奨）。

### メモリ不足

より小さいモデル（`.gemma2_2b`）を試してください：

```swift
let response = try await EdgeLLM.chat("Hello", model: .gemma2_2b)
```

## ライセンス

MIT License

## 貢献

プルリクエスト歓迎です！

## クレジット

EdgeLLMは[MLC-LLM](https://github.com/mlc-ai/mlc-llm)プロジェクトをベースにしています。