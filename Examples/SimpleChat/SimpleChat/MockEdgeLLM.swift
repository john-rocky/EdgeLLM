import Foundation

// Mock EdgeLLM for SimpleChat demo
// In a real app, use the actual EdgeLLM package

public struct EdgeLLM {
    
    public enum Model: String, CaseIterable {
        case qwen05b = "Qwen 0.5B"
        case gemma2b = "Gemma 2B"
        case phi3_mini = "Phi-3.5 Mini"
    }
    
    public struct Options {
        public var temperature: Float
        public var maxTokens: Int
        public var topP: Float
        
        public static let `default` = Options(
            temperature: 0.7,
            maxTokens: 2048,
            topP: 0.95
        )
        
        public init(temperature: Float = 0.7, maxTokens: Int = 2048, topP: Float = 0.95) {
            self.temperature = temperature
            self.maxTokens = maxTokens
            self.topP = topP
        }
    }
    
    public static func chat(_ prompt: String, model: Model = .gemma2b, options: Options = .default) async throws -> String {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Return mock response
        let modelInfo = """
        🤖 Mock Response from \(model.rawValue)
        
        This is a simulated response. In the actual implementation:
        - Model would be loaded from: /Users/majimadaisuke/.cache/mlc_llm/model_weights/hf/mlc-ai/\(model.rawValue)
        - Response would be generated using Metal GPU acceleration
        - First run would take ~5-10 seconds to load the model
        
        Your prompt: "\(prompt)"
        """
        return modelInfo
    }
    
    public static func stream(_ prompt: String, model: Model = .gemma2b, options: Options = .default) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let response = "This is a streaming response from \(model.rawValue). Your prompt was: \"\(prompt)\""
                let words = response.split(separator: " ")
                
                for word in words {
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                    continuation.yield(String(word) + " ")
                }
                
                continuation.finish()
            }
        }
    }
}