#!/usr/bin/env swift

import Foundation
import EdgeLLM

// Test EdgeLLM with local model
Task {
    do {
        print("Testing EdgeLLM with local Qwen 0.5B model...")
        print("Model path: /Users/majimadaisuke/.cache/mlc_llm/model_weights/hf/mlc-ai/Qwen2-0.5B-Instruct-q0f16-MLC")
        
        let response = try await EdgeLLM.chat("Hello! What is 2+2?", model: .qwen05b)
        print("Response: \(response)")
        
        print("\nTesting streaming...")
        for try await chunk in EdgeLLM.stream("Tell me a short story", model: .qwen05b) {
            print(chunk, terminator: "")
        }
        print("\n\nTest completed!")
    } catch {
        print("Error: \(error)")
    }
    exit(0)
}

dispatchMain()