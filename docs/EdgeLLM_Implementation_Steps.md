# EdgeLLM Swift Package - Step-by-Step Implementation Guide

## 🎯 Goal
Create a simplified Swift Package that allows developers to use LLMs with just 3 lines of code, while handling model downloading, caching, and runtime management automatically.

## 📋 Prerequisites
- macOS with Xcode 15+
- CMake installed
- Python 3.8+ with pip
- Understanding of MLC-LLM codebase
- Apple Developer account (for distribution)

## 🚀 Implementation Steps

### Step 1: Environment Setup (Day 1)

#### 1.1 Clone and Build MLC-LLM
```bash
# Clone repository
git clone https://github.com/mlc-ai/mlc-llm.git
cd mlc-llm
git submodule update --init --recursive

# Build for iOS
cd ios
./prepare_libs.sh

# Verify build
ls -la build/lib/
# Should see: libmlc_llm.a, libtvm_runtime.a, etc.
```

#### 1.2 Create EdgeLLM Repository
```bash
# Create new directory
mkdir EdgeLLM && cd EdgeLLM
git init

# Create package structure
mkdir -p Sources/EdgeLLM/Bridge
mkdir -p Sources/EdgeLLMC/include
mkdir -p BinaryTargets
mkdir -p Plugins/MLCBuildPlugin
mkdir -p Tests/EdgeLLMTests
```

#### 1.3 Initial Package.swift
```swift
// Create Package.swift
cat > Package.swift << 'EOF'
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EdgeLLM",
    platforms: [.iOS(.v14), .macOS(.v13)],
    products: [
        .library(name: "EdgeLLM", targets: ["EdgeLLM"])
    ],
    targets: [
        .target(
            name: "EdgeLLM",
            dependencies: ["EdgeLLMC"]
        ),
        .target(
            name: "EdgeLLMC",
            dependencies: []
        ),
        .testTarget(
            name: "EdgeLLMTests",
            dependencies: ["EdgeLLM"]
        )
    ]
)
EOF
```

### Step 2: Extract Core Components (Days 2-3)

#### 2.1 Copy Essential Files from MLCSwift
```bash
# From mlc-llm repository
cp ios/MLCSwift/Sources/MLCEngine/OpenAIProtocol.swift \
   ../EdgeLLM/Sources/EdgeLLM/

# Simplify by removing unnecessary features
# Keep only: ChatCompletionMessage, Role, basic streaming
```

#### 2.2 Create Simplified Bridge Header
```objc
// Sources/EdgeLLM/Bridge/EdgeLLMBridge.h
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^EdgeLLMStreamCallback)(NSString * _Nullable token, 
                                     NSError * _Nullable error);

@interface EdgeLLMBridge : NSObject

- (instancetype)initWithModelPath:(NSString *)modelPath 
                         modelLib:(NSString *)modelLib;

- (void)chatAsync:(NSString *)prompt 
         callback:(EdgeLLMStreamCallback)callback;

- (void)reset;
- (void)unload;

@end

NS_ASSUME_NONNULL_END
```

#### 2.3 Create Bridge Implementation
```objc
// Sources/EdgeLLM/Bridge/EdgeLLMBridge.mm
#import "EdgeLLMBridge.h"
#include <memory>
#include <string>

// Forward declarations
namespace mlc { namespace llm {
    class JSONFFIEngine;
}}

@implementation EdgeLLMBridge {
    std::unique_ptr<mlc::llm::JSONFFIEngine> engine;
    dispatch_queue_t engineQueue;
}

- (instancetype)initWithModelPath:(NSString *)modelPath 
                         modelLib:(NSString *)modelLib {
    if (self = [super init]) {
        engineQueue = dispatch_queue_create("ai.edge.llm.engine", 
                                          DISPATCH_QUEUE_SERIAL);
        // Implementation details from MLCEngine
    }
    return self;
}

// ... rest of implementation
@end
```

### Step 3: Build XCFramework (Days 4-5)

#### 3.1 Create Build Script
```bash
#!/bin/bash
# scripts/build_xcframework.sh

set -e

# Build for iOS Device
xcodebuild archive \
    -scheme MLCRuntime \
    -archivePath archives/ios-device.xcarchive \
    -sdk iphoneos \
    SKIP_INSTALL=NO

# Build for iOS Simulator
xcodebuild archive \
    -scheme MLCRuntime \
    -archivePath archives/ios-simulator.xcarchive \
    -sdk iphonesimulator \
    SKIP_INSTALL=NO

# Build for macOS
xcodebuild archive \
    -scheme MLCRuntime \
    -archivePath archives/macos.xcarchive \
    SKIP_INSTALL=NO

# Create XCFramework
xcodebuild -create-xcframework \
    -framework archives/ios-device.xcarchive/Products/Library/Frameworks/MLCRuntime.framework \
    -framework archives/ios-simulator.xcarchive/Products/Library/Frameworks/MLCRuntime.framework \
    -framework archives/macos.xcarchive/Products/Library/Frameworks/MLCRuntime.framework \
    -output BinaryTargets/MLCRuntime.xcframework

# Calculate checksum
swift package compute-checksum BinaryTargets/MLCRuntime.xcframework.zip
```

#### 3.2 Update Package.swift with Binary Target
```swift
targets: [
    .binaryTarget(
        name: "MLCRuntime",
        path: "BinaryTargets/MLCRuntime.xcframework"
        // or url: "https://github.com/edgeai/EdgeLLM/releases/download/v0.1.0/MLCRuntime.xcframework.zip",
        // checksum: "computed-checksum"
    ),
    .target(
        name: "EdgeLLM",
        dependencies: ["EdgeLLMC", "MLCRuntime"]
    )
]
```

### Step 4: Implement Model Manager (Days 6-7)

#### 4.1 Create Model Manifest
```json
// Sources/EdgeLLM/Resources/models.json
{
  "version": "1.0",
  "models": {
    "qwen-1.5b_q4": {
      "displayName": "Qwen 1.5B Quantized",
      "version": "2025-06-28",
      "sha256": "d1e4c3b2a1...",
      "compressedSize": 524288000,
      "uncompressedSize": 1073741824,
      "urls": {
        "primary": "https://huggingface.co/edgeai/qwen-1.5b-q4/resolve/main/model.tar.zst",
        "mirror": "https://cdn.edge.ai/models/qwen-1.5b-q4.tar.zst"
      },
      "requirements": {
        "minOS": "14.0",
        "minMemoryBytes": 2147483648,
        "supportedDevices": ["iPhone12,1", "iPad13,1"]
      }
    }
  }
}
```

#### 4.2 Implement ModelManager
```swift
// Sources/EdgeLLM/ModelManager.swift
import Foundation
import Compression

actor ModelManager {
    static let shared = ModelManager()
    
    private let cacheURL = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)
        .first!
        .appendingPathComponent("EdgeLLM")
    
    func ensureModel(_ modelId: String, 
                     progress: ((Double) -> Void)? = nil) async throws -> URL {
        // Check cache
        let modelPath = cacheURL.appendingPathComponent(modelId)
        if FileManager.default.fileExists(atPath: modelPath.path) {
            return modelPath
        }
        
        // Download
        let manifest = try await loadManifest()
        guard let model = manifest.models[modelId] else {
            throw EdgeLLMError.modelNotFound(modelId)
        }
        
        // Download with progress
        let downloadedURL = try await download(
            from: URL(string: model.urls.primary)!,
            progress: progress
        )
        
        // Verify checksum
        let checksum = try calculateSHA256(for: downloadedURL)
        guard checksum == model.sha256 else {
            throw EdgeLLMError.checksumMismatch
        }
        
        // Extract
        try await extractArchive(downloadedURL, to: modelPath)
        
        return modelPath
    }
}
```

### Step 5: Create Main API (Days 8-9)

#### 5.1 EdgeLLM Swift Actor
```swift
// Sources/EdgeLLM/EdgeLLM.swift
import Foundation

public actor EdgeLLM {
    private var bridge: EdgeLLMBridge?
    private let modelId: String
    private let options: Options
    
    public struct Options {
        public var temperature: Float
        public var maxTokens: Int
        public var cacheDirectory: URL?
        
        public static let `default` = Options(
            temperature: 0.7,
            maxTokens: 2048,
            cacheDirectory: nil
        )
    }
    
    public init(modelId: String, 
                options: Options = .default,
                onProgress: ((Double) -> Void)? = nil) async throws {
        self.modelId = modelId
        self.options = options
        
        // Ensure model is downloaded
        let modelPath = try await ModelManager.shared.ensureModel(
            modelId, 
            progress: onProgress
        )
        
        // Initialize bridge
        self.bridge = await MainActor.run {
            EdgeLLMBridge(
                modelPath: modelPath.path,
                modelLib: "model_iphone"
            )
        }
    }
    
    public func chat(_ prompt: String) async throws -> String {
        guard let bridge = bridge else {
            throw EdgeLLMError.notInitialized
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            var fullResponse = ""
            
            bridge.chatAsync(prompt) { token, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let token = token {
                    if token == "[DONE]" {
                        continuation.resume(returning: fullResponse)
                    } else {
                        fullResponse += token
                    }
                }
            }
        }
    }
    
    public func stream(_ prompt: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            guard let bridge = bridge else {
                continuation.finish(throwing: EdgeLLMError.notInitialized)
                return
            }
            
            bridge.chatAsync(prompt) { token, error in
                if let error = error {
                    continuation.finish(throwing: error)
                } else if let token = token {
                    if token == "[DONE]" {
                        continuation.finish()
                    } else {
                        continuation.yield(token)
                    }
                }
            }
        }
    }
}
```

### Step 6: Testing (Days 10-11)

#### 6.1 Unit Tests
```swift
// Tests/EdgeLLMTests/EdgeLLMTests.swift
import XCTest
@testable import EdgeLLM

final class EdgeLLMTests: XCTestCase {
    func testModelDownload() async throws {
        // Test model download with mock server
        let mockURL = createMockModelServer()
        let manager = ModelManager(baseURL: mockURL)
        
        let modelPath = try await manager.ensureModel("test-model")
        XCTAssertTrue(FileManager.default.fileExists(atPath: modelPath.path))
    }
    
    func testChatCompletion() async throws {
        let llm = try await EdgeLLM(modelId: "qwen-1.5b_q4")
        let response = try await llm.chat("Hello")
        XCTAssertFalse(response.isEmpty)
    }
    
    func testStreaming() async throws {
        let llm = try await EdgeLLM(modelId: "qwen-1.5b_q4")
        var tokens: [String] = []
        
        for try await token in llm.stream("Tell me a joke") {
            tokens.append(token)
        }
        
        XCTAssertFalse(tokens.isEmpty)
    }
}
```

#### 6.2 Integration Tests
```swift
func testMemoryUsage() async throws {
    let before = getMemoryUsage()
    let llm = try await EdgeLLM(modelId: "qwen-1.5b_q4")
    let after = getMemoryUsage()
    
    XCTAssertLessThan(after - before, 2_000_000_000) // < 2GB
}

func testConcurrentRequests() async throws {
    let llm = try await EdgeLLM(modelId: "qwen-1.5b_q4")
    
    let results = await withTaskGroup(of: String.self) { group in
        for i in 0..<5 {
            group.addTask {
                try! await llm.chat("Question \(i)")
            }
        }
        
        var results: [String] = []
        for await result in group {
            results.append(result)
        }
        return results
    }
    
    XCTAssertEqual(results.count, 5)
}
```

### Step 7: Create Build Plugin (Days 12-13)

#### 7.1 Model Compilation Plugin
```swift
// Plugins/MLCBuildPlugin/Plugin.swift
import PackagePlugin
import Foundation

@main
struct MLCBuildPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, 
                           target: Target) throws -> [Command] {
        
        let modelsToCompile = [
            "qwen-1.5b",
            "llama3-8b",
            "mistral-7b"
        ]
        
        return modelsToCompile.map { modelId in
            let outputPath = context.pluginWorkDirectory
                .appending(subpath: "\(modelId)_q4.tar.zst")
            
            return .buildCommand(
                displayName: "Compile \(modelId) for Metal",
                executable: context.tool(named: "mlc-compile").path,
                arguments: [
                    "--model", modelId,
                    "--quantization", "q4f16_1",
                    "--target", "metal",
                    "--output", outputPath
                ],
                outputFiles: [outputPath]
            )
        }
    }
}
```

### Step 8: Documentation (Days 14-15)

#### 8.1 Create README.md
```markdown
# EdgeLLM

Run Large Language Models on iOS/macOS with just 3 lines of code.

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/edgeai/EdgeLLM", from: "0.1.0")
]
```

## Usage

```swift
import EdgeLLM

// Initialize (downloads model on first use)
let llm = try await EdgeLLM(modelId: "qwen-1.5b_q4")

// Chat
let response = try await llm.chat("Hello, how are you?")

// Stream
for try await token in llm.stream("Tell me a story") {
    print(token, terminator: "")
}
```
```

#### 8.2 API Documentation
- Generate DocC documentation
- Create usage examples
- Performance guidelines
- Troubleshooting guide

### Step 9: Distribution Setup (Days 16-17)

#### 9.1 GitHub Actions CI/CD
```yaml
# .github/workflows/release.yml
name: Release
on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build XCFramework
        run: ./scripts/build_xcframework.sh
      
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            BinaryTargets/MLCRuntime.xcframework.zip
            
      - name: Update Package.swift
        run: |
          CHECKSUM=$(swift package compute-checksum MLCRuntime.xcframework.zip)
          sed -i '' "s/checksum: \".*\"/checksum: \"$CHECKSUM\"/" Package.swift
```

#### 9.2 Model Hosting
- Upload compiled models to Hugging Face Hub
- Set up CDN for faster downloads
- Implement model versioning

### Step 10: Launch (Days 18-20)

#### 10.1 Pre-launch Checklist
- [ ] All tests passing
- [ ] Documentation complete
- [ ] Example app working
- [ ] Performance benchmarks documented
- [ ] Security review (SHA-256 verification)
- [ ] License files included

#### 10.2 Launch Steps
1. Tag release v0.1.0
2. Publish to GitHub
3. Submit to Swift Package Index
4. Write blog post/announcement
5. Create demo video

## 🎯 Success Metrics

- **Installation**: < 1 minute
- **First model download**: < 2 minutes on WiFi
- **Time to first token**: < 3 seconds
- **API simplicity**: 3 lines to working chat
- **Package size**: < 10MB (excluding models)
- **Test coverage**: > 90%

## 🚧 Troubleshooting Common Issues

1. **Build Errors**: Ensure CMake and Xcode command line tools installed
2. **Memory Issues**: Check device has 4GB+ free RAM
3. **Download Failures**: Implement retry logic with exponential backoff
4. **Performance**: Use quantized models (q4) for optimal speed/quality

## 🔄 Future Iterations

- **v0.2**: Multiple model support
- **v0.3**: Custom model loading
- **v0.4**: Fine-tuning API
- **v0.5**: Vision model support