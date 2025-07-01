#!/usr/bin/env swift

import Foundation

// EdgeLLMをテストするための簡単なスクリプト
// ローカルモデルでの動作確認用

print("EdgeLLM Local Test Starting...")

// テスト用の関数を定義
func testEdgeLLM() async {
    do {
        print("Loading EdgeLLM with Qwen 0.6B model...")
        
        // ローカルモデルパスを使って直接テスト
        let modelPath = "/Users/agmajima/.cache/mlc_llm/model_weights/hf/mlc-ai/Qwen3-0.6B-q0f16-MLC"
        
        // ディレクトリの存在を確認
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: modelPath) {
            print("✅ Model found at: \(modelPath)")
            
            // EdgeLLMをインポートしてテスト（実際にはSwiftコンパイル時にEdgeLLMパッケージが必要）
            print("📝 Test prompt: 'Hello, how are you?'")
            
            // NOTE: この部分は実際のEdgeLLMパッケージがリンクされた時に動作する
            // let response = try await EdgeLLM.chatWithLocalModel("Hello, how are you?", model: .qwen05b)
            // print("🤖 Response: \(response)")
            
            print("⚠️  EdgeLLMパッケージをリンクすることで実際のテストが可能になります")
            
        } else {
            print("❌ Model not found at: \(modelPath)")
        }
        
    } catch {
        print("❌ Error: \(error)")
    }
}

// 非同期関数を実行
Task {
    await testEdgeLLM()
    print("Test completed.")
    exit(0)
}

// メインスレッドをブロック
RunLoop.main.run()