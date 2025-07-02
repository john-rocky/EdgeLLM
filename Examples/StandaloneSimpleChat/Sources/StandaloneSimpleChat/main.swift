import Foundation
import EdgeLLM

@main
struct StandaloneSimpleChat {
    static func main() async {
        print("🚀 EdgeLLM Standalone Test")
        print("=" * 50)
        
        do {
            // Test 1: Check if EdgeLLM can be imported
            print("✅ EdgeLLM package imported successfully")
            
            // Test 2: List available models
            print("\n📱 Available models:")
            for model in EdgeLLM.Model.allCases {
                print("  - \(model.displayName) (\(model.rawValue))")
            }
            
            // Test 3: Try to chat with local model
            print("\n💬 Testing chat with Qwen 0.5B model...")
            print("⏳ This may take a moment on first run...")
            
            let response = try await EdgeLLM.chat(
                "Hello! Can you introduce yourself in one sentence?",
                model: .qwen05b
            )
            
            print("\n🤖 Response: \(response)")
            print("\n✅ Test completed successfully!")
            
        } catch {
            print("\n❌ Error: \(error)")
            print("💡 Make sure the model is available locally or can be downloaded")
        }
        
        print("\n" + "=" * 50)
    }
}

extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}