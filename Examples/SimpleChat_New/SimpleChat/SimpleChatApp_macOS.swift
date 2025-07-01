import SwiftUI

// macOS用のテストアプリ
#if os(macOS)
@main
struct SimpleChatApp_macOS: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 400, minHeight: 600)
        }
    }
}
#endif