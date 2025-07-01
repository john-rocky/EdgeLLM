# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

EdgeLLM is a Swift SDK that enables iOS developers to run Large Language Models on-device with just one line of code. It wraps MLC-LLM's MLCSwift to provide a simplified API for iOS apps.

**Key Features:**
- One-line usage: `let response = try await EdgeLLM.chat("Hello!")`
- On-device execution with Metal GPU acceleration
- Automatic model downloading and caching
- Streaming support for real-time responses
- Multiple model support (Qwen 0.5B, Gemma 2B, Phi-3.5)

## Build Commands

### Development Setup
```bash
# Clone EdgeLLM and MLC-LLM (required for development)
git clone https://github.com/john-rocky/EdgeLLM
git clone https://github.com/mlc-ai/mlc-llm

# Setup dependencies
cd EdgeLLM
./scripts/setup.sh

# Build
swift build

# Run tests
swift test
```

### Build XCFramework for Distribution
```bash
# Build the XCFramework
./scripts/build_xcframework.sh

# Create release package
./scripts/create_release.sh
```

### Testing with Example Apps
```bash
# Run SimpleChat example
cd Examples/SimpleChat
open SimpleChat.xcodeproj
# Build and run in Xcode

# Test with local model
swift run test_local_model
```

## High-Level Architecture

### Core Components

1. **EdgeLLM.swift** - Main API wrapper around MLCSwift
   - Provides simplified chat/stream methods
   - Handles model initialization and lifecycle
   - Manages streaming responses via AsyncStream

2. **ModelDownloader.swift** - Automatic model management
   - Downloads models from Hugging Face on first use
   - Caches models in app's Documents directory
   - Handles progress tracking and error recovery

3. **RuntimeLoader.swift** - Dynamic library loading
   - Loads MLC runtime libraries
   - Manages XCFramework dependencies
   - Handles platform-specific configurations

4. **LocalModelConfig.swift** - Model configuration
   - Defines available models and their parameters
   - Maps model IDs to Hugging Face URLs
   - Configures model-specific settings

### Package Structure
```
EdgeLLM/
├── Sources/EdgeLLM/        # Main implementation
├── Examples/               # Example apps and test code
│   ├── SimpleChat/        # SwiftUI example app
│   └── TestEdgeLLM/       # Command-line test tool
├── scripts/               # Build and setup automation
├── docs/                  # Architecture documentation
└── Package.swift          # SPM configuration
```

### Distribution Strategy

1. **Development Mode** (current):
   - Direct dependency on local MLC-LLM via path reference
   - Requires manual setup of MLC libraries

2. **Binary Distribution** (planned):
   - XCFramework with all dependencies bundled
   - Hosted on GitHub Releases (up to 2GB)
   - Automatic download via Swift Package Manager

### Key Dependencies
- **MLC-LLM**: Core LLM runtime (local path: `../ios/MLCSwift`)
- **Required Libraries**: libmlc_llm.a, libtvm_runtime.a, libsentencepiece.a, libtokenizers_cpp.a
- **Platform Requirements**: iOS 14.0+, macOS 13.0+, visionOS 1.0+

## Development Notes

### Model Management
- Model files (.mlmodel, .tflite) should NEVER be committed to git
- Models are downloaded to user's Documents directory on first use
- Model hosting uses Hugging Face with automatic download

### Library Setup
- Pre-built libraries are downloaded by `setup.sh` script
- Library files (.a) are gitignored
- Placeholder URLs in scripts need to be replaced with actual hosting URLs

### Testing Approach
- Mock implementation available for testing without real models
- Example apps demonstrate different integration patterns
- Local model testing supported with actual MLC models

### Current Status
- Version: 0.1.1 with complete C++ runtime
- Branch `complete-package` ready for installation
- XCFramework distribution planned for v0.2.0
- Model hosting infrastructure being set up

### Important Patterns
- Use JSON FFI pattern for C++ interop (see MLCSwift)
- Background thread with high QoS for GPU operations
- Async/await and AsyncStream for modern Swift concurrency
- Actor-based design for thread safety