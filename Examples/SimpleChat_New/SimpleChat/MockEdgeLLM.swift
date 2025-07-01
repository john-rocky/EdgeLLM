import Foundation

// Temporary mock for testing SimpleChat UI
// This will be replaced with actual EdgeLLM package

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
    
    public static func chat(_ prompt: String, model: Model = .qwen05b, options: Options = .default) async throws -> String {
        // Simulate processing delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Return a simple response
        return "This is a test response from \(model.rawValue). Your prompt was: \"\(prompt)\""
    }
    
    public static func stream(_ prompt: String, model: Model = .qwen05b, options: Options = .default) -> AsyncThrowingStream<String, Error> {
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