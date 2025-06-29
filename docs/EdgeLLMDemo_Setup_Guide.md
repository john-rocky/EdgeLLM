# EdgeLLMDemo Setup Guide

## 1. Bundle Directory Structure

Your EdgeLLMDemo project should have this structure:

```
EdgeLLMDemo/
├── EdgeLLMDemo.xcodeproj
├── EdgeLLMDemo/
│   ├── ContentView.swift
│   └── EdgeLLMDemoApp.swift
└── bundle/                              # Add this directory
    └── Llama-3.2-3B-Instruct-q4f16_1-MLC/   # Model files
        ├── mlc-chat-config.json
        ├── ndarray-cache.json
        ├── params_shard_*.bin
        ├── tokenizer.json
        └── tokenizer_config.json
```

## 2. Add Model Files to Xcode

1. In Xcode, right-click on the project navigator
2. Select "Add Files to EdgeLLMDemo..."
3. Choose the `bundle` folder
4. **IMPORTANT**: Select "Create folder references" (NOT "Create groups")
5. The folder should appear as a blue folder icon in Xcode

## 3. Update ContentView.swift

Use the correct model ID:

```swift
struct ContentView: View {
    @State private var edgeLLM: EdgeLLM?
    @State private var isLoading = true
    @State private var errorMessage = ""
    
    var body: some View {
        // ... existing code ...
    }
    
    private func initializeEdgeLLM() async {
        do {
            // Use the full model ID that matches the directory name
            edgeLLM = try await EdgeLLM(modelId: "Llama-3.2-3B-Instruct-q4f16_1-MLC")
            isLoading = false
        } catch {
            errorMessage = "Failed to load model: \(error)"
            isLoading = false
            print("Failed to load model: \(error)")
        }
    }
}
```

## 4. Add MLC Libraries

Make sure these libraries are added to your Xcode project:
- libmlc_llm.a
- libmodel_iphone.a
- libsentencepiece.a
- libtokenizers_cpp.a
- libtvm_runtime.a

## 5. Build Settings

Ensure "Other Linker Flags" includes:
```
-Wl,-all_load
```

## 6. Test

Build and run on your iPhone. The model should now load successfully!