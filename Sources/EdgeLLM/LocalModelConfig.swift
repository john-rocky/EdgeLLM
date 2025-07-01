import Foundation

/// ローカルモデルのテスト用設定
/// 開発時のみ使用
@available(iOS 14.0, macOS 11.0, *)
public extension EdgeLLM {
    
    /// ローカルのキャッシュされたモデルパス
    static let localModelPaths: [Model: String] = [
        .qwen05b: "/Users/agmajima/.cache/mlc_llm/model_weights/hf/mlc-ai/Qwen3-0.6B-q0f16-MLC",
        .gemma2b: "/Users/agmajima/.cache/mlc_llm/model_weights/hf/mlc-ai/gemma-2-2b-it-q4f16_1-MLC",
        .phi3_mini: "/Users/agmajima/.cache/mlc_llm/model_weights/hf/mlc-ai/Phi-3.5-mini-instruct-q4f16_1-MLC"
    ]
    
    /// ローカルモデルを使用してチャット（テスト用）
    static func chatWithLocalModel(
        _ prompt: String,
        model: Model = .qwen05b,
        options: Options = .default
    ) async throws -> String {
        // 一時的にローカルパスを使用
        guard localModelPaths[model] != nil else {
            throw EdgeLLMError.modelNotFound(model.rawValue)
        }
        
        // ローカルモデルでEdgeLLMを初期化
        let llm = try await EdgeLLM(model: model, options: options)
        return try await llm.chat(prompt)
    }
}