# EdgeLLM - 次のステップ

## 現在の状況

1. **EdgeLLMパッケージ構造が修正済み**
   - Package.swiftがソースベースの配布に変更済み
   - MLCSwiftへの依存関係が設定済み
   - DEBUG時にローカルのMLCキャッシュモデルを使用するよう設定済み

2. **Qwen 0.5Bモデルがコンパイル済み**
   - myenv conda環境でコンパイル完了
   - モデルパス: `/Users/majimadaisuke/.cache/mlc_llm/model_weights/hf/mlc-ai/Qwen2-0.5B-Instruct-q0f16-MLC`

3. **SimpleChatアプリ**
   - MockEdgeLLMで動作確認可能
   - 実際のEdgeLLMパッケージとの統合準備完了

## 別のPCで作業を続ける手順

### 1. リポジトリのクローン
```bash
# EdgeLLMリポジトリをクローン
git clone https://github.com/john-rocky/EdgeLLM.git
cd EdgeLLM
git checkout complete-package

# MLC-LLMリポジトリもクローン（EdgeLLMの親ディレクトリとして）
cd ..
git clone https://github.com/mlc-ai/mlc-llm.git
mv EdgeLLM mlc-llm/
```

### 2. 環境セットアップ
```bash
# MLC-LLMのビルド環境をセットアップ
cd mlc-llm
# conda環境を作成（myenvという名前で）
conda create -n myenv python=3.10
conda activate myenv
pip install -e python
```

### 3. モデルのコンパイル（必要な場合）
```bash
# Qwen 0.5Bモデルをコンパイル
mlc_llm compile \
  --model Qwen/Qwen2-0.5B-Instruct \
  --target iphone \
  --quantization q0f16 \
  --max-seq-len 1024
```

### 4. SimpleChatアプリのテスト

#### A. MockEdgeLLMでのテスト（簡単）
1. Xcodeで `EdgeLLM/Examples/SimpleChat/SimpleChat.xcodeproj` を開く
2. スキームがない場合は作成:
   - Product > Scheme > New Scheme...
   - Name: SimpleChat, Target: SimpleChat
3. ビルドして実行

#### B. 実際のEdgeLLMパッケージでのテスト
1. SimpleChatプロジェクトにEdgeLLMパッケージを追加:
   - File > Add Package Dependencies...
   - ローカルパッケージとして `/path/to/mlc-llm/EdgeLLM` を追加
2. ContentView.swiftでimport文を有効化:
   ```swift
   import EdgeLLM // コメントアウトを解除
   ```
3. MockEdgeLLM.swiftを削除
4. ビルドして実行

### 5. 問題が発生した場合

**"No scheme"エラーの場合:**
- Xcodeで新規プロジェクトを作成
- 既存のSwiftファイルをコピー

**パッケージ解決エラーの場合:**
- DerivedDataを削除: `rm -rf ~/Library/Developer/Xcode/DerivedData/*`
- Package.resolvedを削除: `rm Package.resolved`

**モデルが見つからない場合:**
- EdgeLLM.swiftの`modelPath`メソッドでパスを確認
- DEBUG時はローカルキャッシュを使用するよう設定済み

## 重要なポイント

- EdgeLLMは実際のMLC-LLMエンジンを使用（モックではない）
- ローカルでコンパイル済みのQwen 0.5Bモデルを使用可能
- SimpleChatアプリで動作確認が必要

## 参考資料

- PACKAGE_VERIFICATION.md: パッケージの現在の状態の詳細
- EdgeLLM_AI_Agent_Spec.md: EdgeLLMの設計仕様
- CLAUDE.md: プロジェクト全体のガイドライン