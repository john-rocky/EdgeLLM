# EdgeLLM

Run Large Language Models on iOS with **just one line of code**

```swift
let response = try await EdgeLLM.chat("Hello, world!")
```

> **Note**: EdgeLLM v0.1.0 is now available! This is an early release - feedback and contributions are welcome.

## Quick Start

```swift
import EdgeLLM

// 1. Basic chat
let response = try await EdgeLLM.chat("Hello!")

// 2. Choose a model
let response = try await EdgeLLM.chat("Hello!", model: .llama3_8b)

// 3. Stream tokens
for try await token in EdgeLLM.stream("Tell me a joke") {
    print(token, terminator: "")
}
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
    .package(url: "https://github.com/john-rocky/EdgeLLM", from: "0.1.0")
]
```

### Note on First Use

Models are downloaded automatically when first used (1-2GB per model, WiFi recommended).

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
    model: .llama3_8b,  // Use different model
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

## Supported Models

| Model | Size | Description | Download Size |
|-------|------|-------------|---------------|
| `.gemma2b` | 2B | Google Gemma - Lightweight & fast (Default) | ~1.3GB |
| `.phi2` | 2.7B | Microsoft Phi-2 - Balanced performance | ~1.8GB |
| `.llama3_8b` | 8B | Meta Llama 3 - Highest quality (needs more memory) | ~4.5GB |

Models are automatically downloaded from Hugging Face on first use.

## Example App

A sample SwiftUI app is available in the `Examples/SimpleChat` directory.

## Requirements

- iOS 14.0+
- iPhone 12 or later (with Neural Engine)
- Xcode 15.0+

## Performance

On iPhone 15 Pro:
- Initial load: 2-3 seconds
- Token generation: 10-15 tokens/sec (Gemma 2B)
- Memory usage: 2-4GB depending on model

## Troubleshooting

### Model Not Found

Models are downloaded automatically on first run (WiFi recommended).

### Out of Memory

Try a smaller model like `.gemma2b`:

```swift
let response = try await EdgeLLM.chat("Hello", model: .gemma2b)
```

## License

MIT License

## Contributing

Pull requests are welcome!

## Links

- [Documentation](https://github.com/john-rocky/EdgeLLM/tree/main/docs)
- [Example App](https://github.com/john-rocky/EdgeLLM/tree/main/Examples/SimpleChat)
- [Report Issues](https://github.com/john-rocky/EdgeLLM/issues)

## Credits

EdgeLLM is built on top of the [MLC-LLM](https://github.com/mlc-ai/mlc-llm) project.
