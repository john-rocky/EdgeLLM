import Foundation
import EdgeLLM

print("🚀 EdgeLLM Real Inference Test")

func testRealInference() async {
    do {
        print("📝 Testing EdgeLLM with local Qwen3-0.6B model...")
        
        // テスト1: ローカルモデルパスの確認
        let modelPath = EdgeLLM.localModelPaths[.qwen05b]
        print("🔍 Model path: \(modelPath ?? "Not found")")
        
        // テスト2: モデルファイルの存在確認
        if let path = modelPath {
            let fileManager = FileManager.default
            let exists = fileManager.fileExists(atPath: path)
            print("📂 Model exists: \(exists ? "✅ Yes" : "❌ No")")
            
            if exists {
                print("📊 Model files:")
                let configPath = "\(path)/mlc-chat-config.json"
                let tokenizerPath = "\(path)/tokenizer.json"
                print("  - Config: \(fileManager.fileExists(atPath: configPath) ? "✅" : "❌")")
                print("  - Tokenizer: \(fileManager.fileExists(atPath: tokenizerPath) ? "✅" : "❌")")
            }
        }
        
        // テスト3: 実際の推論テスト
        print("\n🤖 Attempting real inference...")
        let testPrompt = "Hello, how are you?"
        
        // ローカルモデルでのチャットを試行
        let response = try await EdgeLLM.chatWithLocalModel(
            testPrompt,
            model: .qwen05b
        )
        
        print("✅ Success! Response:")
        print("📤 Input: \(testPrompt)")
        print("📥 Output: \(response)")
        
    } catch {
        print("❌ Error during inference test: \(error)")
        
        if let edgeError = error as? EdgeLLMError {
            print("   EdgeLLM Error: \(edgeError.localizedDescription)")
        }
        
        print("\n💡 This is expected if:")
        print("   - MLC-LLM libraries are not properly linked")
        print("   - Model files are not in the correct format")
        print("   - GPU/Metal is not available")
    }
}

// メイン実行
Task {
    await testRealInference()
    print("\n🏁 Test completed.")
    exit(0)
}

RunLoop.main.run()