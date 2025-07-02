# EdgeLLM Release Notes

## v0.1.1 (2025-07-01)

### 🎉 Major Updates

- **Complete C++ Runtime Package**: EdgeLLM now includes MLCRuntime.xcframework with all necessary C++ libraries
- **No External Dependencies**: The package is completely self-contained
- **Model Compilation Support**: Successfully compiled Qwen 0.5B model for iOS using MLC-LLM

### 🚀 Features

- Binary distribution via Swift Package Manager
- Support for three lightweight models:
  - Qwen 0.5B (Ultra lightweight, ~1GB)
  - Gemma 2B (Balanced performance, ~3GB)
  - Phi-3.5 Mini (High quality, ~3GB)
- Model download infrastructure (ModelDownloader.swift)
- Streaming API support
- Simple one-line API: `EdgeLLM.chat("Hello!")`

### 📦 Technical Details

- Package size: 7.9MB (EdgeLLM-Complete.zip)
- Includes MLCSwift sources and MLCRuntime.xcframework
- Compatible with iOS 14.0+
- Metal GPU acceleration support

### 🚧 Known Limitations

- Model files are not yet hosted (infrastructure being set up)
- First release focuses on framework readiness
- Mock implementation included for testing

### 🔧 Installation

```swift
dependencies: [
    .package(url: "https://github.com/john-rocky/EdgeLLM", branch: "complete-package")
]
```

### 🛠️ Development

- Compiled Qwen 0.5B model using mlc_llm in myenv conda environment
- Created comprehensive build scripts (build_complete_xcframework.sh)
- Implemented model download functionality with SHA256 verification

### 🔮 Next Steps

1. Set up model hosting infrastructure
2. Upload compiled models to Hugging Face or CDN
3. Enable automatic model downloads
4. Create more example applications

## v0.1.0 (2025-06-30)

- Initial release
- Basic package structure
- Documentation and examples