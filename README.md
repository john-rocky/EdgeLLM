# EdgeLLM

[![SwiftPM](https://img.shields.io/badge/SwiftPM-Add%20Package-green)](https://swift.org/package-manager/)
[![License](https://img.shields.io/badge/License-Apache--2.0-blue)](LICENSE)
[![Release](https://img.shields.io/github/v/tag/john-rocky/EdgeLLM)](https://github.com/john-rocky/EdgeLLM/releases)
[![Platform](https://img.shields.io/badge/platform-iOS%2014%2B%20%7C%20macOS%2014%2B%20%7C%20visionOS%201%2B-lightgrey)](https://developer.apple.com)

<p align="center">
  <img src="https://github.com/user-attachments/assets/c7a7a5bf-b226-405e-86ce-ea3dc19e0d15" alt="EdgeLLM" width="350"/>
</p>

<h1 align="center">EdgeLLM</h1>

<p align="center">Run Large Language Models on iOS devices with <strong>just one line of code</strong></p>

```swift
let response = try await EdgeLLM.chat("Hello, world!")
```

> **Note**: EdgeLLM is now fully functional! Supports multiple models including Qwen, Gemma, and Phi-3.

## Quick Start

```swift
import EdgeLLM

// 1. Basic chat (uses default model)
let response = try await EdgeLLM.chat("Hello!")
print(response)

// 2. Choose a specific model
let response = try await EdgeLLM.chat("Hello!", model: .gemma2b)

// 3. Stream responses in real-time
for try await token in EdgeLLM.stream("Tell me a joke") {
    print(token, terminator: "")
}

// 4. System prompt
let response = try await EdgeLLM.chat(
    "Translate 'hello' to French",
    systemPrompt: "You are a professional translator."
)
```

<p align="center"><img src="https://private-user-images.githubusercontent.com/23278992/465536477-97910a07-5361-42c3-9b12-43e72b8b8ef0.gif?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3NTIyODg1ODUsIm5iZiI6MTc1MjI4ODI4NSwicGF0aCI6Ii8yMzI3ODk5Mi80NjU1MzY0NzctOTc5MTBhMDctNTM2MS00MmMzLTliMTItNDNlNzJiOGI4ZWYwLmdpZj9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNTA3MTIlMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjUwNzEyVDAyNDQ0NVomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPWM3YTYyMTEwMDI2ZWM2YzBhN2U3NTMyMzE4NDliMTVkZTdmNDhlYzk1M2MzODA3NjE5MDczNmIzMDYwZmU2NmEmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0In0.zijTI4a0j75K6aHZOZkQhKUGcm1vwI94b3SYFm4Ua6I" width="350" alt="demo">><br><em><sub><i>Fictional penguin article summarised offline.</em></p>

## Features

- **Dead Simple** - Chat with LLMs in one line
- **iOS Optimized** - Metal GPU acceleration for blazing speed
- **Privacy First** - Everything runs on-device
- **Easy Install** - Swift Package Manager ready
- **Streaming Support** - Real-time token-by-token responses
- **System Prompts** - Set context and personality
- **Multi-Turn Conversations** - Full conversation history support
- **SwiftUI Ready** - Observable wrapper for SwiftUI apps
- **Model Management** - Download, cache, and manage models
- **Custom Models** - Bring your own MLC-compiled models

## Installation

### Swift Package Manager

In Xcode:

1. File -> Add Package Dependencies
2. Enter URL: `https://github.com/john-rocky/EdgeLLM`
3. Select version and click "Add Package"

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/john-rocky/EdgeLLM", from: "1.0.0")
]
```

## Supported Models

| Model | Enum | Size | Best For |
|-------|------|------|----------|
| **Qwen 0.6B** | `.qwen06b` | ~1.2 GB | Fastest responses, low-end devices |
| **Gemma 2B** | `.gemma2b` | ~2.5 GB | Balanced speed & quality |
| **Phi-3.5 Mini** | `.phi3_mini` | ~3.8 GB | Best quality, reasoning tasks |

Models are automatically downloaded on first use (WiFi recommended).

## Usage

### Simplest Example

```swift
import EdgeLLM

// Chat in one line!
let response = try await EdgeLLM.chat("What's the weather like?")
print(response)
```

### Streaming Responses

```swift
// Receive response token by token
for try await token in EdgeLLM.stream("Tell me a story") {
    print(token, terminator: "")
}
```

### System Prompts

```swift
// Set model behavior with a system prompt
let response = try await EdgeLLM.chat(
    "Explain recursion",
    systemPrompt: "You are a patient teacher. Use simple analogies."
)

// Or via Options for reuse
let options = EdgeLLM.Options(systemPrompt: "You are a pirate. Respond in pirate speak.")
let llm = try await EdgeLLM(model: .gemma2b, options: options)
let response = try await llm.chat("What is the meaning of life?")
```

### Multi-Turn Conversations

```swift
let llm = try await EdgeLLM(model: .gemma2b)
let conversation = Conversation(systemPrompt: "You are a helpful assistant.")

// Full conversation history is maintained
let r1 = try await llm.chat("My name is Alice", in: conversation)
let r2 = try await llm.chat("What's my name?", in: conversation)
// r2 correctly answers "Alice"

// Stream within a conversation
for try await token in llm.stream("Tell me more", in: conversation) {
    print(token, terminator: "")
}

// View history
print(conversation.messages.count)

// Reset conversation (keeps system prompt)
conversation.clear()
```

### Generation Options

```swift
let options = EdgeLLM.Options(
    temperature: 0.3,       // More deterministic (default: 0.7)
    maxTokens: 500,         // Limit response length (default: 2048)
    topP: 0.9,              // Nucleus sampling (default: 0.95)
    systemPrompt: "Be concise.",
    frequencyPenalty: 0.5,  // Reduce repetition
    presencePenalty: 0.3,   // Encourage topic diversity
    stopSequences: ["\n\n"] // Stop at double newline
)

let response = try await EdgeLLM.chat("Summarize quantum computing", options: options)
```

### SwiftUI Integration

```swift
import SwiftUI
import EdgeLLM

struct ChatView: View {
    @StateObject private var chat = EdgeLLMChat(
        model: .gemma2b,
        systemPrompt: "You are a helpful assistant."
    )
    @State private var input = ""

    var body: some View {
        VStack {
            // Download progress
            if chat.isDownloading {
                ProgressView("Downloading model...")
            }

            // Chat messages
            ScrollView {
                ForEach(chat.messages) { msg in
                    HStack {
                        if msg.role == .user { Spacer() }
                        Text(msg.content)
                            .padding(8)
                            .background(msg.role == .user ? Color.blue : Color.gray.opacity(0.2))
                            .cornerRadius(12)
                        if msg.role == .assistant { Spacer() }
                    }
                }
            }

            // Performance metrics
            if chat.isGenerating {
                Text("\(String(format: "%.1f", chat.tokensPerSecond)) tok/s")
                    .font(.caption)
            }

            // Input
            HStack {
                TextField("Message", text: $input)
                Button("Send") {
                    let text = input
                    input = ""
                    Task { await chat.send(text) }
                }
                .disabled(chat.isGenerating || !chat.isModelLoaded)
            }
        }
        .task { await chat.load() }
    }
}
```

### Model Management

```swift
// Check if a model is already downloaded
if EdgeLLM.isDownloaded(.gemma2b) {
    print("Ready to use!")
}

// Pre-download a model
try await EdgeLLM.download(.phi3_mini) { progress in
    print(progress.statusDescription) // "Downloading params_shard_2.bin (3/8)"
}

// List downloaded models
let models = EdgeLLM.downloadedModels()
for model in models {
    print("\(model.model.displayName): \(model.sizeBytes / 1_000_000) MB")
}

// Check available space
let freeSpace = EdgeLLM.availableDiskSpace()
let cacheSize = EdgeLLM.totalCacheSize()

// Delete a model
try EdgeLLM.deleteModel(.phi3_mini)
```

### Custom Models

Bring your own MLC-compiled models when using a custom MLCRuntime binary:

```swift
let config = EdgeLLM.ModelConfig(
    name: "My Custom Model",
    modelLib: "custom_model_lib_hash",
    huggingFaceURL: "https://huggingface.co/your-org/your-model-MLC",
    approximateSize: 2_000_000_000
)

let llm = try await EdgeLLM(config: config)
let response = try await llm.chat("Hello!")
```

## Example Apps

### Simple Chat
Basic chat interface in `Examples/SimpleChat`:
```bash
cd Examples/SimpleChat
open SimpleChat.xcodeproj
```

### Streaming Chat with Performance Metrics
Advanced demo with real-time streaming and performance monitoring:
```bash
cd Examples/StreamingChat
open StreamingChat.xcodeproj
```

Features:
- Real-time token streaming
- Live performance metrics (tokens/sec, latency)
- Model comparison (Qwen3, Gemma, Phi-3.5)

## Requirements

- iOS 14.0+ / macOS 14.0+ / visionOS 1.0+
- Xcode 15.0+
- 4GB+ free storage for models
- Recommended: iPhone 12 or newer (Neural Engine support)

## Performance

On iPhone 15 Pro:
- Initial load: 2-3 seconds
- Token generation: 10-30 tokens/sec (model dependent)
- Memory usage: 1-4GB depending on model

## Troubleshooting

### Model Not Found

Models are downloaded automatically on first run (WiFi recommended).

### Out of Memory

Try a smaller model like `.qwen06b`:

```swift
let response = try await EdgeLLM.chat("Hello", model: .qwen06b)
```

### Manage Disk Space

```swift
// Check and clean up
let cacheSize = EdgeLLM.totalCacheSize()
try EdgeLLM.deleteAllModels()
```

## License

Apache 2.0 License

## Contributing

Pull requests are welcome!

### Development Setup

1. Clone the repository
2. Set up git hooks to prevent large files:
   ```bash
   git config core.hooksPath .githooks
   ```

### Important: Large Files Policy

- **Never commit binary files** (`.xcframework`, `.zip`, `.mlmodel`, etc.)
- **Maximum file size**: 10MB
- Large files should be uploaded to GitHub Releases
- The pre-commit hook will block commits with large files

## Links

- [Example App](https://github.com/john-rocky/EdgeLLM/tree/main/Examples/SimpleChat)
- [Report Issues](https://github.com/john-rocky/EdgeLLM/issues)

## Credits

EdgeLLM is built on top of the [MLC-LLM](https://github.com/mlc-ai/mlc-llm) project.
