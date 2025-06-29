import SwiftUI
import EdgeLLM

/// EdgeLLMの最もシンプルな使用例
struct SimpleChatView: View {
    @State private var userInput = ""
    @State private var response = ""
    @State private var isLoading = false
    @State private var streamedResponse = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // タイトル
            Text("EdgeLLM Simple Chat")
                .font(.largeTitle)
                .padding()
            
            // レスポンスエリア
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if !response.isEmpty {
                        Text("完全なレスポンス:")
                            .font(.headline)
                        Text(response)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    if !streamedResponse.isEmpty {
                        Text("ストリーミングレスポンス:")
                            .font(.headline)
                        Text(streamedResponse)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 300)
            
            // 入力エリア
            HStack {
                TextField("メッセージを入力...", text: $userInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(isLoading)
                
                Button(action: sendMessage) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                }
                .disabled(userInput.isEmpty || isLoading)
            }
            .padding()
            
            // 使用例
            VStack(alignment: .leading, spacing: 10) {
                Text("使用例:")
                    .font(.headline)
                
                ForEach(examples, id: \.self) { example in
                    Button(example) {
                        userInput = example
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            
            Spacer()
        }
        .padding()
    }
    
    private let examples = [
        "こんにちは！",
        "今日の天気はどうですか？",
        "簡単なレシピを教えて",
        "プログラミングについて質問があります"
    ]
    
    private func sendMessage() {
        guard !userInput.isEmpty else { return }
        
        let message = userInput
        userInput = ""
        isLoading = true
        response = ""
        streamedResponse = ""
        
        Task {
            do {
                // 方法1: 最もシンプル - 1行でチャット
                response = try await EdgeLLM.chat(message)
                
                // 方法2: ストリーミングレスポンス
                streamedResponse = ""
                for try await token in try await EdgeLLM.stream(message) {
                    streamedResponse += token
                }
                
            } catch {
                response = "エラー: \(error.localizedDescription)"
            }
            
            isLoading = false
        }
    }
}

// MARK: - 上級者向けの使用例

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    private var llm: EdgeLLM?
    
    struct ChatMessage: Identifiable {
        let id = UUID()
        let role: String
        let content: String
    }
    
    func initialize() async {
        do {
            // カスタムオプションでLLMを初期化
            let options = EdgeLLM.Options(
                temperature: 0.8,
                maxTokens: 1024,
                topP: 0.9
            )
            
            llm = try await EdgeLLM(model: .llama3_2, options: options)
        } catch {
            print("初期化エラー: \(error)")
        }
    }
    
    func sendMessage(_ content: String) async {
        messages.append(ChatMessage(role: "user", content: content))
        
        guard let llm = llm else { return }
        
        var assistantMessage = ChatMessage(role: "assistant", content: "")
        messages.append(assistantMessage)
        
        do {
            // ストリーミングでレスポンスを更新
            for try await token in llm.stream(content) {
                if let index = messages.lastIndex(where: { $0.id == assistantMessage.id }) {
                    messages[index] = ChatMessage(
                        role: "assistant",
                        content: messages[index].content + token
                    )
                }
            }
        } catch {
            print("エラー: \(error)")
        }
    }
    
    func reset() async {
        await llm?.reset()
        messages.removeAll()
    }
}

// MARK: - App Entry Point

@main
struct SimpleChatApp: App {
    var body: some Scene {
        WindowGroup {
            SimpleChatView()
        }
    }
}