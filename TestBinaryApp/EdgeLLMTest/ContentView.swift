import SwiftUI
import EdgeLLM

struct ContentView: View {
    @State private var prompt = ""
    @State private var response = ""
    @State private var isLoading = false
    @State private var selectedModel = EdgeLLM.Model.qwen05b
    @State private var streamedResponse = ""
    @State private var useStreaming = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Model selector
                VStack(alignment: .leading) {
                    Text("Select Model:")
                        .font(.headline)
                    Picker("Model", selection: $selectedModel) {
                        ForEach(EdgeLLM.Model.allCases, id: \.self) { model in
                            Text(model.displayName).tag(model)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.horizontal)
                
                // Input
                VStack(alignment: .leading) {
                    Text("Your prompt:")
                        .font(.headline)
                    TextField("Ask me anything...", text: $prompt)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(isLoading)
                }
                .padding(.horizontal)
                
                // Streaming toggle
                Toggle("Use Streaming", isOn: $useStreaming)
                    .padding(.horizontal)
                
                // Send button
                Button(action: sendMessage) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Send")
                            .font(.headline)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(prompt.isEmpty || isLoading)
                
                // Response
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Response:")
                            .font(.headline)
                        
                        Text(useStreaming ? streamedResponse : response)
                            .font(.body)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .textSelection(.enabled)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("EdgeLLM Test v0.2.0")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    func sendMessage() {
        isLoading = true
        response = ""
        streamedResponse = ""
        
        Task {
            do {
                if useStreaming {
                    // Streaming response
                    for try await token in await EdgeLLM.stream(prompt, model: selectedModel) {
                        await MainActor.run {
                            streamedResponse += token
                        }
                    }
                    await MainActor.run {
                        isLoading = false
                    }
                } else {
                    // Regular response
                    let result = try await EdgeLLM.chat(prompt, model: selectedModel)
                    await MainActor.run {
                        response = result
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    response = "Error: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}