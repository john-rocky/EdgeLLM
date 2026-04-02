import Foundation
import os

/// EdgeLLM - Simple on-device LLM API library
///
/// Usage:
/// ```swift
/// let llm = try await EdgeLLM(model: .gemma2b)
/// let response = try await llm.chat("Hello, world!")
/// print(response)
/// ```

// Force static library initialization at import time
@available(iOS 14.0, macOS 11.0, *)
public enum EdgeLLMRuntime {
    static let forceInit: Void = {
        _ = MLCEngine()
        return ()
    }()
}

@available(iOS 14.0, macOS 11.0, *)
public actor EdgeLLM {

    // MARK: - Public Types

    /// Model size category
    public enum ModelCategory: String, CaseIterable, Sendable {
        case tiny    // < 1GB, runs on any device
        case small   // 1-3GB, iPhone 12+
        case medium  // 3-5GB, iPhone 14 Pro+
    }

    /// Supported models
    public enum Model: String, CaseIterable, Sendable {
        // Tiny models (< 1GB)
        case qwen06b = "Qwen3-0.6B-q0f16-MLC"

        // Small models (1-3GB)
        case gemma2b = "gemma-2-2b-it-q4f16_1-MLC"

        // Medium models (3-5GB)
        case phi3_mini = "Phi-3.5-mini-instruct-q4f16_1-MLC"

        var modelLib: String {
            switch self {
            case .qwen06b:
                return "qwen3_q0f16_e63d9b1954017ab989b2bde1896a12e2"
            case .gemma2b:
                return "gemma2_q4f16_1_779a95d4ef785ea159992d38fac2317f"
            case .phi3_mini:
                return "phi3_q4f16_1_eba3d93dab5930b68f7296c1fd0d29ec"
            }
        }

        /// Display name for UI
        public var displayName: String {
            switch self {
            case .qwen06b:
                return "Qwen 0.6B"
            case .gemma2b:
                return "Gemma 2B"
            case .phi3_mini:
                return "Phi-3.5 Mini"
            }
        }

        /// Approximate download size in bytes
        public var approximateSize: Int64 {
            switch self {
            case .qwen06b:    return 1_200_000_000
            case .gemma2b:    return 2_500_000_000
            case .phi3_mini:  return 3_800_000_000
            }
        }

        /// Size category for device compatibility
        public var category: ModelCategory {
            switch self {
            case .qwen06b:    return .tiny
            case .gemma2b:    return .small
            case .phi3_mini:  return .medium
            }
        }

        /// Formatted download size string (e.g. "1.2 GB")
        public var sizeDescription: String {
            let gb = Double(approximateSize) / 1_000_000_000
            return String(format: "%.1f GB", gb)
        }

        var huggingFaceURL: String? {
            switch self {
            case .qwen06b:
                return "https://huggingface.co/mlc-ai/Qwen3-0.6B-q0f16-MLC"
            case .gemma2b:
                return "https://huggingface.co/mlc-ai/gemma-2-2b-it-q4f16_1-MLC"
            case .phi3_mini:
                return "https://huggingface.co/mlc-ai/Phi-3.5-mini-instruct-q4f16_1-MLC"
            }
        }
    }

    /// Generation options
    public struct Options: Sendable {
        public var temperature: Float
        public var maxTokens: Int
        public var topP: Float
        public var systemPrompt: String?
        public var frequencyPenalty: Float?
        public var presencePenalty: Float?
        public var stopSequences: [String]?

        public static let `default` = Options()

        public init(
            temperature: Float = 0.7,
            maxTokens: Int = 2048,
            topP: Float = 0.95,
            systemPrompt: String? = nil,
            frequencyPenalty: Float? = nil,
            presencePenalty: Float? = nil,
            stopSequences: [String]? = nil
        ) {
            self.temperature = temperature
            self.maxTokens = maxTokens
            self.topP = topP
            self.systemPrompt = systemPrompt
            self.frequencyPenalty = frequencyPenalty
            self.presencePenalty = presencePenalty
            self.stopSequences = stopSequences
        }
    }

    /// Custom model configuration for models not in the built-in catalog.
    /// Requires a compatible MLCRuntime binary that includes the model library.
    public struct ModelConfig: Sendable {
        /// Display name
        public let name: String
        /// Model library identifier (compiled into MLCRuntime)
        public let modelLib: String
        /// HuggingFace model repository URL
        public let huggingFaceURL: String
        /// Approximate download size in bytes
        public let approximateSize: Int64

        public init(name: String, modelLib: String, huggingFaceURL: String, approximateSize: Int64 = 0) {
            self.name = name
            self.modelLib = modelLib
            self.huggingFaceURL = huggingFaceURL
            self.approximateSize = approximateSize
        }
    }

    /// Information about a cached model
    public struct CachedModel: Sendable {
        public let model: Model
        public let path: URL
        public let sizeBytes: Int64
    }

    // MARK: - Properties

    private let engine = MLCEngine()
    private let model: Model
    private var options: Options
    private var isLoaded = false
    private let logger = Logger(subsystem: "ai.edge.llm", category: "EdgeLLM")

    // Custom model storage
    private let customModelLib: String?
    private let customModelName: String?

    #if DEBUG
    /// Override model paths during development
    public static var debugModelPathOverride: ((Model) -> String?)? = nil
    #endif

    // MARK: - Initialization

    /// Initialize EdgeLLM with a built-in model
    /// - Parameters:
    ///   - model: Model to use
    ///   - options: Generation options
    public init(model: Model = .gemma2b, options: Options = .default) async throws {
        _ = EdgeLLMRuntime.forceInit

        self.model = model
        self.options = options
        self.customModelLib = nil
        self.customModelName = nil

        logger.info("Initializing EdgeLLM with model: \(model.displayName)")

        let modelPath = try await ensureModelAvailable(model)
        try await loadModel(modelPath: modelPath, modelLib: model.modelLib)
    }

    /// Initialize EdgeLLM with a custom model configuration.
    /// Use this when you have built a custom MLCRuntime with additional model support.
    /// - Parameters:
    ///   - config: Custom model configuration
    ///   - options: Generation options
    public init(config: ModelConfig, options: Options = .default) async throws {
        _ = EdgeLLMRuntime.forceInit

        // Use qwen06b as placeholder for the enum (custom model uses its own config)
        self.model = .qwen06b
        self.options = options
        self.customModelLib = config.modelLib
        self.customModelName = config.name

        logger.info("Initializing EdgeLLM with custom model: \(config.name)")

        let cacheURL = try Self.getCacheDirectory().appendingPathComponent(
            config.huggingFaceURL
                .replacingOccurrences(of: "https://huggingface.co/", with: "")
                .replacingOccurrences(of: "/", with: "_")
        )

        let modelPath: String
        if FileManager.default.fileExists(atPath: cacheURL.path) {
            modelPath = cacheURL.path
        } else {
            modelPath = try await Self.downloadModelStatic(
                model: .qwen06b, from: config.huggingFaceURL, to: cacheURL, onProgress: nil
            )
        }

        try await loadModel(modelPath: modelPath, modelLib: config.modelLib)
    }

    // MARK: - Public Methods

    /// Send a chat message and get a complete response
    /// - Parameter prompt: User message
    /// - Returns: Complete model response
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

    /// Send a message within a conversation and get a complete response
    /// - Parameters:
    ///   - prompt: User message
    ///   - conversation: Conversation to continue
    /// - Returns: Complete model response
    public func chat(_ prompt: String, in conversation: Conversation) async throws -> String {
        guard isLoaded else {
            throw EdgeLLMError.modelNotLoaded
        }

        conversation.append(prompt, role: .user)
        var fullResponse = ""

        for try await token in streamMessages(conversation.asChatMessages) {
            fullResponse += token
        }

        conversation.append(fullResponse, role: .assistant)
        return fullResponse
    }

    /// Stream chat response token by token
    /// - Parameter prompt: User message
    /// - Returns: Async stream of tokens
    public func stream(_ prompt: String) -> AsyncThrowingStream<String, Error> {
        var messages: [ChatCompletionMessage] = []
        if let systemPrompt = self.options.systemPrompt {
            messages.append(ChatCompletionMessage(role: .system, content: systemPrompt))
        }
        messages.append(ChatCompletionMessage(role: .user, content: prompt))
        return streamMessages(messages)
    }

    /// Stream a response within a conversation
    /// - Parameters:
    ///   - prompt: User message
    ///   - conversation: Conversation to continue
    /// - Returns: Async stream of tokens (assistant message is appended on completion)
    public func stream(_ prompt: String, in conversation: Conversation) -> AsyncThrowingStream<String, Error> {
        conversation.append(prompt, role: .user)
        let messages = conversation.asChatMessages
        var accumulated = ""

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await token in self.streamMessages(messages) {
                        try Task.checkCancellation()
                        accumulated += token
                        continuation.yield(token)
                    }
                    conversation.append(accumulated, role: .assistant)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Update generation options without reloading the model
    public func updateOptions(_ newOptions: Options) {
        self.options = newOptions
    }

    /// Reset conversation context
    public func reset() async {
        await engine.reset()
    }

    /// Unload the current model
    public func unload() async {
        await engine.unload()
        isLoaded = false
    }

    /// Cancel any in-progress generation
    public func cancel() async {
        await engine.reset()
    }

    // MARK: - Private Methods

    func streamMessages(_ messages: [ChatCompletionMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                guard self.isLoaded else {
                    continuation.finish(throwing: EdgeLLMError.modelNotLoaded)
                    return
                }

                do {
                    for try await response in await self.engine.chat.completions.create(
                        messages: messages,
                        model: self.model.rawValue,
                        frequency_penalty: self.options.frequencyPenalty,
                        presence_penalty: self.options.presencePenalty,
                        max_tokens: self.options.maxTokens,
                        stop: self.options.stopSequences,
                        stream_options: StreamOptions(include_usage: true),
                        temperature: self.options.temperature,
                        top_p: self.options.topP
                    ) {
                        try Task.checkCancellation()
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
                    self.logger.error("Stream error: \(error)")
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func ensureModelAvailable(_ model: Model) async throws -> String {
        // Check for local MLC cache (for development)
        #if DEBUG
        if let override = Self.debugModelPathOverride?(model) {
            if FileManager.default.fileExists(atPath: override) {
                logger.info("Using debug override model at: \(override)")
                return override
            }
        }
        #endif

        // Check bundled models
        let bundleURL = Bundle.main.bundleURL.appendingPathComponent("bundle")
        let modelURL = bundleURL.appendingPathComponent(model.rawValue)

        if FileManager.default.fileExists(atPath: modelURL.path) {
            logger.info("Using bundled model at: \(modelURL.path)")
            return modelURL.path
        }

        // Check cache
        let cacheURL = try Self.getCacheDirectory().appendingPathComponent(model.rawValue)

        if FileManager.default.fileExists(atPath: cacheURL.path) {
            logger.info("Using cached model at: \(cacheURL.path)")
            return cacheURL.path
        }

        // Download model
        if let downloadURL = model.huggingFaceURL {
            logger.info("Model not found locally, downloading from: \(downloadURL)")
            return try await downloadModel(model: model, from: downloadURL, to: cacheURL, onProgress: nil)
        }

        throw EdgeLLMError.modelNotFound(model.rawValue)
    }

    static func getCacheDirectory() throws -> URL {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let edgeLLMCache = cacheDir.appendingPathComponent("EdgeLLM")

        if !FileManager.default.fileExists(atPath: edgeLLMCache.path) {
            try FileManager.default.createDirectory(at: edgeLLMCache, withIntermediateDirectories: true)
        }

        return edgeLLMCache
    }

    private func downloadModel(
        model: Model,
        from urlString: String,
        to destination: URL,
        onProgress: ((DownloadProgress) -> Void)?
    ) async throws -> String {
        return try await Self.downloadModelStatic(model: model, from: urlString, to: destination, onProgress: onProgress)
    }

    private static func downloadModelStatic(
        model: Model,
        from urlString: String,
        to destination: URL,
        onProgress: ((DownloadProgress) -> Void)?
    ) async throws -> String {
        let logger = Logger(subsystem: "ai.edge.llm", category: "EdgeLLM")
        logger.info("Starting model download from: \(urlString)")

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let baseFiles = [
            "mlc-chat-config.json",
            "ndarray-cache.json",
            "tokenizer.json"
        ]

        var downloadedFiles: [String] = []

        for file in baseFiles {
            let fileURL = URL(string: urlString)!.appendingPathComponent("resolve/main/\(file)")
            let tempFile = tempDir.appendingPathComponent(file)

            logger.info("Downloading: \(file)")

            let (data, response) = try await URLSession.shared.data(from: fileURL)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw EdgeLLMError.downloadFailed("Failed to download required file: \(file)")
            }

            try data.write(to: tempFile)
            downloadedFiles.append(file)
        }

        // Parse ndarray-cache.json to determine shard files
        let ndarrayPath = tempDir.appendingPathComponent("ndarray-cache.json")
        let ndarrayData = try Data(contentsOf: ndarrayPath)

        guard let ndarrayJson = try JSONSerialization.jsonObject(with: ndarrayData) as? [String: Any] else {
            throw EdgeLLMError.downloadFailed("Invalid ndarray-cache.json format")
        }

        var shardFiles = Set<String>()

        if let records = ndarrayJson["records"] as? [[String: Any]] {
            for record in records {
                if let dataPath = record["dataPath"] as? String {
                    shardFiles.insert(dataPath)
                }
            }
        }

        if shardFiles.isEmpty {
            if let _ = try? await downloadOptionalFileStatic(from: urlString, filename: "params.bin", to: tempDir) {
                downloadedFiles.append("params.bin")
            } else {
                var shardIndex = 0
                while shardIndex < 50 {
                    let shardFile = "params_shard_\(shardIndex).bin"
                    if let _ = try? await downloadOptionalFileStatic(from: urlString, filename: shardFile, to: tempDir) {
                        downloadedFiles.append(shardFile)
                        shardIndex += 1
                    } else {
                        break
                    }
                }
            }
        } else {
            let sortedShards = shardFiles.sorted()
            let totalFiles = sortedShards.count + baseFiles.count

            for (index, shardFile) in sortedShards.enumerated() {
                let fileURL = URL(string: urlString)!.appendingPathComponent("resolve/main/\(shardFile)")
                let tempFile = tempDir.appendingPathComponent(shardFile)

                let (data, response) = try await URLSession.shared.data(from: fileURL)

                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw EdgeLLMError.downloadFailed("Failed to download shard file: \(shardFile)")
                }

                try data.write(to: tempFile)
                downloadedFiles.append(shardFile)

                onProgress?(DownloadProgress(
                    bytesWritten: Int64(data.count),
                    totalBytes: model.approximateSize,
                    fileName: shardFile,
                    fileIndex: baseFiles.count + index + 1,
                    totalFiles: totalFiles
                ))
            }
        }

        guard downloadedFiles.count > baseFiles.count else {
            throw EdgeLLMError.downloadFailed("No model weight files found")
        }

        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)

        for file in downloadedFiles {
            let sourceFile = tempDir.appendingPathComponent(file)
            let destFile = destination.appendingPathComponent(file)
            try FileManager.default.moveItem(at: sourceFile, to: destFile)
        }

        logger.info("Model downloaded successfully to: \(destination.path)")
        return destination.path
    }

    private static func downloadOptionalFileStatic(from baseURL: String, filename: String, to tempDir: URL) async throws -> Data? {
        let fileURL = URL(string: baseURL)!.appendingPathComponent("resolve/main/\(filename)")

        do {
            let (data, response) = try await URLSession.shared.data(from: fileURL)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }

            let tempFile = tempDir.appendingPathComponent(filename)
            try data.write(to: tempFile)
            return data
        } catch {
            return nil
        }
    }

    private func loadModel(modelPath: String, modelLib: String) async throws {
        logger.info("Loading model from: \(modelPath)")

        await MainActor.run {
            logger.info("Loading model on main thread")
        }

        logger.info("Calling engine.reload with modelLib: \(modelLib)")
        await engine.reload(modelPath: modelPath, modelLib: modelLib)
        isLoaded = true

        logger.info("Model loaded successfully with lib: \(modelLib)")
    }
}

// MARK: - Static Convenience Methods

@available(iOS 14.0, macOS 11.0, *)
extension EdgeLLM {

    /// One-liner chat (model is automatically managed)
    public static func chat(
        _ prompt: String,
        systemPrompt: String? = nil,
        model: Model = .gemma2b,
        options: Options = .default
    ) async throws -> String {
        _ = EdgeLLMRuntime.forceInit

        var opts = options
        if let sp = systemPrompt { opts.systemPrompt = sp }
        let llm = try await EdgeLLM(model: model, options: opts)
        return try await llm.chat(prompt)
    }

    /// One-liner streaming chat
    public static func stream(
        _ prompt: String,
        systemPrompt: String? = nil,
        model: Model = .gemma2b,
        options: Options = .default
    ) async throws -> AsyncThrowingStream<String, Error> {
        _ = EdgeLLMRuntime.forceInit

        var opts = options
        if let sp = systemPrompt { opts.systemPrompt = sp }
        let llm = try await EdgeLLM(model: model, options: opts)
        return await llm.stream(prompt)
    }
}

// MARK: - Download & Model Management

@available(iOS 14.0, macOS 11.0, *)
extension EdgeLLM {

    /// Download a model with progress tracking (does not load it)
    public static func download(
        _ model: Model,
        onProgress: @escaping @Sendable (DownloadProgress) -> Void = { _ in }
    ) async throws {
        if isDownloaded(model) { return }

        let cacheURL = try getCacheDirectory().appendingPathComponent(model.rawValue)
        guard let urlString = model.huggingFaceURL else {
            throw EdgeLLMError.modelNotFound(model.rawValue)
        }

        _ = try await downloadModelStatic(model: model, from: urlString, to: cacheURL, onProgress: onProgress)
    }

    /// Check if a model is already downloaded
    public static func isDownloaded(_ model: Model) -> Bool {
        guard let cacheDir = try? getCacheDirectory() else { return false }
        let modelDir = cacheDir.appendingPathComponent(model.rawValue)
        let configPath = modelDir.appendingPathComponent("mlc-chat-config.json")
        return FileManager.default.fileExists(atPath: configPath.path)
    }

    /// List all downloaded models
    public static func downloadedModels() -> [CachedModel] {
        guard let cacheDir = try? getCacheDirectory() else { return [] }
        var results: [CachedModel] = []

        for model in Model.allCases {
            let modelDir = cacheDir.appendingPathComponent(model.rawValue)
            if FileManager.default.fileExists(atPath: modelDir.path) {
                let size = Self.directorySize(at: modelDir)
                results.append(CachedModel(model: model, path: modelDir, sizeBytes: size))
            }
        }
        return results
    }

    /// Delete a cached model
    public static func deleteModel(_ model: Model) throws {
        let cacheDir = try getCacheDirectory()
        let modelDir = cacheDir.appendingPathComponent(model.rawValue)
        if FileManager.default.fileExists(atPath: modelDir.path) {
            try FileManager.default.removeItem(at: modelDir)
        }
    }

    /// Delete all cached models
    public static func deleteAllModels() throws {
        for model in Model.allCases {
            try deleteModel(model)
        }
    }

    /// Total cache size in bytes
    public static func totalCacheSize() -> Int64 {
        guard let cacheDir = try? getCacheDirectory() else { return 0 }
        return directorySize(at: cacheDir)
    }

    /// Available disk space in bytes
    public static func availableDiskSpace() -> Int64 {
        guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let free = attrs[.systemFreeSize] as? Int64 else {
            return 0
        }
        return free
    }

    private static func directorySize(at url: URL) -> Int64 {
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += Int64(size)
            }
        }
        return total
    }
}

// MARK: - Download Progress

@available(iOS 14.0, macOS 11.0, *)
public struct DownloadProgress: Sendable {
    public let bytesWritten: Int64
    public let totalBytes: Int64
    public let fileName: String
    public let fileIndex: Int
    public let totalFiles: Int

    public var progress: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(bytesWritten) / Double(totalBytes)
    }

    public var progressPercentage: Int {
        Int(progress * 100)
    }

    /// e.g. "Downloading params_shard_2.bin (3/8)"
    public var statusDescription: String {
        "Downloading \(fileName) (\(fileIndex)/\(totalFiles))"
    }
}

// MARK: - Errors

@available(iOS 14.0, macOS 11.0, *)
public enum EdgeLLMError: LocalizedError, Sendable {
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
