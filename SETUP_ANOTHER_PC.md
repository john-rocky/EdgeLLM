# 別のPCでEdgeLLM SimpleChatを実機ビルドする手順

## 1. 必要なもの
- Mac（Xcodeがインストール可能）
- iPhone/iPad（iOS 14.0以降）
- Apple Developer Account（無料でOK）
- USBケーブル

## 2. リポジトリのクローン

```bash
# EdgeLLMリポジトリをクローン
git clone https://github.com/john-rocky/EdgeLLM.git
cd EdgeLLM
git checkout complete-package
```

## 3. SimpleChatプロジェクトを開く

```bash
cd Examples/SimpleChat
open SimpleChat.xcodeproj
```

## 4. Xcodeでの設定

### 4.1 開発チームの設定
1. プロジェクトナビゲーターで `SimpleChat` を選択
2. `Signing & Capabilities` タブを開く
3. `Team` で自分のApple IDを選択（なければ追加）
4. `Bundle Identifier` を一意のものに変更（例: `com.yourname.SimpleChat`）

### 4.2 実機の接続
1. iPhoneをUSBで接続
2. iPhoneで「このコンピュータを信頼」を選択
3. Xcodeの上部バーで、デバイスとして自分のiPhoneを選択

### 4.3 ビルド設定の確認
1. `Build Settings` → `Other Linker Flags` に以下があることを確認：
   ```
   -Wl,-all_load
   ```

## 5. モデルファイルの準備（オプション）

実機でモデルをダウンロードするか、事前に配置：

### オプション1: アプリ内でダウンロード（推奨）
- 何もしない。アプリが初回起動時に自動でダウンロード

### オプション2: 事前にモデルを配置
```bash
# Mac上でモデルをダウンロード
mkdir -p ~/Downloads/models
cd ~/Downloads/models

# Qwen 0.5Bモデルをダウンロード（例）
git clone https://huggingface.co/mlc-ai/Qwen3-0.6B-q0f16-MLC
```

## 6. ビルドと実行

1. `Product` → `Clean Build Folder` (Shift+Cmd+K)
2. `Product` → `Run` (Cmd+R)

## 7. 初回実行時の設定

### iPhoneでの設定
初回実行時にエラーが出る場合：
1. iPhone: `設定` → `一般` → `デバイス管理`
2. 開発者アプリケーションで自分のApple IDを選択
3. 「信頼」をタップ

## 8. トラブルシューティング

### エラー: "Missing package product 'EdgeLLM'"
```bash
# Xcodeで
File → Packages → Reset Package Caches
File → Packages → Resolve Package Versions
```

### エラー: "Function mlc.json_ffi.CreateJSONFFIEngine not found"
- Build Settings → Other Linker Flags に `-Wl,-all_load` が設定されているか確認

### エラー: "Cannot open model file"
- モデルがダウンロードされているか確認
- アプリにインターネット接続許可があるか確認

## 9. 必要なディスク容量

- Xcode: 約15GB
- EdgeLLMリポジトリ: 約100MB
- モデルファイル（各）: 約300MB-1GB

## 10. パフォーマンスのヒント

- iPhone 12以降推奨（Neural Engine搭載）
- 初回のモデルロードは時間がかかる（1-2分）
- 2回目以降は高速（数秒）

## 注意事項

- 実機ビルドには Apple Developer Account が必要（無料でOK）
- 初回は証明書の作成に時間がかかる場合がある
- モデルファイルは大きいので、Wi-Fi環境推奨

## サポート

問題が発生した場合：
- GitHub Issues: https://github.com/john-rocky/EdgeLLM/issues
- サンプルコード: Examples/SimpleChat