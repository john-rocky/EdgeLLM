# SimpleChat - EdgeLLM Example App

A minimal chat application demonstrating EdgeLLM usage in iOS.

> **Note**: This example uses a mock implementation of EdgeLLM for easy testing. To use the real EdgeLLM package, uncomment the import statement in ContentView.swift and add the EdgeLLM package dependency.

## Features

- 💬 Simple chat interface
- 🔄 Model selection (Gemma 2B, Phi-2, Llama 3 8B)
- 📱 SwiftUI-based UI
- 🚀 One-line LLM integration

## Setup

1. Open `SimpleChat.xcodeproj` in Xcode
2. Build and run on your device or simulator

### To use real EdgeLLM:

1. Remove `MockEdgeLLM.swift` from the project
2. Uncomment `import EdgeLLM` in ContentView.swift and StreamingContentView.swift
3. Add EdgeLLM package dependency:
   - File → Add Package Dependencies
   - Enter: `https://github.com/john-rocky/EdgeLLM`
   - Select version and add package

## Code Structure

- `SimpleChatApp.swift` - App entry point
- `ContentView.swift` - Main chat interface

## Key Code

The core LLM integration is just one line:

```swift
let response = try await EdgeLLM.chat(prompt, model: selectedModel)
```

## Requirements

- iOS 14.0+
- Xcode 15.0+
- iPhone 12 or later (recommended)

## Notes

- Models are downloaded on first use (1-4GB)
- WiFi recommended for initial download
- Each model requires 2-4GB of device storage

## Screenshots

<img src="screenshot.png" width="250">