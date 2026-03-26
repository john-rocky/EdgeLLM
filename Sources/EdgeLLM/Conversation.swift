import Foundation

/// Manages multi-turn conversation state for EdgeLLM
@available(iOS 14.0, macOS 11.0, *)
public final class Conversation: @unchecked Sendable {

    public struct Message: Identifiable, Sendable {
        public let id: UUID
        public let role: Role
        public let content: String
        public let timestamp: Date

        public enum Role: String, Sendable {
            case system
            case user
            case assistant
        }

        public init(role: Role, content: String) {
            self.id = UUID()
            self.role = role
            self.content = content
            self.timestamp = Date()
        }
    }

    /// All messages in this conversation
    public private(set) var messages: [Message] = []

    /// Create a new conversation
    /// - Parameter systemPrompt: Optional system prompt to set context
    public init(systemPrompt: String? = nil) {
        if let sp = systemPrompt {
            messages.append(Message(role: .system, content: sp))
        }
    }

    /// Append a message to the conversation
    public func append(_ content: String, role: Message.Role) {
        messages.append(Message(role: role, content: content))
    }

    /// Clear all messages
    /// - Parameter keepSystemPrompt: If true, preserves the initial system prompt
    public func clear(keepSystemPrompt: Bool = true) {
        if keepSystemPrompt, let first = messages.first, first.role == .system {
            messages = [first]
        } else {
            messages.removeAll()
        }
    }

    /// Number of messages (excluding system prompt)
    public var messageCount: Int {
        messages.filter { $0.role != .system }.count
    }

    // MARK: - Internal

    internal var asChatMessages: [ChatCompletionMessage] {
        messages.map { msg in
            let role: ChatCompletionRole
            switch msg.role {
            case .system:    role = .system
            case .user:      role = .user
            case .assistant: role = .assistant
            }
            return ChatCompletionMessage(role: role, content: msg.content)
        }
    }
}
