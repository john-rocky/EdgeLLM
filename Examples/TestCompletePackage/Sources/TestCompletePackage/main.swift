import EdgeLLM
import Foundation

@main
struct TestCompletePackage {
    static func main() async {
        print("Testing EdgeLLM Complete Package...")
        
        do {
            // Test with the simplest API
            let response = try await EdgeLLM.chat("Hello, world!")
            print("Response: \(response)")
            
            // Test with model selection
            let response2 = try await EdgeLLM.chat("What is 2+2?", model: .phi2)
            print("Response with Phi-2: \(response2)")
            
            print("✅ EdgeLLM Complete Package is working!")
        } catch {
            print("❌ Error: \(error)")
        }
    }
}