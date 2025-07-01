#!/usr/bin/env swift

import Foundation

// Simple test script to verify EdgeLLM with local model
// Run with: swift TestLocalModel.swift

print("🔍 Testing EdgeLLM with local Qwen2-0.5B model...")

// Check if model exists
let modelPath = "/Users/majimadaisuke/.cache/mlc_llm/model_weights/hf/mlc-ai/Qwen2-0.5B-Instruct-q0f16-MLC"
let fileManager = FileManager.default

if fileManager.fileExists(atPath: modelPath) {
    print("✅ Model found at: \(modelPath)")
    
    // List model files
    do {
        let files = try fileManager.contentsOfDirectory(atPath: modelPath)
        print("\n📁 Model files:")
        for file in files.prefix(10) {
            if let attrs = try? fileManager.attributesOfItem(atPath: "\(modelPath)/\(file)"),
               let size = attrs[.size] as? Int {
                let sizeInMB = Double(size) / 1024 / 1024
                print("  - \(file): \(String(format: "%.1f", sizeInMB)) MB")
            }
        }
        
        // Check for required files
        let requiredFiles = ["mlc-chat-config.json", "ndarray-cache.json", "params_shard_0.bin", "tokenizer.json"]
        var allFilesPresent = true
        
        print("\n🔍 Checking required files:")
        for required in requiredFiles {
            let exists = fileManager.fileExists(atPath: "\(modelPath)/\(required)")
            print("  - \(required): \(exists ? "✅" : "❌")")
            if !exists { allFilesPresent = false }
        }
        
        if allFilesPresent {
            print("\n✅ All required files are present!")
            print("📱 This model is ready to use with EdgeLLM")
        } else {
            print("\n❌ Some required files are missing")
        }
        
    } catch {
        print("❌ Error reading model directory: \(error)")
    }
} else {
    print("❌ Model not found at expected path")
    print("💡 Please run mlc_llm to download the model first")
}

// Check model library
let modelLibPath = "/Users/majimadaisuke/.cache/mlc_llm/model_lib/0920320bd8cb76240254512c707122bc.tar"
if fileManager.fileExists(atPath: modelLibPath) {
    print("\n✅ Model library found at: \(modelLibPath)")
} else {
    print("\n⚠️  Model library not found")
}

print("\n📝 Next steps:")
print("1. Update EdgeLLM to use this local model path")
print("2. Build SimpleChat app with DEBUG flag enabled")
print("3. Run the app and test with Qwen 0.5B model")