import Foundation

// Simple test to verify EdgeLLM can use MLCChat models
print("🔍 Testing EdgeLLM with MLCChat models...")

// Check if MLCChat app is installed and has models
let mlcChatBundlePath = "/Applications/MLCChat.app/bundle"
let fileManager = FileManager.default

print("📁 Checking MLCChat bundle path: \(mlcChatBundlePath)")

if fileManager.fileExists(atPath: mlcChatBundlePath) {
    print("✅ Found MLCChat bundle")
    
    // List available models
    do {
        let models = try fileManager.contentsOfDirectory(atPath: mlcChatBundlePath)
        print("📦 Available models:")
        for model in models {
            print("  - \(model)")
            
            // Check model config
            let configPath = "\(mlcChatBundlePath)/\(model)/mlc-chat-config.json"
            if fileManager.fileExists(atPath: configPath) {
                print("    ✅ Has config file")
            }
        }
    } catch {
        print("❌ Error listing models: \(error)")
    }
} else {
    print("❌ MLCChat bundle not found at expected path")
    
    // Try to find in user's Library
    let libraryPaths = [
        "~/Library/Containers/ai.mlc.mlcchat/Data/Library/Application Support/MLCChat",
        "~/Library/Application Support/MLCChat",
        "~/Documents/MLCChat"
    ]
    
    for path in libraryPaths {
        let expandedPath = NSString(string: path).expandingTildeInPath
        print("🔍 Checking: \(expandedPath)")
        if fileManager.fileExists(atPath: expandedPath) {
            print("  ✅ Found directory")
            do {
                let contents = try fileManager.contentsOfDirectory(atPath: expandedPath)
                print("  📁 Contents: \(contents)")
            } catch {
                print("  ❌ Error: \(error)")
            }
        }
    }
}