// Minimal OpenAI Protocol definitions for EdgeLLM
import Foundation

// Basic chat completion types needed for EdgeLLM
public struct ChatCompletionMessage: Codable {
    public var role: Role
    public var content: String
    
    public enum Role: String, Codable {
        case system
        case user
        case assistant
    }
    
    public init(role: Role, content: String) {
        self.role = role
        self.content = content
    }
}

public struct ChatCompletionRequest: Codable {
    public var messages: [ChatCompletionMessage]
    public var model: String
    public var max_tokens: Int?
    public var temperature: Float?
    public var stream: Bool
    
    public init(
        messages: [ChatCompletionMessage],
        model: String,
        max_tokens: Int? = nil,
        temperature: Float? = nil,
        stream: Bool = false
    ) {
        self.messages = messages
        self.model = model
        self.max_tokens = max_tokens
        self.temperature = temperature
        self.stream = stream
    }
}

public struct ChatCompletionResponse: Codable {
    public var id: String
    public var choices: [Choice]
    public var usage: Usage?
    
    public struct Choice: Codable {
        public var index: Int
        public var message: ChatCompletionMessage?
        public var delta: Delta?
        public var finish_reason: String?
        
        public struct Delta: Codable {
            public var content: String?
            
            public func asText() -> String {
                return content ?? ""
            }
        }
    }
    
    public struct Usage: Codable {
        public var prompt_tokens: Int
        public var completion_tokens: Int
        public var total_tokens: Int
    }
}

public struct StreamOptions: Codable {
    public var include_usage: Bool
    
    public init(include_usage: Bool = false) {
        self.include_usage = include_usage
    }
}