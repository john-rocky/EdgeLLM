import SwiftUI
import EdgeLLM

struct ContentView: View {
    @State private var messages: [ChatMessage] = []
    @State private var userInput = ""
    @State private var isStreaming = false
    @State private var llm: EdgeLLM?
    @State private var selectedModel: EdgeLLM.Model = .qwen06b
    @State private var errorMessage = ""
    @State private var showError = false
    
    // Performance metrics
    @State private var tokenCount = 0
    @State private var startTime: Date?
    @State private var tokensPerSecond: Double = 0
    @State private var totalResponseTime: TimeInterval = 0
    @State private var firstTokenTime: TimeInterval = 0
    @State private var modelLoadTime: TimeInterval = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Model selector and performance metrics
                VStack(spacing: 12) {
                    // Model selector
                    HStack {
                        Text("Model:")
                            .font(.headline)
                        
                        Picker("Model", selection: $selectedModel) {
                            Text("Qwen3 0.6B").tag(EdgeLLM.Model.qwen06b)
                            Text("Gemma 2B").tag(EdgeLLM.Model.gemma2b)
                            Text("Phi-3.5 Mini").tag(EdgeLLM.Model.phi3_mini)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: selectedModel) { _ in
                            Task {
                                await loadModel()
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Performance metrics
                    if tokenCount > 0 || modelLoadTime > 0 {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                PerformanceMetricView(
                                    title: "Tokens/sec",
                                    value: String(format: "%.1f", tokensPerSecond),
                                    icon: "speedometer"
                                )
                                
                                PerformanceMetricView(
                                    title: "Total tokens",
                                    value: "\(tokenCount)",
                                    icon: "number"
                                )
                            }
                            
                            HStack {
                                PerformanceMetricView(
                                    title: "First token",
                                    value: String(format: "%.2fs", firstTokenTime),
                                    icon: "timer"
                                )
                                
                                PerformanceMetricView(
                                    title: "Model load",
                                    value: String(format: "%.2fs", modelLoadTime),
                                    icon: "cpu"
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .background(Color(.systemGroupedBackground))
                
                Divider()
                
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if isStreaming {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(0.8)
                                    Text("Generating...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _ in
                        withAnimation {
                            proxy.scrollTo(messages.last?.id, anchor: .bottom)
                        }
                    }
                }
                
                Divider()
                
                // Input area
                HStack(spacing: 12) {
                    TextField("Ask me anything...", text: $userInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(isStreaming || llm == nil)
                        .onSubmit {
                            sendMessage()
                        }
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(canSend ? .blue : .gray)
                    }
                    .disabled(!canSend)
                }
                .padding()
            }
            .navigationTitle("EdgeLLM Streaming")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: 
                Button(action: clearChat) {
                    Image(systemName: "trash")
                }
                .disabled(messages.isEmpty)
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            Task {
                await loadModel()
            }
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK")) {
                    errorMessage = ""
                }
            )
        }
    }
    
    private var canSend: Bool {
        !userInput.isEmpty && !isStreaming && llm != nil
    }
    
    private func loadModel() async {
        let loadStart = Date()
        
        do {
            llm = try await EdgeLLM(model: selectedModel)
            modelLoadTime = Date().timeIntervalSince(loadStart)
        } catch {
            errorMessage = "Failed to load model: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func sendMessage() {
        let userMessage = ChatMessage(
            role: .user,
            content: userInput,
            timestamp: Date()
        )
        messages.append(userMessage)
        
        let prompt = userInput
        userInput = ""
        isStreaming = true
        
        // Reset metrics
        tokenCount = 0
        tokensPerSecond = 0
        startTime = Date()
        firstTokenTime = 0
        
        // Create AI message placeholder
        let aiMessage = ChatMessage(
            role: .assistant,
            content: "",
            timestamp: Date()
        )
        messages.append(aiMessage)
        let aiMessageId = aiMessage.id
        
        Task {
            do {
                guard let llm = llm else {
                    throw EdgeLLMError.modelNotLoaded
                }
                
                var isFirstToken = true
                var responseContent = ""
                
                for try await token in llm.stream(prompt) {
                    if isFirstToken {
                        firstTokenTime = Date().timeIntervalSince(startTime!)
                        isFirstToken = false
                    }
                    
                    responseContent += token
                    tokenCount += 1
                    
                    // Update performance metrics
                    let elapsed = Date().timeIntervalSince(startTime!)
                    tokensPerSecond = Double(tokenCount) / elapsed
                    
                    // Update message content
                    await MainActor.run {
                        if let index = messages.firstIndex(where: { $0.id == aiMessageId }) {
                            messages[index].content = responseContent
                        }
                    }
                }
                
                // Final metrics
                totalResponseTime = Date().timeIntervalSince(startTime!)
                
            } catch {
                await MainActor.run {
                    errorMessage = "Streaming error: \(error.localizedDescription)"
                    showError = true
                    
                    // Update message with error
                    if let index = messages.firstIndex(where: { $0.id == aiMessageId }) {
                        messages[index].content = "Error: \(error.localizedDescription)"
                    }
                }
            }
            
            await MainActor.run {
                isStreaming = false
            }
        }
    }
    
    private func clearChat() {
        messages.removeAll()
        tokenCount = 0
        tokensPerSecond = 0
        totalResponseTime = 0
        firstTokenTime = 0
    }
}

// MARK: - Chat Message Model
struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    var content: String
    let timestamp: Date
    
    enum Role {
        case user
        case assistant
    }
}

// MARK: - Message Bubble View
struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.role == .user ? "You" : "AI")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(message.content)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(message.role == .user ? Color.blue : Color(.systemGray5))
                    )
                    .foregroundColor(message.role == .user ? .white : .primary)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.role == .user ? .trailing : .leading)
            
            if message.role == .assistant {
                Spacer()
            }
        }
    }
}

// MARK: - Performance Metric View
struct PerformanceMetricView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}