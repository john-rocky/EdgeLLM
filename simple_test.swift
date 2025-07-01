#!/usr/bin/env swift

import Foundation

print("🚀 EdgeLLM Simple Test")

// 1. モデルファイルの存在確認
let modelPaths = [
    "/Users/agmajima/.cache/mlc_llm/model_weights/hf/mlc-ai/Qwen3-0.6B-q0f16-MLC",
    "/Users/agmajima/.cache/mlc_llm/model_weights/hf/mlc-ai/gemma-2-2b-it-q4f16_1-MLC",
    "/Users/agmajima/.cache/mlc_llm/model_weights/hf/mlc-ai/Phi-3.5-mini-instruct-q4f16_1-MLC"
]

let fileManager = FileManager.default

print("\n📂 Model Files Check:")
for (index, path) in modelPaths.enumerated() {
    let modelName = ["Qwen3-0.6B", "Gemma-2-2B", "Phi-3.5-mini"][index]
    let exists = fileManager.fileExists(atPath: path)
    let status = exists ? "✅" : "❌"
    print("  \(status) \(modelName): \(exists ? "Found" : "Not Found")")
    
    if exists {
        // チェック設定ファイル
        let configPath = "\(path)/mlc-chat-config.json"
        let hasConfig = fileManager.fileExists(atPath: configPath)
        print("     Config: \(hasConfig ? "✅" : "❌")")
        
        // tokenizerファイル
        let tokenizerPath = "\(path)/tokenizer.json"
        let hasTokenizer = fileManager.fileExists(atPath: tokenizerPath)
        print("     Tokenizer: \(hasTokenizer ? "✅" : "❌")")
    }
}

// 2. MLCライブラリの存在確認
print("\n📚 MLC Libraries Check:")
let mlcLibPath = "/Users/agmajima/Downloads/mlc-llm/ios/MLCSwift"
let libExists = fileManager.fileExists(atPath: mlcLibPath)
print("  MLCSwift: \(libExists ? "✅ Found" : "❌ Not Found")")

if libExists {
    let sourceExists = fileManager.fileExists(atPath: "\(mlcLibPath)/Sources")
    print("  Sources: \(sourceExists ? "✅" : "❌")")
}

// 3. EdgeLLMパッケージ構造の確認
print("\n📦 EdgeLLM Package Check:")
let edgeLLMPath = "/Users/agmajima/Downloads/mlc-llm/EdgeLLM"
let packageExists = fileManager.fileExists(atPath: "\(edgeLLMPath)/Package.swift")
print("  Package.swift: \(packageExists ? "✅" : "❌")")

let sourcesExists = fileManager.fileExists(atPath: "\(edgeLLMPath)/Sources/EdgeLLM")
print("  Sources: \(sourcesExists ? "✅" : "❌")")

print("\n🏁 Test Complete!")
print("💡 Next: Run 'swift build' in EdgeLLM directory to test compilation")