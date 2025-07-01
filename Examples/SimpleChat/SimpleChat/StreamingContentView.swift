import SwiftUI
// Note: In a real app, import EdgeLLM package
// import EdgeLLM

// Alternative view with streaming support
struct StreamingContentView: View {
    @State private var userInput = ""
    @State private var currentResponse = ""
    @State private var isStreaming = false
    
    var body: some View {
        VStack {
            // Response area
            ScrollView {
                Text(currentResponse.isEmpty ? "Ask me anything!" : currentResponse)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
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
    }
    
    func streamResponse() {
        let prompt = userInput
        userInput = ""
        currentResponse = ""
        isStreaming = true
        
        Task {
            do {
                for try await token in EdgeLLM.stream(prompt) {
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
