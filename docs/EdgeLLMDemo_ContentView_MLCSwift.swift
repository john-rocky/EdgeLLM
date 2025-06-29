import SwiftUI
// EdgeLLMの代わりにMLCSwift版を使用
// import EdgeLLM

struct ContentView: View {
    @State private var input = ""
    @State private var output = ""
    @State private var isLoading = true
    @State private var isGenerating = false
    @State private var llm: EdgeLLM_Demo?
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                        Text("Loading model...")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !errorMessage.isEmpty {
                    VStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        Text("Error")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                } else {
                    // Chat interface
                    ScrollView {
                        Text(output.isEmpty ? "Response will appear here..." : output)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                    }
                    
                    HStack {
                        TextField("Type your message", text: $input)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(isGenerating)
                        
                        Button(action: {
                            Task {
                                await chat()
                            }
                        }) {
                            if isGenerating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "paperplane.fill")
                            }
                        }
                        .disabled(input.isEmpty || isGenerating)
                        .padding(.horizontal, 8)
                    }
                }
            }
            .padding()
            .navigationTitle("EdgeLLM Demo")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await loadModel()
        }
    }
    
    func loadModel() async {
        do {
            print("Starting model load...")
            llm = try await EdgeLLM_Demo(modelId: "Llama-3.2-3B-Instruct-q4f16_1-MLC")
            isLoading = false
            print("Model loaded successfully!")
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            print("Failed to load model: \(error)")
        }
    }
    
    func chat() async {
        guard let llm = llm else { return }
        
        let userInput = input
        input = ""
        output = ""
        isGenerating = true
        
        do {
            for try await token in llm.stream(userInput) {
                output += token
            }
        } catch {
            output = "Error: \(error.localizedDescription)"
        }
        
        isGenerating = false
    }
}

#Preview {
    ContentView()
}