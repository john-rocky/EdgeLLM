import SwiftUI
import EdgeLLM

// Alternative view with streaming support
struct StreamingContentView: View {
    @State private var userInput = ""
    @State private var currentResponse = ""
    @State private var isStreaming = false
    @State private var llm: EdgeLLM?
    @State private var errorMessage = ""
    
    var body: some View {
        VStack {
            // Response area
            ScrollView {
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(currentResponse.isEmpty ? "Ask me anything!" : currentResponse)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            Divider()
            
            // Input area
            HStack {
                TextField("Type a message...", text: $userInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(isStreaming)
                
                Button(action: streamResponse) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(userInput.isEmpty || isStreaming ? .gray : .blue)
                }
                .disabled(userInput.isEmpty || isStreaming)
            }
            .padding()
        }
        .navigationTitle("EdgeLLM Stream")
        .onAppear {
            Task {
                do {
                    llm = try await EdgeLLM(model: .qwen05b)
                } catch {
                    errorMessage = "Failed to initialize: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func streamResponse() {
        let prompt = userInput
        userInput = ""
        currentResponse = ""
        isStreaming = true
        
        Task {
            do {
                guard let llm = llm else {
                    throw EdgeLLMError.modelNotLoaded
                }
                for try await token in llm.stream(prompt) {
                    await MainActor.run {
                        currentResponse += token
                    }
                }
            } catch {
                await MainActor.run {
                    currentResponse = "Error: \(error.localizedDescription)"
                }
            }
            
            await MainActor.run {
                isStreaming = false
            }
        }
    }
}