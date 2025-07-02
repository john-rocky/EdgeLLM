import SwiftUI

@main
struct SimpleChatApp: App {
    init() {
        // MLC-LLM is now properly initialized in the XCFramework
        print("🚀 SimpleChat starting with EdgeLLM...")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}