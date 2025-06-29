import Foundation
import os
import MLCSwift

// EdgeLLM API that uses MLCSwift internally
@available(iOS 14.0, macOS 13.0, *)
public actor EdgeLLM_MLCChat {
    
    // MARK: - Properties
    
    private let engine = MLCEngine()
    private let modelId: String
    private var isLoaded = false
    private let logger = Logger(subsystem: "ai.edge.llm", category: "EdgeLLM")
    
    // MARK: - Public Types
    
    public struct Options {
        public var temperature: Float
        public var maxTokens: Int
        public var topP: Float
        
        public static let `default` = Options(
            temperature: 0.7,
            maxTokens: 2048,
            topP: 0.95
        )
        
        public init(
            temperature: Float = 0.7,
            maxTokens: Int = 2048,
            topP: Float = 0.95
        ) {
            self.temperature = temperature
            self.maxTokens = maxTokens
            self.topP = topP
        }
    }
    
    // MARK: - Initialization
    
    /// Initialize EdgeLLM with a model ID using MLCEngine
    public init(modelId: String, options: Options = .default) async throws {
        self.modelId = modelId
        
        print("🔍 EdgeLLM_MLCChat: Initializing with model: \(modelId)")
        
        // Load model using MLCEngine
        try await loadModel(modelId: modelId)
    }
    
    // MARK: - Public Methods
    
    /// Send a chat message and receive a complete response
    public func chat(_ prompt: String) async throws -> String {
        guard isLoaded else {
            throw EdgeLLMError.modelNotLoaded
        }
        
        print("💬 EdgeLLM_MLCChat: Starting chat with prompt: \(prompt)")
        
        var fullResponse = ""
        
        for try await token in stream(prompt) {
            fullResponse += token
        }
        
        return fullResponse
    }
    
    /// Stream a chat response token by token
    public func stream(_ prompt: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                guard self.isLoaded else {
                    continuation.finish(throwing: EdgeLLMError.modelNotLoaded)
                    return
                }
                
                print("🔄 EdgeLLM_MLCChat: Starting stream for prompt: \(prompt)")
                
                // Create chat request using MLCSwift
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
                        // Process streaming response
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
                    print("❌ EdgeLLM_MLCChat: Stream error: \(error)")
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    /// Reset the conversation context
    public func reset() async {
        await engine.reset()
    }
    
    /// Unload the current model
    public func unload() async {
        await engine.unload()
        isLoaded = false
    }
    
    // MARK: - Private Methods
    
    private func loadModel(modelId: String) async throws {
        print("🔍 EdgeLLM_MLCChat: Loading model with ID: \(modelId)")
        
        // Use Bundle.main to find model path (same as MLCChat)
        guard let modelPath = Bundle.main.path(forResource: "Llama-3.2-3B-Instruct-q4f16_1-MLC", ofType: nil) else {
            // Try bundle root
            let bundlePath = Bundle.main.resourcePath ?? ""
            print("📁 EdgeLLM_MLCChat: Using bundle root: \(bundlePath)")
            
            // Check if model files exist in bundle root
            let configPath = bundlePath + "/mlc-chat-config.json"
            guard FileManager.default.fileExists(atPath: configPath) else {
                print("❌ EdgeLLM_MLCChat: Model config not found")
                throw EdgeLLMError.modelNotFound(modelId)
            }
            
            // Load model using bundle root
            print("🔄 EdgeLLM_MLCChat: Loading model from bundle root...")
            await engine.reload(modelPath: bundlePath, modelLib: "model_iphone")
            isLoaded = true
            print("✅ EdgeLLM_MLCChat: Model loaded successfully!")
            return
        }
        
        // Load model using found path
        print("🔄 EdgeLLM_MLCChat: Loading model from: \(modelPath)")
        await engine.reload(modelPath: modelPath, modelLib: "model_iphone")
        isLoaded = true
        print("✅ EdgeLLM_MLCChat: Model loaded successfully!")
    }
}

// MARK: - Supporting Types

public enum EdgeLLMError: LocalizedError {
    case modelNotFound(String)
    case modelNotLoaded
    case downloadFailed(String)
    case checksumMismatch
    case insufficientMemory
    case invalidConfiguration
    
    public var errorDescription: String? {
        switch self {
        case .modelNotFound(let id):
            return "Model '\(id)' not found"
        case .modelNotLoaded:
            return "No model is currently loaded"
        case .downloadFailed(let reason):
            return "Model download failed: \(reason)"
        case .checksumMismatch:
            return "Downloaded model checksum does not match"
        case .insufficientMemory:
            return "Insufficient memory to load model"
        case .invalidConfiguration:
            return "Invalid model configuration"
        }
    }
}