# EdgeLLM

[![SwiftPM](https://img.shields.io/badge/SwiftPM-Add%20Package-green)](https://swift.org/package-manager/)
[![License](https://img.shields.io/badge/License-Apache--2.0-blue)](LICENSE)
[![Release](https://img.shields.io/github/v/tag/john-rocky/EdgeLLM)](https://github.com/john-rocky/EdgeLLM/releases)

**EdgeLLM** is a Swift Package that currently ships with **three pre‑compiled models**  
(~300 MB XCFramework) so you can run LLMs offline on iOS / macOS *without any extra download*.

> A lightweight 10 MB runtime + on‑demand weights is on our roadmap.  
> For now we prioritise *“it just works”* over minimal binary size.

---

## 🚀 One‑Line Installation

```swift
// Package.swift
.package(url: "https://github.com/john-rocky/EdgeLLM", from: "0.1.1")
```

*First `swift build` fetches the 300 MB package; subsequent builds are cached.*

---

## ⚡ 5‑Line Quick Start

```swift
import EdgeLLM
let llm   = try EdgeLLM(modelId: "qwen-0.6b_q0")
let reply = try await llm.chat("Hello!")
print(reply)
```

Because the models are bundled, **no runtime download** is needed.  
Works entirely offline—even in Airplane Mode.

---

## 📚 Bundled Models

| ID | Params | Languages | Suggested RAM | Typical Use |
|----|--------|-----------|--------------|-------------|
| `qwen-0.6b_q0`    | 0.6 B | EN · JA · ZH | ≥ 4 GB | lightweight chat, summaries |
| `gemma-2b_q4`     | 2 B   | EN          | ≥ 4 GB | Q&A, code completion |
| `phi-3.5-mini_q4` | 3.5 B | Multi       | ≥ 6 GB | multilingual chat, translation |

*More models coming—see roadmap.*

---

## ✨ Features

* **Offline by default** – all weights in the app bundle  
* **Metal‑accelerated** – ≈ 15 tok/s on iPhone 15 Pro (Phi‑3.5 Mini int4)  
* **BYOM** – side‑load any `.tar.zst` via `EdgeLLM.registerLocalModel()`  
* **Apache‑2.0** – business‑friendly licence  

---

## 🗺 Roadmap

| Milestone | ETA |
|-----------|-----|
| 10 MB runtime + on‑demand weights | Q3 2025 |
| Android / Vulkan build | Q3 2025 |
| High‑perf 7 B kernels (plugin) | Planned |
| WebAssembly demo | Research |

---

## 💬 Community

* **Discord** – <https://discord.gg/edgellm>  
* **GitHub Discussions** – open a topic under *Q&A*.

---

## 🔒 License

Apache‑2.0 — see `LICENSE`.  
Portions derived from MLC‑LLM (Apache‑2.0); see `LICENSE-THIRD-PARTY.txt`.

---

*Generated 2025-07-03*
