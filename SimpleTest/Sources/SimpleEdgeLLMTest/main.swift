import Foundation

print("🚀 EdgeLLM Simple Test - Package Compilation")

// EdgeLLMの基本的な型とエラーを定義（テスト用）
enum TestModel: String {
    case qwen05b = "Qwen3-0.6B"
    case gemma2b = "Gemma-2B"
    case phi3_mini = "Phi-3.5-mini"
}

enum TestError: LocalizedError {
    case modelNotFound(String)
    case compilationTest
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound(let model):
            return "Model '\(model)' not found"
        case .compilationTest:
            return "This is a compilation test"
        }
    }
}

// 基本的なasync/awaitテスト
func testAsyncAwait() async throws -> String {
    try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
    return "Async/await works!"
}

// モデルファイルの存在確認
func checkModels() {
    let modelPaths = [
        "/Users/agmajima/.cache/mlc_llm/model_weights/hf/mlc-ai/Qwen3-0.6B-q0f16-MLC",
        "/Users/agmajima/.cache/mlc_llm/model_weights/hf/mlc-ai/gemma-2-2b-it-q4f16_1-MLC",
        "/Users/agmajima/.cache/mlc_llm/model_weights/hf/mlc-ai/Phi-3.5-mini-instruct-q4f16_1-MLC"
    ]
    
    let fileManager = FileManager.default
    print("\n📂 Model Files Check:")
    
    for (index, path) in modelPaths.enumerated() {
        let modelName = ["Qwen3-0.6B", "Gemma-2-2B", "Phi-3.5-mini"][index]
        let exists = fileManager.fileExists(atPath: path)
        print("  \(exists ? "✅" : "❌") \(modelName): \(exists ? "Found" : "Not Found")")
    }
}

// メイン関数
Task {
    print("🔍 Testing basic Swift features...")
    
    // 1. 基本的なasync/awaitテスト
    do {
        let result = try await testAsyncAwait()
        print("✅ Async/await: \(result)")
    } catch {
        print("❌ Async/await failed: \(error)")
    }
    
    // 2. Enumとエラーハンドリング
    do {
        let model = TestModel.qwen05b
        print("✅ Enum test: \(model.rawValue)")
        
        throw TestError.compilationTest
    } catch let error as TestError {
        print("✅ Error handling: \(error.localizedDescription)")
    } catch {
        print("❌ Unexpected error: \(error)")
    }
    
    // 3. モデルファイルの確認
    checkModels()
    
    print("\n🎉 Basic Swift features working correctly!")
    print("💡 Next step: Integrate with actual EdgeLLM package")
    
    exit(0)
}

RunLoop.main.run()