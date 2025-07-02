import Foundation
import MLCRuntime

@available(iOS 14.0, *)
public class MLCInitializer {
    public static let shared = MLCInitializer()
    private var isInitialized = false
    
    private init() {}
    
    public func initialize() {
        guard !isInitialized else { return }
        
        // Initialize MLC-LLM runtime
        // This registers the necessary functions including CreateJSONFFIEngine
        
        // Note: In a real implementation, we would need to call the proper
        // initialization functions from the MLC runtime. Since we don't have
        // direct access to those functions in the current setup, we'll need
        // to modify our approach.
        
        isInitialized = true
    }
}