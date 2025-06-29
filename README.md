# EdgeLLM

Run Large Language Models on iOS with **just one line of code**

```swift
let response = try await EdgeLLM.chat("Hello, world!")
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
2. Enter URL: `https://github.com/yourusername/EdgeLLM`
3. Select version and click "Add Package"

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/EdgeLLM", from: "0.1.0")
]
```

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
for try await token in try await EdgeLLM.stream("Tell me a story") {
    print(token, terminator: "")
}
```

### Customization

```swift
// Specify model and options
let response = try await EdgeLLM.chat(
    "Technical question",
    model: .phi3_5_mini,  // Use different model
    options: EdgeLLM.Options(
        temperature: 0.3,  // More deterministic
        maxTokens: 500
    )
)
```

### Advanced Usage

```swift
// Keep LLM instance for conversations
let llm = try await EdgeLLM(model: .llama3_2)

// Multiple exchanges
let response1 = try await llm.chat("My name is John")
let response2 = try await llm.chat("What's my name?")

// Reset conversation
await llm.reset()
```

## Supported Models

| Model | Size | Description |
|-------|------|-------------|
| `.llama3_2` | 3B | Meta Llama 3.2 - Balanced performance |
| `.gemma2_2b` | 2B | Google Gemma 2 - Lightweight & fast |
| `.phi3_5_mini` | 3.8B | Microsoft Phi-3.5 - Great for technical tasks |

## Sample App

Check out the sample app in `Examples/SimpleChat`:

```bash
cd Examples/SimpleChat
open SimpleChat.xcodeproj
```

## Requirements

- iOS 14.0+
- iPhone 12 or later (with Neural Engine)
- Xcode 15.0+

## Performance

On iPhone 15 Pro:
- Initial load: 2-3 seconds
- Token generation: 15-20 tokens/sec
- Memory usage: 2-3GB

## Troubleshooting

### Model Not Found

Models are downloaded automatically on first run (WiFi recommended).

### Out of Memory

Try a smaller model like `.gemma2_2b`:

```swift
let response = try await EdgeLLM.chat("Hello", model: .gemma2_2b)
```

## License

MIT License

## Contributing

Pull requests are welcome!

## Credits

EdgeLLM is built on top of the [MLC-LLM](https://github.com/mlc-ai/mlc-llm) project.
