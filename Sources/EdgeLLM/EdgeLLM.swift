import Foundation
import os

/// EdgeLLM - シンプルなLLM APIライブラリ
/// 
/// 使用例:
/// ```swift
/// let llm = try await EdgeLLM(model: .llama3_2)
/// let response = try await llm.chat("Hello, world!")
/// print(response)
/// ```
@available(iOS 14.0, macOS 11.0, *)
public actor EdgeLLM {
    
    // MARK: - Public Types
    
    /// サポートされているモデル
    public enum Model: String, CaseIterable {
        case qwen05b = "Qwen2-0.5B-Instruct-q0f16-MLC"
        case gemma2b = "gemma-2-2b-it-q4f16_1-MLC"
        case phi3_mini = "Phi-3.5-mini-instruct-q4f16_1-MLC"
        
        var modelLib: String {
            switch self {
            case .qwen05b:
                return "qwen3_q0f16_e63d9b1954017ab989b2bde1896a12e2"     // Qwen3 0.5B quantized model
            case .gemma2b:
                return "gemma2_q4f16_1_779a95d4ef785ea159992d38fac2317f"  // Gemma 2B quantized model
            case .phi3_mini:
                return "phi3_q4f16_1_eba3d93dab5930b68f7296c1fd0d29ec"    // Phi-3.5 mini quantized model
            }
        }
        
        var displayName: String {
            switch self {
            case .qwen05b:
                return "Qwen 0.5B"
            case .gemma2b:
                return "Gemma 2B"
            case .phi3_mini:
                return "Phi-3.5 Mini"
            }
        }
        
        var huggingFaceURL: String? {
            switch self {
            case .qwen05b:
                return "https://huggingface.co/mlc-ai/Qwen2-0.5B-Instruct-q0f16-MLC"
            case .gemma2b:
                return "https://huggingface.co/mlc-ai/gemma-2-2b-it-q4f16_1-MLC"
            case .phi3_mini:
                return "https://huggingface.co/mlc-ai/Phi-3.5-mini-instruct-q4f16_1-MLC"
            }
        }
    }
    
    /// 生成オプション
    public struct Options {
        public var temperature: Float
        public var maxTokens: Int
        public var topP: Float
        
        public static let `default` = Options(
            temperature: 0.7,
            maxTokens: 2048,
            topP: 0.95
        )
        
        public init(
            temperature: Float = 0.7,
            maxTokens: Int = 2048,
            topP: Float = 0.95
        ) {
            self.temperature = temperature
            self.maxTokens = maxTokens
            self.topP = topP
        }
    }
    
    // MARK: - Properties
    
    private let engine = MLCEngine()
    private let model: Model
    private let options: Options
    private var isLoaded = false
    private let logger = Logger(subsystem: "ai.edge.llm", category: "EdgeLLM")
    
    // MARK: - Initialization
    
    /// EdgeLLMを初期化
    /// - Parameters:
    ///   - model: 使用するモデル
    ///   - options: 生成オプション
    public init(model: Model, options: Options = .default) async throws {
        self.model = model
        self.options = options
        
        logger.info("Initializing EdgeLLM with model: \(model.displayName)")
        
        // モデルの可用性をチェック
        let modelPath = try await ensureModelAvailable(model)
        
        // モデルをロード
        try await loadModel(modelPath: modelPath, modelLib: model.modelLib)
    }
    
    // MARK: - Public Methods
    
    /// チャットメッセージを送信して完全なレスポンスを取得
    /// - Parameter prompt: ユーザーのメッセージ
    /// - Returns: モデルの完全なレスポンス
    public func chat(_ prompt: String) async throws -> String {
        guard isLoaded else {
            throw EdgeLLMError.modelNotLoaded
        }
        
        var fullResponse = ""
        
        for try await token in stream(prompt) {
            fullResponse += token
        }
        
        return fullResponse
    }
    
    /// チャットレスポンスをトークンごとにストリーム
    /// - Parameter prompt: ユーザーのメッセージ
    /// - Returns: トークンの非同期ストリーム
    public func stream(_ prompt: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                guard self.isLoaded else {
                    continuation.finish(throwing: EdgeLLMError.modelNotLoaded)
                    return
                }
                
                let request = ChatCompletionRequest(
                    messages: [
                        ChatCompletionMessage(role: .user, content: prompt)
                    ],
                    model: self.model.rawValue,
                    max_tokens: self.options.maxTokens,
                    stream: true,
                    temperature: self.options.temperature
                )
                
                do {
                    for try await response in await self.engine.chat.completions.create(
                        messages: request.messages,
                        model: request.model,
                        max_tokens: request.max_tokens,
                        stream_options: StreamOptions(include_usage: true),
                        temperature: request.temperature
                    ) {
                        for choice in response.choices {
                            if let content = choice.delta.content {
                                let token = content.asText()
                                if !token.isEmpty {
                                    continuation.yield(token)
                                }
                            }
                            
                            if choice.finish_reason != nil {
                                continuation.finish()
                                return
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    logger.error("Stream error: \(error)")
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    /// 会話コンテキストをリセット
    public func reset() async {
        await engine.reset()
    }
    
    /// 現在のモデルをアンロード
    public func unload() async {
        await engine.unload()
        isLoaded = false
    }
    
    // MARK: - Private Methods
    
    private func ensureModelAvailable(_ model: Model) async throws -> String {
        // 開発用：ローカルのmlc_llmキャッシュをチェック
        #if DEBUG
        let mlcCachePath = "/Users/majimadaisuke/.cache/mlc_llm/model_weights/hf/mlc-ai/\(model.rawValue)"
        if FileManager.default.fileExists(atPath: mlcCachePath) {
            logger.info("Using local MLC cache model at: \(mlcCachePath)")
            return mlcCachePath
        }
        #endif
        
        // バンドルモデルをチェック
        let bundleURL = Bundle.main.bundleURL.appendingPathComponent("bundle")
        let modelURL = bundleURL.appendingPathComponent(model.rawValue)
        
        if FileManager.default.fileExists(atPath: modelURL.path) {
            logger.info("Using bundled model at: \(modelURL.path)")
            return modelURL.path
        }
        
        // キャッシュをチェック
        let cacheURL = try getCacheDirectory().appendingPathComponent(model.rawValue)
        
        if FileManager.default.fileExists(atPath: cacheURL.path) {
            logger.info("Using cached model at: \(cacheURL.path)")
            return cacheURL.path
        }
        
        // モデルをダウンロード
        if let downloadURL = model.huggingFaceURL {
            logger.info("Model not found locally, downloading from: \(downloadURL)")
            return try await downloadModel(model: model, from: downloadURL, to: cacheURL)
        }
        
        throw EdgeLLMError.modelNotFound(model.rawValue)
    }
    
    private func getCacheDirectory() throws -> URL {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let edgeLLMCache = cacheDir.appendingPathComponent("EdgeLLM")
        
        if !FileManager.default.fileExists(atPath: edgeLLMCache.path) {
            try FileManager.default.createDirectory(at: edgeLLMCache, withIntermediateDirectories: true)
        }
        
        return edgeLLMCache
    }
    
    private func downloadModel(model: Model, from urlString: String, to destination: URL) async throws -> String {
        logger.info("Starting model download from: \(urlString)")
        
        // Create temporary directory for download
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Download model files
        let modelFiles = [
            "mlc-chat-config.json",
            "ndarray-cache.json",
            "params_shard_0.bin",
            "tokenizer.json"
        ]
        
        for file in modelFiles {
            let fileURL = URL(string: urlString)!.appendingPathComponent("resolve/main/\(file)")
            let tempFile = tempDir.appendingPathComponent(file)
            
            logger.info("Downloading: \(file)")
            
            let (data, response) = try await URLSession.shared.data(from: fileURL)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw EdgeLLMError.downloadFailed("Failed to download \(file)")
            }
            
            try data.write(to: tempFile)
        }
        
        // Move to destination
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        
        for file in modelFiles {
            let sourceFile = tempDir.appendingPathComponent(file)
            let destFile = destination.appendingPathComponent(file)
            try FileManager.default.moveItem(at: sourceFile, to: destFile)
        }
        
        logger.info("Model downloaded successfully to: \(destination.path)")
        return destination.path
    }
    
    private func loadModel(modelPath: String, modelLib: String) async throws {
        logger.info("Loading model from: \(modelPath)")
        
        await engine.reload(modelPath: modelPath, modelLib: modelLib)
        isLoaded = true
        
        logger.info("Model loaded successfully")
    }
}

// MARK: - Static Methods

extension EdgeLLM {
    /// ワンライナーでチャット（モデルは自動的に管理される）
    /// - Parameters:
    ///   - prompt: ユーザーのメッセージ
    ///   - model: 使用するモデル（デフォルト: .llama3_2）
    ///   - options: 生成オプション
    /// - Returns: モデルの完全なレスポンス
    public static func chat(
        _ prompt: String,
        model: Model = .gemma2b,
        options: Options = .default
    ) async throws -> String {
        let llm = try await EdgeLLM(model: model, options: options)
        return try await llm.chat(prompt)
    }
    
    /// ワンライナーでストリーミングチャット
    /// - Parameters:
    ///   - prompt: ユーザーのメッセージ
    ///   - model: 使用するモデル
    ///   - options: 生成オプション
    /// - Returns: トークンの非同期ストリーム
    public static func stream(
        _ prompt: String,
        model: Model = .gemma2b,
        options: Options = .default
    ) async throws -> AsyncThrowingStream<String, Error> {
        let llm = try await EdgeLLM(model: model, options: options)
        return await llm.stream(prompt)
    }
}

// MARK: - Download Progress

public struct DownloadProgress {
    public let bytesWritten: Int64
    public let totalBytes: Int64
    public let fileName: String
    
    public var progress: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(bytesWritten) / Double(totalBytes)
    }
    
    public var progressPercentage: Int {
        Int(progress * 100)
    }
}

// MARK: - Errors

public enum EdgeLLMError: LocalizedError {
    case modelNotFound(String)
    case modelNotLoaded
    case downloadFailed(String)
    case downloadNotImplemented
    case invalidURL(String)
    case checksumMismatch(expected: String, actual: String)
    case extractionFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .modelNotFound(let model):
            return "Model '\(model)' not found"
        case .modelNotLoaded:
            return "No model is currently loaded"
        case .downloadFailed(let reason):
            return "Model download failed: \(reason)"
        case .downloadNotImplemented:
            return "Model download is not yet implemented"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .checksumMismatch(let expected, let actual):
            return "Checksum mismatch: expected \(expected), got \(actual)"
        case .extractionFailed(let message):
            return "Extraction failed: \(message)"
        }
    }
}