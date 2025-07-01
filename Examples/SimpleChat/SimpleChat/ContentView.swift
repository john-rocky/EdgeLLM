import SwiftUI
import EdgeLLM

struct ContentView: View {
    @State private var userInput = ""
    @State private var messages: [ChatMessage] = []
    @State private var isLoading = false
    @State private var selectedModel: EdgeLLM.Model = .qwen05b
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Model selector
                Picker("Model", selection: $selectedModel) {
                    Text("Qwen 0.5B").tag(EdgeLLM.Model.qwen05b)
                    Text("Gemma 2B").tag(EdgeLLM.Model.gemma2b)
                    Text("Phi-3.5 Mini").tag(EdgeLLM.Model.phi3_mini)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(messages) { message in
                                MessageView(message: message)
                            }
                            
                            if isLoading {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                    Text("Thinking...")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
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
                HStack {
                    TextField("Type a message...", text: $userInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(isLoading)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(userInput.isEmpty || isLoading ? .gray : .blue)
                    }
                    .disabled(userInput.isEmpty || isLoading)
                }
                .padding()
            }
            .navigationTitle("EdgeLLM Chat")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    func sendMessage() {
        let userMessage = ChatMessage(role: .user, content: userInput)
        messages.append(userMessage)
        
        let prompt = userInput
        userInput = ""
        isLoading = true
        
        Task {
            do {
                let response = try await EdgeLLM.chat(prompt, model: selectedModel)
                await MainActor.run {
                    messages.append(ChatMessage(role: .assistant, content: response))
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    messages.append(ChatMessage(role: .assistant, content: "Error: \(error.localizedDescription)"))
                    isLoading = false
                }
            }
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String
    
    enum Role {
        case user
        case assistant
    }
}

struct MessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top) {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading) {
                Text(message.role == .user ? "You" : "AI")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(message.content)
                    .padding(10)
                    .background(message.role == .user ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .cornerRadius(10)
            }
            
            if message.role == .assistant {
                Spacer()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}