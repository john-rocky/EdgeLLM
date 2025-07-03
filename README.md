# EdgeLLM

[![SwiftPM](https://img.shields.io/badge/SwiftPM-Add%20Package-green)](https://swift.org/package-manager/)
[![License](https://img.shields.io/badge/License-Apache--2.0-blue)](LICENSE)
[![Release](https://img.shields.io/github/v/tag/john-rocky/EdgeLLM)](https://github.com/john-rocky/EdgeLLM/releases)

<p align="center">
  <img src="https://github.com/user-attachments/assets/c7a7a5bf-b226-405e-86ce-ea3dc19e0d15" alt="EdgeLLM" width="800"/>
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

// 4. Advanced usage with custom instance
let llm = try await EdgeLLM(model: .qwen06b)
let response = try await llm.chat("Explain quantum computing")
```

## Features

- 🚀 **Dead Simple** - Chat with LLMs in one line
- 📱 **iOS Optimized** - Metal GPU acceleration for blazing speed
- 🔒 **Privacy First** - Everything runs on-device
- 📦 **Easy Install** - Swift Package Manager ready
- 🌊 **Streaming Support** - Real-time responses

## Installation

### Swift Package Manager

In Xcode:

1. File → Add Package Dependencies
2. Enter URL: `https://github.com/john-rocky/EdgeLLM`
3. Select version and click "Add Package"

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/john-rocky/EdgeLLM", from: "1.0.0")
]
```

## Supported Models

- **Qwen 0.6B** (`.qwen06b`) - Smallest, fastest model (~1.2GB)
- **Gemma 2B** (`.gemma2b`) - Balanced performance (~2.5GB)  
- **Phi-3.5 Mini** (`.phi3_mini`) - Most capable (~3.8GB)

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

### Customization

```swift
// Specify model and options
let response = try await EdgeLLM.chat(
    "Technical question",
    model: .gemma2b,  // Use different model
    options: EdgeLLM.Options(
        temperature: 0.3,  // More deterministic
        maxTokens: 500
    )
)
```

### Advanced Usage

```swift
// Keep LLM instance for conversations
let llm = try await EdgeLLM(model: .gemma2b)

// Multiple exchanges
let response1 = try await llm.chat("My name is John")
let response2 = try await llm.chat("What's my name?")

// Reset conversation
await llm.reset()
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

- iOS 14.0+
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

## License

Apache2.0 License

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

- [Documentation](https://github.com/john-rocky/EdgeLLM/tree/main/docs)
- [Example App](https://github.com/john-rocky/EdgeLLM/tree/main/Examples/SimpleChat)
- [Report Issues](https://github.com/john-rocky/EdgeLLM/issues)

## Credits

EdgeLLM is built on top of the [MLC-LLM](https://github.com/mlc-ai/mlc-llm) project.
