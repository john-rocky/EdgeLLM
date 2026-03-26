import Foundation
import Combine

/// SwiftUI-friendly wrapper for EdgeLLM with observable state
@available(iOS 14.0, macOS 11.0, *)
public class EdgeLLMChat: ObservableObject {

    // MARK: - Published State

    @Published public private(set) var messages: [ChatMessage] = []
    @Published public private(set) var isGenerating: Bool = false
    @Published public private(set) var isModelLoaded: Bool = false
    @Published public private(set) var isDownloading: Bool = false
    @Published public private(set) var downloadProgress: Double = 0
    @Published public private(set) var error: Error?
    @Published public private(set) var currentStreamingText: String = ""

    // Performance metrics
    @Published public private(set) var tokensPerSecond: Double = 0
    @Published public private(set) var tokenCount: Int = 0
    @Published public private(set) var firstTokenLatency: TimeInterval = 0

    // MARK: - Types

    public struct ChatMessage: Identifiable {
        public let id: UUID
        public let role: Role
        public var content: String
        public let timestamp: Date

        public enum Role: String {
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

    // MARK: - Configuration

    public let model: EdgeLLM.Model
    public let options: EdgeLLM.Options

    // MARK: - Private

    private var llm: EdgeLLM?
    private let conversation: Conversation
    private var generationTask: Task<Void, Never>?

    // MARK: - Init

    /// Create a new chat instance
    /// - Parameters:
    ///   - model: Model to use
    ///   - options: Generation options
    ///   - systemPrompt: Optional system prompt
    public init(
        model: EdgeLLM.Model = .gemma2b,
        options: EdgeLLM.Options = .default,
        systemPrompt: String? = nil
    ) {
        self.model = model
        self.options = options
        self.conversation = Conversation(systemPrompt: systemPrompt)
    }

    // MARK: - Public Methods

    /// Load the model (call in .task or .onAppear)
    @MainActor
    public func load() async {
        guard !isModelLoaded else { return }
        isDownloading = true
        error = nil

        do {
            llm = try await EdgeLLM(model: model, options: options)
            isModelLoaded = true
        } catch {
            self.error = error
        }

        isDownloading = false
    }

    /// Send a message and stream the response
    @MainActor
    public func send(_ text: String) async {
        guard let llm = llm, !isGenerating else { return }

        // Add user message
        messages.append(ChatMessage(role: .user, content: text))

        // Prepare streaming state
        isGenerating = true
        error = nil
        currentStreamingText = ""
        tokenCount = 0
        let startTime = Date()
        var isFirstToken = true

        // Add placeholder assistant message
        messages.append(ChatMessage(role: .assistant, content: ""))
        let assistantIndex = messages.count - 1

        do {
            conversation.append(text, role: .user)
            for try await token in await llm.streamMessages(conversation.asChatMessages) {
                if isFirstToken {
                    firstTokenLatency = Date().timeIntervalSince(startTime)
                    isFirstToken = false
                }
                currentStreamingText += token
                tokenCount += 1
                let elapsed = Date().timeIntervalSince(startTime)
                if elapsed > 0 {
                    tokensPerSecond = Double(tokenCount) / elapsed
                }
                messages[assistantIndex].content = currentStreamingText
            }
            conversation.append(currentStreamingText, role: .assistant)
        } catch {
            self.error = error
        }

        isGenerating = false
    }

    /// Stop the current generation
    @MainActor
    public func stop() async {
        guard let llm = llm else { return }
        await llm.cancel()
        isGenerating = false
    }

    /// Clear all messages
    @MainActor
    public func clearMessages(keepSystemPrompt: Bool = true) {
        messages.removeAll()
        conversation.clear(keepSystemPrompt: keepSystemPrompt)
        currentStreamingText = ""
        tokenCount = 0
        tokensPerSecond = 0
        firstTokenLatency = 0
        error = nil
    }
}
