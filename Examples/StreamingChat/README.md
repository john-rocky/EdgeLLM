# EdgeLLM Streaming Chat Demo

A sophisticated chat application demonstrating EdgeLLM's streaming capabilities with real-time performance metrics.

## Features

- 🌊 **Real-time Streaming** - See responses generated token by token
- 📊 **Performance Metrics** - Live tokens/second, latency measurements
- 🎯 **Model Selection** - Switch between Qwen3, Gemma, and Phi-3.5
- 💬 **Chat Interface** - Beautiful message bubbles with timestamps
- ⚡ **Optimized Performance** - Showcases EdgeLLM's on-device speed

## Performance Indicators

The app displays key performance metrics:

1. **Tokens/sec** - Real-time generation speed
2. **Total tokens** - Number of tokens generated
3. **First token** - Time to first token (latency)
4. **Model load** - Initial model loading time

## How to Run

1. Open `StreamingChat.xcodeproj` in Xcode
2. Add EdgeLLM package dependency:
   - File → Add Package Dependencies
   - Enter: `https://github.com/john-rocky/EdgeLLM`
   - Select version 1.0.0 or later
3. Build and run on your iOS device (iOS 14.0+)

## Models

- **Qwen3 0.6B** - Fastest, ~20-30 tokens/sec
- **Gemma 2B** - Balanced, ~15-20 tokens/sec  
- **Phi-3.5 Mini** - Most capable, ~10-15 tokens/sec

## Demo Usage

1. Select a model from the segmented control
2. Type your message and tap send
3. Watch the response stream in real-time
4. Monitor performance metrics at the top
5. Switch models to compare performance

## Technical Details

This demo showcases:
- EdgeLLM's async/await streaming API
- Real-time UI updates with SwiftUI
- Performance measurement techniques
- Model switching capabilities

Perfect for demonstrating EdgeLLM's capabilities to:
- Developers evaluating on-device LLMs
- Users comparing model performance
- Teams building AI-powered iOS apps