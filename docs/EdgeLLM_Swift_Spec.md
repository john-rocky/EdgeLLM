# EdgeLLM Swift SDK — Implementation Specification
*Last updated: 2025-06-28*

---

## 0. Purpose

This document explains **exactly** how to turn the reference *MLCChat* sample into a
production‑ready Swift Package named **EdgeLLM**.  
The goal is that a developer (or an autonomous AI agent) can follow the steps here,
run the supplied commands, and end up with a package that is installed with one line:

```swift
.package(url: "https://github.com/edgeai/EdgeLLM", from: "0.1.0")
```

After installation, an app should compile and run with:

```swift
import EdgeLLM
let llm = try EdgeLLM(modelId: "qwen-1.5b_q4")
let reply = try await llm.chat("Hello, world!")
```

No other Xcode configuration is required.

---

## 1. High‑level workflow

1. **Offline build phase (macOS / CI)**  
   • convert the original Hugging Face model to MLC format  
   • compile Metal / Vulkan kernels  
   • wrap them into **MLCRuntime.xcframework**  
   • package the quantised weights and tokenizer into a single `.tar.zst` archive  
   • upload the archive to either Hugging Face Hub or your CDN  
   • publish `MLCRuntime.xcframework` as a SwiftPM binary target.

2. **Runtime phase (iOS / visionOS / macOS Catalyst)**  
   • the Swift Package pulls in `MLCRuntime.xcframework`  
   • at first launch the SDK downloads the `.tar.zst`, verifies SHA‑256 and unpacks it  
     under `~/Library/Application Support/EdgeLLM/<sha>/`  
   • the app calls `EdgeLLM.chat()` which forwards the prompt to MLCRuntime C‑API and streams tokens back.

---

## 2. Repository layout

```
EdgeLLM/
├ Package.swift
├ Sources/
│ └ EdgeLLM/
│    ├ EdgeLLM.swift
│    └ Resources/
│        └ bundle/
├ BinaryTargets/
│ └ MLCRuntime.xcframework
├ Plugins/
│ └ MLCBuildPlugin/
│     └ Plugin.swift
└ .github/workflows/
      build.yml
```

---

## 3. Build‑tool plugin (Plugins/MLCBuildPlugin/Plugin.swift)

The plugin runs during `swift build` **only on Apple Silicon / macOS**.

```swift
import PackagePlugin
import Foundation

@main
struct MLCBuildPlugin: BuildToolPlugin {
  func createBuildCommands(context: PluginContext,
                           target: Target) throws -> [Command] {

    let work  = context.pluginWorkDirectory
    let venv  = work.appending("venv")
    let model = "qwen-1.5b"
    let out   = work.appending("package")

    let script = """
      python3 -m venv \(venv) &&
      \(venv)/bin/pip install --quiet mlc_llm==0.9.0 &&
      \(venv)/bin/mlc_llm compile --model \(model)            --target iphone --quantization q4f16_1 &&
      \(venv)/bin/mlc_llm package build/\(model)_q4f16            --tar -o \(out)/\(model)_q4f16.tar.zst
      """
    return [.prebuildCommand(
      displayName: "MLC ▸ compile & package \(model)",
      executable: .bash,
      arguments: ["-c", script],
      outputFilesDirectory: out)]
  }
}
```

---

## 4. Package.swift essentials

```swift
// swift-tools-version: 5.10
import PackageDescription

let package = Package(
  name: "EdgeLLM",
  platforms: [.iOS(.v15), .macOS(.v13)],
  products: [.library(name: "EdgeLLM", targets: ["EdgeLLM"])],
  targets: [
    .binaryTarget(
      name: "MLCRuntime",
      url: "https://cdn.edge.ai/xcframeworks/MLCRuntime_0.9.0.zip",
      checksum: "<SHA256>"
    ),
    .target(
      name: "EdgeLLM",
      dependencies: ["MLCRuntime"],
      resources: [.process("Resources/bundle")],
      plugins: [.plugin(name: "MLCBuildPlugin")]
    )
  ]
)
```

---

## 5. Runtime helper (Sources/EdgeLLM/EdgeLLM.swift)

```swift
import Foundation
import MLCRuntime

public final class EdgeLLM {
  private var session: OpaquePointer?

  public init(modelId: String) throws {
    try Self.ensureModelReady(modelId: modelId)
    let path = Self.localPath(for: modelId)
    session  = mlc_llm_create_session(path)
  }

  public func chat(_ text: String) throws -> String {
    var outPtr: UnsafeMutablePointer<CChar>? = nil
    mlc_llm_chat(session, text, &outPtr)
    defer { mlc_llm_free(outPtr) }
    return String(cString: outPtr!)
  }
}
```

`mlc_llm_*` symbols are provided by `MLCRuntime.xcframework`.

---

## 6. Manifest JSON (downloaded at runtime)

```json
{
  "modelId": "qwen-1.5b_q4",
  "version": "2025-06-28",
  "url": {
    "default": "hf://edgeai/qwen-1.5b_q4.tar.zst",
    "premium": "https://cdn.edge.ai/signed/qwen?sig=..."
  },
  "sha256": "d1e4..."
}
```

---

## 7. Continuous‑integration pipeline

1. Checkout  
2. `swift build -c release` (triggers plugin)  
3. Upload runtime & model to storage  
4. Patch checksum into Package.swift  
5. Create GitHub Release `v0.1.0`

---

## 8. Testing checklist

* Build on macOS 14 & iOS 17 sim  
* Verify first‑run download + local cache  
* Chat latency < 5 s on iPhone 15  
* Archive source < 10 MB  
* SHA‑256 of local archive equals manifest

---

Happy shipping!
