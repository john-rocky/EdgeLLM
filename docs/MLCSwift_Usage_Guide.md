# MLCSwift Usage Guide

## Overview

MLCSwift is a Swift package that provides an OpenAI-compatible API for running Large Language Models (LLMs) directly on iOS/macOS devices using Metal GPU acceleration. This guide covers how to integrate and use MLCSwift in your applications.

## Installation

### 1. Add Package Dependency

Add MLCSwift to your Xcode project:
- File → Add Package Dependencies
- Add local package: `ios/MLCSwift`

### 2. Configure Build Settings

In your app target's build settings:

**Library Search Paths:**
```
$(PROJECT_DIR)/dist/lib
```

**Other Linker Flags:**
```
-Wl,-all_load
-lmodel_iphone
-lmlc_llm
-ltvm_runtime
-ltokenizers_cpp
-lsentencepiece
-ltokenizers_c
```

### 3. Bundle Model Resources

Copy the `dist/bundle` directory to your app's resources. This contains model configurations and metadata.

## Basic Usage

### Simple Chat Example

```swift
import MLCSwift

class ChatViewModel: ObservableObject {
    private let engine = MLCEngine()
    @Published var response = ""
    
    func loadModel() async {
        let modelPath = Bundle.main.path(forResource: "model", ofType: nil)!
        let modelLib = "model_iphone"
        
        await engine.reload(modelPath: modelPath, modelLib: modelLib)
    }
    
    func chat(prompt: String) async {
        response = ""
        
        for await res in await engine.chat.completions.create(
            messages: [
                ChatCompletionMessage(role: .user, content: prompt)
            ],
            stream_options: StreamOptions(include_usage: true)
        ) {
            if let content = res.choices.first?.delta.content {
                response += content.asText()
            }
        }
    }
}
```

### Complete Implementation Example

```swift
import SwiftUI
import MLCSwift

// MARK: - Chat State Management
@MainActor
final class ChatState: ObservableObject {
    private let engine = MLCEngine()
    
    @Published var messages: [ChatMessage] = []
    @Published var isGenerating = false
    @Published var streamingText = ""
    @Published var statistics = ""
    
    private var conversationHistory: [ChatCompletionMessage] = []
    
    func loadModel(modelPath: String, modelLib: String) async {
        await engine.reload(modelPath: modelPath, modelLib: modelLib)
    }
    
    func sendMessage(_ text: String) {
        // Add user message
        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)
        conversationHistory.append(
            ChatCompletionMessage(role: .user, content: text)
        )
        
        // Start generation
        Task {
            await generateResponse()
        }
    }
    
    private func generateResponse() async {
        isGenerating = true
        streamingText = ""
        
        // Add placeholder for assistant message
        messages.append(ChatMessage(role: .assistant, content: ""))
        
        do {
            for await res in await engine.chat.completions.create(
                messages: conversationHistory,
                stream_options: StreamOptions(include_usage: true)
            ) {
                // Handle streaming content
                for choice in res.choices {
                    if let content = choice.delta.content {
                        streamingText += content.asText()
                        
                        // Update UI
                        if let lastIndex = messages.indices.last {
                            messages[lastIndex].content = streamingText
                        }
                    }
                }
                
                // Handle usage statistics
                if let usage = res.usage {
                    statistics = usage.extra?.asTextLabel() ?? ""
                }
            }
            
            // Add to conversation history
            conversationHistory.append(
                ChatCompletionMessage(role: .assistant, content: streamingText)
            )
            
        } catch {
            print("Generation error: \(error)")
        }
        
        isGenerating = false
    }
    
    func resetConversation() async {
        messages.removeAll()
        conversationHistory.removeAll()
        await engine.reset()
    }
}

// MARK: - Data Models
struct ChatMessage: Identifiable {
    let id = UUID()
    let role: ChatCompletionMessage.Role
    var content: String
}

// MARK: - SwiftUI View
struct ChatView: View {
    @StateObject private var chatState = ChatState()
    @State private var inputText = ""
    
    var body: some View {
        VStack {
            // Messages list
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(chatState.messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding()
            }
            
            // Statistics
            if !chatState.statistics.isEmpty {
                Text(chatState.statistics)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            // Input field
            HStack {
                TextField("Type a message...", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(chatState.isGenerating)
                
                Button("Send") {
                    if !inputText.isEmpty {
                        chatState.sendMessage(inputText)
                        inputText = ""
                    }
                }
                .disabled(chatState.isGenerating || inputText.isEmpty)
            }
            .padding()
        }
        .task {
            await loadModel()
        }
    }
    
    private func loadModel() async {
        // Configure your model path
        let modelPath = Bundle.main.path(
            forResource: "model", 
            ofType: nil, 
            inDirectory: "bundle"
        )!
        let modelLib = "model_iphone"
        
        await chatState.loadModel(
            modelPath: modelPath, 
            modelLib: modelLib
        )
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            Text(message.content)
                .padding()
                .background(
                    message.role == .user ? Color.blue : Color.gray.opacity(0.2)
                )
                .foregroundColor(
                    message.role == .user ? .white : .primary
                )
                .cornerRadius(12)
            
            if message.role == .assistant {
                Spacer()
            }
        }
    }
}
```

## Advanced Features

### Multi-modal Support (Text + Images)

```swift
// Create message with image
let imageData = UIImage(named: "example")!.pngData()!
let base64Image = imageData.base64EncodedString()

let message = ChatCompletionMessage(
    role: .user,
    content: [
        .text(ChatCompletionMessage.ContentPart.TextContent(
            text: "What's in this image?"
        )),
        .image_url(ChatCompletionMessage.ContentPart.ImageURLContent(
            image_url: ChatCompletionMessage.ContentPart.ImageURL(
                url: "data:image/png;base64,\(base64Image)"
            )
        ))
    ]
)
```

### Function Calling

```swift
// Define a function tool
let weatherTool = ChatCompletionTool(
    type: "function",
    function: ChatCompletionTool.Function(
        name: "get_weather",
        description: "Get the current weather",
        parameters: [
            "type": "object",
            "properties": [
                "location": [
                    "type": "string",
                    "description": "The city and state"
                ]
            ],
            "required": ["location"]
        ]
    )
)

// Create completion with tools
for await res in await engine.chat.completions.create(
    messages: messages,
    tools: [weatherTool],
    stream_options: StreamOptions(include_usage: true)
) {
    // Handle tool calls in response
    if let toolCalls = res.choices.first?.delta.tool_calls {
        for toolCall in toolCalls {
            if toolCall.function?.name == "get_weather" {
                // Process weather function call
                let arguments = toolCall.function?.arguments
                // ... handle function execution
            }
        }
    }
}
```

### Configuration Options

```swift
// Advanced generation parameters
for await res in await engine.chat.completions.create(
    messages: messages,
    model: "Llama-3-8B-Instruct",  // Optional model override
    frequency_penalty: 0.1,         // Repetition penalty
    presence_penalty: 0.1,          // Topic penalty  
    temperature: 0.7,               // Randomness (0-1)
    top_p: 0.95,                   // Nucleus sampling
    max_tokens: 500,               // Maximum response length
    stream_options: StreamOptions(include_usage: true)
) {
    // Process response
}
```

## Model Management

### Model Preparation

1. **Convert Hugging Face Model:**
   ```bash
   mlc_llm convert_weight \
     --model HuggingFaceModel/Name \
     --target metal \
     --quantization q4f16_1
   ```

2. **Package for iOS:**
   ```bash
   mlc_llm package \
     --model-path converted_model \
     --output dist/bundle
   ```

3. **Generate Library:**
   ```bash
   cd ios && ./prepare_libs.sh
   ```

### Dynamic Model Loading

```swift
// Load model from app documents
let documentsPath = FileManager.default.urls(
    for: .documentDirectory, 
    in: .userDomainMask
).first!

let modelPath = documentsPath
    .appendingPathComponent("models/llama3")
    .path

await engine.reload(
    modelPath: modelPath,
    modelLib: "model_iphone"
)
```

## Performance Optimization

### Memory Management

```swift
// Check available memory before loading
let availableMemory = os_proc_available_memory()
let requiredMemory: UInt64 = 2 * 1024 * 1024 * 1024 // 2GB

if availableMemory < requiredMemory {
    // Handle low memory condition
    print("Insufficient memory for model")
}

// Unload model when not needed
await engine.unload()
```

### Generation Speed Monitoring

```swift
// Monitor tokens per second
for await res in await engine.chat.completions.create(
    messages: messages,
    stream_options: StreamOptions(include_usage: true)
) {
    if let usage = res.usage,
       let extra = usage.extra {
        // Extract performance metrics
        let tokensPerSecond = extra.asTokensPerSecond()
        print("Generation speed: \(tokensPerSecond) tokens/sec")
    }
}
```

## Error Handling

```swift
do {
    // Load model with error handling
    await engine.reload(modelPath: modelPath, modelLib: modelLib)
    
    // Generate with timeout
    let task = Task {
        for await res in await engine.chat.completions.create(
            messages: messages,
            stream_options: StreamOptions(include_usage: true)
        ) {
            // Process response
        }
    }
    
    // Cancel if taking too long
    Task {
        try await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
        task.cancel()
    }
    
} catch {
    switch error {
    case MLCEngineError.modelNotFound:
        print("Model file not found")
    case MLCEngineError.insufficientMemory:
        print("Not enough memory to load model")
    default:
        print("Unknown error: \(error)")
    }
}
```

## Best Practices

1. **Model Selection**: Choose quantized models (q4f16_1) for optimal performance/quality balance
2. **Conversation Context**: Limit conversation history to prevent memory issues
3. **UI Updates**: Always update UI on main thread when streaming
4. **Background Handling**: Pause generation when app goes to background
5. **Error Recovery**: Implement retry logic for model loading failures

## Troubleshooting

### Common Issues

1. **"Library not loaded" error**: Ensure all linker flags are set correctly
2. **Model loading fails**: Verify model files are included in app bundle
3. **Slow generation**: Check device thermal state and available memory
4. **Crash on launch**: Confirm minimum iOS version (14.0+) requirement

### Debug Logging

```swift
// Enable verbose logging
MLCEngine.setLogLevel(.debug)

// Monitor engine state
print("Engine loaded: \(engine.isLoaded)")
print("Model path: \(engine.currentModelPath ?? "none")")
```

## Future: EdgeLLM Simplified API

The upcoming EdgeLLM package will simplify usage to:

```swift
import EdgeLLM

// One-line initialization
let llm = try EdgeLLM(modelId: "llama3-8b-instruct")

// Simple chat
let response = try await llm.chat("Hello, how are you?")

// Streaming
for try await token in llm.stream("Tell me a story") {
    print(token, terminator: "")
}
```

This will handle model downloading, caching, and configuration automatically.