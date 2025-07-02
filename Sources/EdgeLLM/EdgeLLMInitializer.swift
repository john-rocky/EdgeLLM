import Foundation

/// EdgeLLM Initializer
/// Forces the static library initialization
@available(iOS 14.0, macOS 11.0, *)
public struct EdgeLLMInitializer {
    /// Initialize EdgeLLM runtime
    /// Call this once at app startup if you encounter "CreateJSONFFIEngine not found" error
    public static func initialize() {
        // This forces the linker to include all symbols
        _ = MLCEngine()
    }
}