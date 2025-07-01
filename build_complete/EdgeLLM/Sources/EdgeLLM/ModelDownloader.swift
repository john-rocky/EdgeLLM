import Foundation
import os

@available(iOS 14.0, macOS 13.0, *)
public struct ModelDownloader {
    
    private let logger = Logger(subsystem: "ai.edge.llm", category: "ModelDownloader")
    
    // Model manifest structure
    public struct ModelManifest: Codable {
        let modelId: String
        let version: String
        let url: ModelURL
        let sha256: String
        let sizeBytes: Int64?
        
        struct ModelURL: Codable {
            let `default`: String
            let premium: String?
        }
    }
    
    // Download progress
    public struct DownloadProgress {
        public let bytesWritten: Int64
        public let totalBytes: Int64
        public var progress: Double {
            guard totalBytes > 0 else { return 0 }
            return Double(bytesWritten) / Double(totalBytes)
        }
    }
    
    // Model storage paths
    private var modelStorageURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("EdgeLLM", isDirectory: true)
    }
    
    private func modelDirectory(for sha256: String) -> URL {
        return modelStorageURL.appendingPathComponent(sha256, isDirectory: true)
    }
    
    // Check if model is already downloaded
    public func isModelReady(manifest: ModelManifest) -> Bool {
        let modelDir = modelDirectory(for: manifest.sha256)
        let configPath = modelDir.appendingPathComponent("mlc-chat-config.json")
        return FileManager.default.fileExists(atPath: configPath.path)
    }
    
    // Get local model path
    public func localModelPath(manifest: ModelManifest) -> URL? {
        guard isModelReady(manifest: manifest) else { return nil }
        return modelDirectory(for: manifest.sha256)
    }
    
    // Ensure model is ready (download if needed)
    public func ensureModelReady(
        manifest: ModelManifest,
        progressHandler: ((DownloadProgress) -> Void)? = nil
    ) async throws -> URL {
        
        // Check if already downloaded
        if let localPath = localModelPath(manifest: manifest) {
            logger.info("Model already downloaded at: \(localPath.path)")
            return localPath
        }
        
        logger.info("Downloading model: \(manifest.modelId)")
        
        // Create storage directory
        try FileManager.default.createDirectory(at: modelStorageURL, withIntermediateDirectories: true)
        
        // Download model
        let modelURL = try await downloadModel(manifest: manifest, progressHandler: progressHandler)
        
        logger.info("Model ready at: \(modelURL.path)")
        return modelURL
    }
    
    // Download model from URL
    private func downloadModel(
        manifest: ModelManifest,
        progressHandler: ((DownloadProgress) -> Void)?
    ) async throws -> URL {
        
        // Parse download URL
        let urlString = manifest.url.default
        guard let downloadURL = parseModelURL(urlString) else {
            throw EdgeLLMError.invalidURL(urlString)
        }
        
        logger.info("Downloading from: \(downloadURL)")
        
        // Create temporary directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Download file
        let downloadedFile = tempDir.appendingPathComponent("model.tar.zst")
        try await downloadFile(from: downloadURL, to: downloadedFile, progressHandler: progressHandler)
        
        // Verify checksum
        let checksum = try computeSHA256(for: downloadedFile)
        guard checksum == manifest.sha256 else {
            throw EdgeLLMError.checksumMismatch(expected: manifest.sha256, actual: checksum)
        }
        
        // Extract to final location
        let modelDir = modelDirectory(for: manifest.sha256)
        try extractTarZst(from: downloadedFile, to: modelDir)
        
        return modelDir
    }
    
    // Parse model URL (supports hf:// and https://)
    private func parseModelURL(_ urlString: String) -> URL? {
        if urlString.hasPrefix("hf://") {
            // Convert Hugging Face URL
            let path = String(urlString.dropFirst(5))
            return URL(string: "https://huggingface.co/\(path)/resolve/main/model.tar.zst")
        } else {
            return URL(string: urlString)
        }
    }
    
    // Download file with progress
    private func downloadFile(
        from url: URL,
        to destination: URL,
        progressHandler: ((DownloadProgress) -> Void)?
    ) async throws {
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw EdgeLLMError.downloadFailed("Invalid response")
        }
        
        try data.write(to: destination)
        
        if let contentLength = httpResponse.expectedContentLength {
            progressHandler?(DownloadProgress(
                bytesWritten: Int64(data.count),
                totalBytes: contentLength
            ))
        }
    }
    
    // Compute SHA256 checksum
    private func computeSHA256(for fileURL: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: fileURL)
        defer { handle.closeFile() }
        
        var hasher = SHA256()
        while autoreleasepool(invoking: {
            let chunk = handle.readData(ofLength: 1024 * 1024) // 1MB chunks
            guard !chunk.isEmpty else { return false }
            hasher.update(data: chunk)
            return true
        }) {}
        
        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    // Extract tar.zst file
    private func extractTarZst(from source: URL, to destination: URL) throws {
        // Create destination directory
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        
        // Use system commands to extract
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        task.arguments = ["-xf", source.path, "-C", destination.path]
        
        try task.run()
        task.waitUntilExit()
        
        guard task.terminationStatus == 0 else {
            throw EdgeLLMError.extractionFailed("tar extraction failed")
        }
    }
}

// SHA256 implementation (simplified)
import CryptoKit

@available(iOS 14.0, macOS 13.0, *)
extension ModelDownloader {
    struct SHA256 {
        private var hasher = CryptoKit.SHA256()
        
        mutating func update(data: Data) {
            hasher.update(data: data)
        }
        
        func finalize() -> SHA256.Digest {
            return hasher.finalize()
        }
    }
}

// EdgeLLM errors
public enum EdgeLLMError: LocalizedError {
    case invalidURL(String)
    case downloadFailed(String)
    case checksumMismatch(expected: String, actual: String)
    case extractionFailed(String)
    case modelNotFound(String)
    case modelNotLoaded
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .downloadFailed(let reason):
            return "Download failed: \(reason)"
        case .checksumMismatch(let expected, let actual):
            return "Checksum mismatch. Expected: \(expected), Actual: \(actual)"
        case .extractionFailed(let reason):
            return "Extraction failed: \(reason)"
        case .modelNotFound(let model):
            return "Model not found: \(model)"
        case .modelNotLoaded:
            return "Model not loaded"
        }
    }
}