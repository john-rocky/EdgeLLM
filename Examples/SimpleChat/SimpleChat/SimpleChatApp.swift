import SwiftUI

@main
struct SimpleChatApp: App {
    init() {
        // Note: In a production app, we would need to properly initialize MLC-LLM
        // The current XCFramework is missing the json_ffi_engine initialization
        print("⚠️ Warning: MLC-LLM initialization incomplete in current XCFramework")
        print("💡 To fix: Use MLCChat's library configuration or rebuild XCFramework with json_ffi_engine.cc")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}