# Local Model Setup for SimpleChat

## ローカルモデルを使用したテスト手順

### 1. モデルをアプリバンドルにコピー

SimpleChatアプリがローカルのQwen2-0.5Bモデルを使用できるようにするには、以下の方法があります：

#### 方法A: シンボリックリンクを作成（開発用）

```bash
# SimpleChatアプリのビルドディレクトリにbundleフォルダを作成
cd ~/Library/Developer/Xcode/DerivedData/SimpleChat-*/Build/Products/Debug-iphonesimulator/SimpleChat.app
mkdir -p bundle
ln -s /Users/majimadaisuke/.cache/mlc_llm/model_weights/hf/mlc-ai/Qwen2-0.5B-Instruct-q0f16-MLC bundle/
```

#### 方法B: キャッシュディレクトリを直接参照するようコードを修正

EdgeLLM.swiftの`ensureModelAvailable`メソッドを一時的に修正して、キャッシュから直接読み込むようにする。

### 2. モデルライブラリの配置

コンパイル済みのモデルライブラリ（qwen2_q0f16_iphone.tar）も必要です：

```bash
# モデルライブラリをコピー
cp /Users/majimadaisuke/Downloads/mlc-llm/EdgeLLM/models/qwen2_q0f16_iphone.tar \
   /Users/majimadaisuke/Downloads/mlc-llm/ios/MLCChat/dist/lib/
```

### 3. 簡易テスト用の設定

最も簡単な方法は、EdgeLLMのコードを一時的に修正して、ハードコードされたパスを使用することです。

## 現在利用可能なローカルモデル

- **Qwen2-0.5B-Instruct-q0f16-MLC** (最小、推奨)
  - パス: `/Users/majimadaisuke/.cache/mlc_llm/model_weights/hf/mlc-ai/Qwen2-0.5B-Instruct-q0f16-MLC`
  - サイズ: 約1GB
  - コンパイル済み

- **その他のモデル**（未コンパイル）
  - gemma-2-2b-it-q4f16_1-MLC
  - Phi-3.5-mini-instruct-q4f16_1-MLC
  - Llama-3.2-3B-Instruct-q4f16_1-MLC