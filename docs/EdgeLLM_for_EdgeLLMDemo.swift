import Foundation
import os
import MLCSwift

// EdgeLLM API implementation using MLCSwift directly for EdgeLLMDemo
@available(iOS 14.0, macOS 13.0, *)
public actor EdgeLLM_Demo {
    
    // MARK: - Properties
    
    private let engine = MLCEngine()
    private let modelId: String
    private var isLoaded = false
    
    // MARK: - Initialization
    
    public init(modelId: String) async throws {
        self.modelId = modelId
        print("🔍 EdgeLLM_Demo: Initializing with model: \(modelId)")
        try await loadModel(modelId: modelId)
    }
    
    // MARK: - Public Methods
    
    public func chat(_ prompt: String) async throws -> String {
        guard isLoaded else {
            throw EdgeLLMError.modelNotLoaded
        }
        
        var fullResponse = ""
        
        for try await token in stream(prompt) {
            fullResponse += token
        }
        
        return fullResponse
    }
    
    public func stream(_ prompt: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                guard self.isLoaded else {
                    continuation.finish(throwing: EdgeLLMError.modelNotLoaded)
                    return
                }
                
                let request = ChatCompletionRequest(
                    messages: [
                        ChatCompletionMessage(role: .user, content: prompt)
                    ],
                    model: self.modelId,
                    max_tokens: 2048,
                    stream: true,
                    temperature: 0.7
                )
                
                do {
                    for try await response in await self.engine.chat.completions.create(
                        messages: request.messages,
                        model: request.model,
                        max_tokens: request.max_tokens,
                        temperature: request.temperature,
                        stream_options: StreamOptions(include_usage: true)
                    ) {
                        for choice in response.choices {
                            if let content = choice.delta.content {
                                let token = content.asText()
                                if !token.isEmpty {
                                    continuation.yield(token)
                                }
                            }
                            
                            if choice.finish_reason != nil {
                                continuation.finish()
                                return
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    print("❌ EdgeLLM_Demo: Stream error: \(error)")
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    public func reset() async {
        await engine.reset()
    }
    
    public func unload() async {
        await engine.unload()
        isLoaded = false
    }
    
    // MARK: - Private Methods
    
    private func loadModel(modelId: String) async throws {
        print("🔍 EdgeLLM_Demo: Loading model with ID: \(modelId)")
        
        // Use same path resolution as EdgeLLM
        let bundleURL = Bundle.main.bundleURL.appendingPathComponent("bundle")
        let modelURL = bundleURL.appendingPathComponent(modelId)
        let modelPath = modelURL.path
        
        print("📁 EdgeLLM_Demo: Model path: \(modelPath)")
        
        // Check if model exists
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: modelPath, isDirectory: &isDirectory) && isDirectory.boolValue else {
            print("❌ EdgeLLM_Demo: Model directory not found at: \(modelPath)")
            throw EdgeLLMError.modelNotFound(modelId)
        }
        
        print("✅ EdgeLLM_Demo: Found model directory")
        
        // Load model using MLCEngine
        print("🔄 EdgeLLM_Demo: Loading model...")
        await engine.reload(modelPath: modelPath, modelLib: "llama_q4f16_1_d44304359a2802d16aa168086928bcad")
        isLoaded = true
        print("✅ EdgeLLM_Demo: Model loaded successfully!")
    }
}

// Error types
public enum EdgeLLMError: LocalizedError {
    case modelNotFound(String)
    case modelNotLoaded
    
    public var errorDescription: String? {
        switch self {
        case .modelNotFound(let id):
            return "Model '\(id)' not found"
        case .modelNotLoaded:
            return "No model is currently loaded"
        }
    }
}