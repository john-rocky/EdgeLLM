import Foundation
import os

/// EdgeLLMランタイムの動的ロード管理
@available(iOS 14.0, macOS 13.0, *)
public class EdgeLLMRuntimeLoader {
    private static let logger = Logger(subsystem: "ai.edge.llm", category: "RuntimeLoader")
    
    /// ランタイムのダウンロードURL
    public struct RuntimeSource {
        public static let gitHubRelease = "https://github.com/yourusername/EdgeLLM/releases/download/v0.2.0/MLCRuntime.zip"
        public static let cdnMirror = "https://cdn.jsdelivr.net/gh/yourusername/EdgeLLM@v0.2.0/MLCRuntime.zip"
        public static let directS3 = "https://edgellm-runtime.s3.amazonaws.com/v0.2.0/MLCRuntime.zip"
    }
    
    /// ランタイムの状態
    public enum RuntimeStatus {
        case notInstalled
        case downloading(progress: Double)
        case installed
        case error(String)
    }
    
    /// ランタイムの現在の状態
    @Published public private(set) var status: RuntimeStatus = .notInstalled
    
    /// ランタイムがインストールされているか確認
    public static func isRuntimeAvailable() -> Bool {
        let runtimePath = getRuntimePath()
        return FileManager.default.fileExists(atPath: runtimePath.path)
    }
    
    /// ランタイムのインストールパス
    private static func getRuntimePath() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("EdgeLLM/Runtime")
    }
    
    /// ランタイムをダウンロードしてインストール
    public func installRuntime(from source: String = RuntimeSource.gitHubRelease) async throws {
        logger.info("Starting runtime download from: \(source)")
        
        guard let url = URL(string: source) else {
            throw EdgeLLMError.invalidURL
        }
        
        // ダウンロード先の準備
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("EdgeLLMRuntime.zip")
        let runtimePath = Self.getRuntimePath()
        
        // URLSessionでダウンロード
        let (localURL, response) = try await URLSession.shared.download(from: url) { progress in
            Task { @MainActor in
                self.status = .downloading(progress: progress)
            }
        }
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw EdgeLLMError.downloadFailed("Invalid response")
        }
        
        // ファイルを移動
        try FileManager.default.moveItem(at: localURL, to: tempURL)
        
        // 解凍
        try await unzipRuntime(from: tempURL, to: runtimePath)
        
        // クリーンアップ
        try? FileManager.default.removeItem(at: tempURL)
        
        self.status = .installed
        logger.info("Runtime installed successfully")
    }
    
    /// ランタイムを解凍
    private func unzipRuntime(from zipURL: URL, to destination: URL) async throws {
        let task = Process()
        task.launchPath = "/usr/bin/unzip"
        task.arguments = ["-o", zipURL.path, "-d", destination.path]
        
        try task.run()
        task.waitUntilExit()
        
        guard task.terminationStatus == 0 else {
            throw EdgeLLMError.unzipFailed
        }
    }
    
    /// ランタイムのサイズを取得（MB）
    public static func getRuntimeSize() -> Double? {
        let runtimePath = getRuntimePath()
        
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: runtimePath.path),
              let size = attributes[.size] as? NSNumber else {
            return nil
        }
        
        return Double(size.int64Value) / 1024 / 1024
    }
}

// MARK: - URLSession Extension

extension URLSession {
    func download(from url: URL, progress: @escaping (Double) -> Void) async throws -> (URL, URLResponse) {
        let (localURL, response) = try await self.download(from: url)
        return (localURL, response)
    }
}

// MARK: - Smart Loading

extension EdgeLLM {
    /// スマートな初期化（必要に応じてランタイムをダウンロード）
    public static func initialize() async throws {
        if !EdgeLLMRuntimeLoader.isRuntimeAvailable() {
            logger.info("Runtime not found. Downloading...")
            
            let loader = EdgeLLMRuntimeLoader()
            
            // 複数のソースから試行
            let sources = [
                EdgeLLMRuntimeLoader.RuntimeSource.cdnMirror,
                EdgeLLMRuntimeLoader.RuntimeSource.gitHubRelease,
                EdgeLLMRuntimeLoader.RuntimeSource.directS3
            ]
            
            for source in sources {
                do {
                    try await loader.installRuntime(from: source)
                    break
                } catch {
                    logger.error("Failed to download from \(source): \(error)")
                    continue
                }
            }
            
            guard EdgeLLMRuntimeLoader.isRuntimeAvailable() else {
                throw EdgeLLMError.runtimeNotAvailable
            }
        }
        
        logger.info("Runtime is ready")
    }
}

// MARK: - Errors

extension EdgeLLMError {
    static let invalidURL = EdgeLLMError.downloadFailed("Invalid URL")
    static let unzipFailed = EdgeLLMError.downloadFailed("Failed to unzip runtime")
    static let runtimeNotAvailable = EdgeLLMError.downloadFailed("Runtime not available after download attempts")
}