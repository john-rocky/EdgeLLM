# EdgeLLM Swift Package Implementation Strategy

## Overview

This document outlines the implementation strategy for creating EdgeLLM, a simplified Swift Package that makes it easy to use LLMs in iOS/macOS applications. It builds upon the existing MLCSwift implementation while providing a more streamlined API and automated build process.

## Phase 1: Foundation Setup

### 1.1 Extract Core Components from MLCSwift

**Key files to adapt:**
- `ios/MLCSwift/Sources/MLCEngine/LLMEngine.swift` → Simplify to EdgeLLM.swift
- `ios/MLCSwift/Sources/MLCEngine/LLMEngine.mm` → Create EdgeLLM bridge
- `ios/MLCSwift/Sources/MLCEngine/OpenAIProtocol.swift` → Keep for compatibility

**Simplifications:**
- Remove complex OpenAI protocol features (function calling, logprobs)
- Focus on basic chat completion
- Streamline initialization to single model ID parameter

### 1.2 Create XCFramework Build Process

**Build script workflow:**
```bash
# 1. Build MLC runtime for iOS/macOS
cd cpp && mkdir build_ios && cd build_ios
cmake .. -G Xcode \
  -DCMAKE_TOOLCHAIN_FILE=../cmake/ios.toolchain.cmake \
  -DDEPLOYMENT_TARGET=14.0 \
  -DCMAKE_BUILD_TYPE=Release \
  -DUSE_METAL=ON

# 2. Create xcframework
xcodebuild -create-xcframework \
  -framework build_ios/Release-iphoneos/MLCRuntime.framework \
  -framework build_ios/Release-iphonesimulator/MLCRuntime.framework \
  -output MLCRuntime.xcframework
```

### 1.3 Model Compilation Pipeline

**Automated via build plugin:**
1. Download Hugging Face model
2. Apply quantization (q4f16_1 default)
3. Compile Metal shaders
4. Package as tar.zst archive
5. Generate SHA-256 checksum

## Phase 2: Swift Package Structure

### 2.1 Package Layout
```
EdgeLLM/
├── Package.swift
├── Sources/
│   ├── EdgeLLM/
│   │   ├── EdgeLLM.swift          # Main API
│   │   ├── ModelManager.swift      # Download/cache logic
│   │   ├── Bridge/                # Obj-C++ bridge
│   │   │   ├── EdgeLLMBridge.h
│   │   │   └── EdgeLLMBridge.mm
│   │   └── Resources/
│   │       └── models.json        # Model manifest
│   └── EdgeLLMC/                  # C API wrapper
│       └── include/
│           └── module.modulemap
├── BinaryTargets/
│   └── MLCRuntime.xcframework
└── Plugins/
    └── MLCBuildPlugin/
        └── Plugin.swift
```

### 2.2 Simplified API Design

```swift
// Basic usage
let llm = try EdgeLLM(modelId: "qwen-1.5b_q4")
let response = try await llm.chat("Hello!")

// Streaming
for try await token in llm.stream("Tell me a story") {
    print(token, terminator: "")
}

// With options
let llm = try EdgeLLM(
    modelId: "llama3-8b_q4",
    options: .init(
        temperature: 0.7,
        maxTokens: 1000,
        cacheDirectory: customPath
    )
)
```

### 2.3 Model Management

**Download Strategy:**
1. Check local cache first (`~/Library/Application Support/EdgeLLM/<sha>/`)
2. Download from manifest URL if not cached
3. Verify SHA-256 checksum
4. Extract tar.zst to cache directory
5. Load model from extracted path

**Manifest Format:**
```json
{
  "models": {
    "qwen-1.5b_q4": {
      "version": "2025-06-28",
      "sha256": "d1e4...",
      "size": 1073741824,
      "urls": {
        "hf": "https://huggingface.co/edgeai/qwen-1.5b_q4/resolve/main/model.tar.zst",
        "cdn": "https://cdn.edge.ai/models/qwen-1.5b_q4.tar.zst"
      },
      "requirements": {
        "minOS": "14.0",
        "minMemory": 2147483648
      }
    }
  }
}
```

## Phase 3: Implementation Details

### 3.1 Bridge Layer Adaptation

**From MLCEngine's JSON FFI approach:**
```objc
// EdgeLLMBridge.mm
@implementation EdgeLLMBridge {
    std::unique_ptr<mlc::llm::JSONFFIEngine> engine;
}

- (instancetype)initWithModelPath:(NSString *)path {
    mlc::llm::JSONFFIEngineConfig config;
    config.model = std::string([path UTF8String]);
    config.device = "metal";
    engine = std::make_unique<mlc::llm::JSONFFIEngine>(config);
    return self;
}

- (NSString *)chat:(NSString *)prompt {
    std::string request = CreateChatRequest([prompt UTF8String]);
    std::string response = engine->Chat(request);
    return ParseChatResponse(response);
}
@end
```

### 3.2 Swift Actor Implementation

```swift
public actor EdgeLLM {
    private let bridge: EdgeLLMBridge
    private let modelId: String
    
    public init(modelId: String, options: Options = .default) async throws {
        self.modelId = modelId
        
        // Ensure model is downloaded
        let modelPath = try await ModelManager.shared.ensureModel(modelId)
        
        // Initialize bridge on background thread
        self.bridge = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let bridge = EdgeLLMBridge(modelPath: modelPath)
                continuation.resume(returning: bridge)
            }
        }
    }
    
    public func chat(_ prompt: String) async throws -> String {
        return await withCheckedThrowingContinuation { continuation in
            bridge.chatAsync(prompt) { response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: response ?? "")
                }
            }
        }
    }
}
```

### 3.3 Build Plugin Implementation

```swift
@main
struct MLCBuildPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        let models = ["qwen-1.5b", "llama3-8b", "mistral-7b"]
        let commands = models.map { model in
            createCompileCommand(for: model, context: context)
        }
        return commands
    }
    
    private func createCompileCommand(for model: String, context: PluginContext) -> Command {
        let outputDir = context.pluginWorkDirectory.appending("models")
        let script = """
            #!/bin/bash
            set -e
            
            # Setup Python environment
            python3 -m venv venv
            source venv/bin/activate
            pip install --quiet mlc_llm transformers
            
            # Compile model
            mlc_llm compile \\
                --model-id \(model) \\
                --quantization q4f16_1 \\
                --target metal \\
                --output \(outputDir)/\(model)_q4
            
            # Package model
            tar -czf \(outputDir)/\(model)_q4.tar.zst \\
                -C \(outputDir)/\(model)_q4 .
        """
        
        return .prebuildCommand(
            displayName: "Compile \(model) for Metal",
            executable: .init("/bin/bash"),
            arguments: ["-c", script],
            outputFilesDirectory: outputDir
        )
    }
}
```

## Phase 4: Testing & Validation

### 4.1 Unit Tests
- Model download and caching
- Bridge layer functionality
- Async/await behavior
- Error handling

### 4.2 Integration Tests
- End-to-end chat completion
- Streaming responses
- Memory usage monitoring
- Performance benchmarks

### 4.3 Device Testing
- iPhone 12+ (A14 Bionic)
- iPad Pro (M1+)
- macOS (Apple Silicon)
- visionOS compatibility

## Phase 5: Distribution

### 5.1 Package Publishing
1. Build xcframework for all platforms
2. Upload to CDN with versioning
3. Update Package.swift with checksum
4. Tag release on GitHub
5. Submit to Swift Package Index

### 5.2 Model Distribution
- Host quantized models on Hugging Face Hub
- Mirror on CDN for reliability
- Implement fallback URLs
- Support custom model sources

## Phase 6: Future Enhancements

### 6.1 Advanced Features
- Multiple model loading
- Context persistence
- Custom tokenizers
- Fine-tuning support

### 6.2 Platform Expansion
- watchOS support (limited models)
- tvOS compatibility
- Catalyst optimization
- Swift 6 concurrency

## Implementation Timeline

1. **Week 1-2**: Extract and simplify MLCSwift components
2. **Week 3-4**: Build xcframework and packaging pipeline
3. **Week 5-6**: Implement model download/caching system
4. **Week 7-8**: Testing and optimization
5. **Week 9-10**: Documentation and release preparation

## Success Criteria

- Single-line package installation
- < 5 lines of code for basic usage
- < 10 MB package size (excluding models)
- < 3 second model load time
- Comprehensive documentation
- 95%+ test coverage