import Foundation
import EdgeLLM

print("🚀 EdgeLLM Test App Starting...")

func testEdgeLLM() async {
    do {
        print("📝 Testing EdgeLLM with local model...")
        
        // ローカルモデルを使用してチャット
        let response = try await EdgeLLM.chatWithLocalModel("Hello, how are you?", model: .qwen05b)
        
        print("🤖 Response from EdgeLLM:")
        print(response)
        
        print("\n✅ EdgeLLM test completed successfully!")
        
    } catch {
        print("❌ Error testing EdgeLLM: \(error)")
        if let edgeLLMError = error as? EdgeLLMError {
            print("   EdgeLLM specific error: \(edgeLLMError)")
        }
    }
}

// 非同期関数を実行
Task {
    await testEdgeLLM()
    exit(0)
}

// メインスレッドをブロック
RunLoop.main.run()