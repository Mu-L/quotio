//
//  CLIProxyManager.swift
//  Quotio - CLIProxyAPI GUI Wrapper
//

import Foundation
import AppKit

@MainActor
@Observable
final class CLIProxyManager {
    private var process: Process?
    private(set) var proxyStatus = ProxyStatus()
    private(set) var isStarting = false
    private(set) var isDownloading = false
    private(set) var downloadProgress: Double = 0
    private(set) var lastError: String?
    
    let binaryPath: String
    let configPath: String
    let authDir: String
    let managementKey: String
    
    var port: UInt16 {
        get { proxyStatus.port }
        set {
            proxyStatus.port = newValue
            UserDefaults.standard.set(Int(newValue), forKey: "proxyPort")
            updateConfigPort(newValue)
        }
    }
    
    private static let githubRepo = "router-for-me/CLIProxyAPI"
    private static let binaryName = "CLIProxyAPI"
    
    var baseURL: String {
        "http://127.0.0.1:\(proxyStatus.port)"
    }
    
    var managementURL: String {
        "\(baseURL)/v0/management"
    }
    
    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let quotioDir = appSupport.appendingPathComponent("Quotio")
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        
        try? FileManager.default.createDirectory(at: quotioDir, withIntermediateDirectories: true)
        
        self.binaryPath = quotioDir.appendingPathComponent("CLIProxyAPI").path
        self.configPath = quotioDir.appendingPathComponent("config.yaml").path
        self.authDir = homeDir.appendingPathComponent(".cli-proxy-api").path
        
        // Always use key from UserDefaults, generate new if not exists
        // Never read from config because CLIProxyAPI hashes the key on startup
        if let savedKey = UserDefaults.standard.string(forKey: "managementKey"), !savedKey.hasPrefix("$2a$") {
            self.managementKey = savedKey
        } else {
            self.managementKey = UUID().uuidString
            UserDefaults.standard.set(managementKey, forKey: "managementKey")
        }
        
        let savedPort = UserDefaults.standard.integer(forKey: "proxyPort")
        if savedPort > 0 && savedPort < 65536 {
            self.proxyStatus.port = UInt16(savedPort)
        }
        
        try? FileManager.default.createDirectory(atPath: authDir, withIntermediateDirectories: true)
        
        ensureConfigExists()
    }
    
    private func updateConfigPort(_ newPort: UInt16) {
        guard FileManager.default.fileExists(atPath: configPath),
              var content = try? String(contentsOfFile: configPath, encoding: .utf8) else { return }
        
        if let range = content.range(of: #"port:\s*\d+"#, options: .regularExpression) {
            content.replaceSubrange(range, with: "port: \(newPort)")
            try? content.write(toFile: configPath, atomically: true, encoding: .utf8)
        }
    }
    
    private func ensureConfigExists() {
        guard !FileManager.default.fileExists(atPath: configPath) else { return }
        
        let defaultConfig = """
        host: "127.0.0.1"
        port: \(proxyStatus.port)
        auth-dir: "\(authDir)"
        
        api-keys:
          - "quotio-local-\(UUID().uuidString.prefix(8))"
        
        remote-management:
          allow-remote: false
          secret-key: "\(managementKey)"
        
        debug: false
        logging-to-file: false
        usage-statistics-enabled: true
        
        routing:
          strategy: "round-robin"
        
        quota-exceeded:
          switch-project: true
          switch-preview-model: true
        
        request-retry: 3
        max-retry-interval: 30
        """
        
        try? defaultConfig.write(toFile: configPath, atomically: true, encoding: .utf8)
    }
    
    private func syncSecretKeyInConfig() {
        guard FileManager.default.fileExists(atPath: configPath),
              var content = try? String(contentsOfFile: configPath, encoding: .utf8) else { return }
        
        if let range = content.range(of: #"secret-key:\s*\".*\""#, options: .regularExpression) {
            content.replaceSubrange(range, with: "secret-key: \"\(managementKey)\"")
            try? content.write(toFile: configPath, atomically: true, encoding: .utf8)
        } else if let range = content.range(of: #"secret-key:\s*[^\n]+"#, options: .regularExpression) {
            content.replaceSubrange(range, with: "secret-key: \"\(managementKey)\"")
            try? content.write(toFile: configPath, atomically: true, encoding: .utf8)
        }
    }
    
    var isBinaryInstalled: Bool {
        FileManager.default.fileExists(atPath: binaryPath)
    }
    
    func downloadAndInstallBinary() async throws {
        isDownloading = true
        downloadProgress = 0
        lastError = nil
        
        defer { isDownloading = false }
        
        do {
            let releaseInfo = try await fetchLatestRelease()
            guard let asset = findCompatibleAsset(in: releaseInfo) else {
                throw ProxyError.noCompatibleBinary
            }
            
            downloadProgress = 0.1
            
            let binaryData = try await downloadAsset(url: asset.downloadURL)
            downloadProgress = 0.7
            
            try await extractAndInstall(data: binaryData, assetName: asset.name)
            downloadProgress = 1.0
            
        } catch {
            lastError = error.localizedDescription
            throw error
        }
    }
    
    private struct ReleaseInfo: Codable {
        let tagName: String
        let assets: [AssetInfo]
        
        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case assets
        }
    }
    
    private struct AssetInfo: Codable {
        let name: String
        let browserDownloadUrl: String
        
        enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadUrl = "browser_download_url"
        }
        
        var downloadURL: String { browserDownloadUrl }
    }
    
    private struct CompatibleAsset {
        let name: String
        let downloadURL: String
    }
    
    private func fetchLatestRelease() async throws -> ReleaseInfo {
        let urlString = "https://api.github.com/repos/router-for-me/CLIProxyAPI/releases/latest"
        guard let url = URL(string: urlString) else {
            throw ProxyError.networkError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.addValue("Quotio/1.0", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ProxyError.networkError("Failed to fetch release info")
        }
        
        return try JSONDecoder().decode(ReleaseInfo.self, from: data)
    }
    
    private func findCompatibleAsset(in release: ReleaseInfo) -> CompatibleAsset? {
        #if arch(arm64)
        let arch = "arm64"
        #else
        let arch = "amd64"
        #endif
        
        let platform = "darwin"
        let targetPattern = "\(platform)_\(arch)"
        let skipPatterns = ["windows", "linux", "checksum"]
        
        for asset in release.assets {
            let lowercaseName = asset.name.lowercased()
            
            let shouldSkip = skipPatterns.contains { lowercaseName.contains($0) }
            if shouldSkip { continue }
            
            if lowercaseName.contains(targetPattern) {
                return CompatibleAsset(name: asset.name, downloadURL: asset.browserDownloadUrl)
            }
        }
        
        return nil
    }
    
    private func downloadAsset(url: String) async throws -> Data {
        guard let downloadURL = URL(string: url) else {
            throw ProxyError.networkError("Invalid download URL")
        }
        
        var request = URLRequest(url: downloadURL)
        request.addValue("Quotio/1.0", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ProxyError.networkError("Failed to download binary")
        }
        
        return data
    }
    
    private func extractAndInstall(data: Data, assetName: String) async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        let downloadedFile = tempDir.appendingPathComponent(assetName)
        try data.write(to: downloadedFile)
        
        let binaryURL = URL(fileURLWithPath: binaryPath)
        
        if assetName.hasSuffix(".tar.gz") || assetName.hasSuffix(".tgz") {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
            process.arguments = ["-xzf", downloadedFile.path, "-C", tempDir.path]
            try process.run()
            process.waitUntilExit()
            
            if let binary = try findBinaryInDirectory(tempDir) {
                if FileManager.default.fileExists(atPath: binaryPath) {
                    try FileManager.default.removeItem(atPath: binaryPath)
                }
                try FileManager.default.copyItem(at: binary, to: binaryURL)
            } else {
                throw ProxyError.extractionFailed
            }
            
        } else if assetName.hasSuffix(".zip") {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
            process.arguments = ["-o", downloadedFile.path, "-d", tempDir.path]
            try process.run()
            process.waitUntilExit()
            
            if let binary = try findBinaryInDirectory(tempDir) {
                if FileManager.default.fileExists(atPath: binaryPath) {
                    try FileManager.default.removeItem(atPath: binaryPath)
                }
                try FileManager.default.copyItem(at: binary, to: binaryURL)
            } else {
                throw ProxyError.extractionFailed
            }
            
        } else {
            if FileManager.default.fileExists(atPath: binaryPath) {
                try FileManager.default.removeItem(atPath: binaryPath)
            }
            try FileManager.default.copyItem(at: downloadedFile, to: binaryURL)
        }
        
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: binaryPath)
    }
    
    private func findBinaryInDirectory(_ directory: URL) throws -> URL? {
        let contents = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isExecutableKey, .isRegularFileKey])
        
        let binaryNames = ["CLIProxyAPI", "cli-proxy-api", "claude-code-proxy", "proxy"]
        
        for name in binaryNames {
            if let found = contents.first(where: { $0.lastPathComponent.lowercased() == name.lowercased() }) {
                return found
            }
        }
        
        for item in contents {
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: item.path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    if let found = try findBinaryInDirectory(item) {
                        return found
                    }
                } else {
                    let resourceValues = try item.resourceValues(forKeys: [.isExecutableKey])
                    if resourceValues.isExecutable == true {
                        let name = item.lastPathComponent.lowercased()
                        if !name.hasSuffix(".sh") && !name.hasSuffix(".txt") && !name.hasSuffix(".md") {
                            return item
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    func start() async throws {
        guard isBinaryInstalled else {
            throw ProxyError.binaryNotFound
        }
        
        guard !proxyStatus.running else { return }
        
        isStarting = true
        lastError = nil
        
        defer { isStarting = false }
        
        syncSecretKeyInConfig()
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: binaryPath)
        process.arguments = ["-config", configPath]
        process.currentDirectoryURL = URL(fileURLWithPath: binaryPath).deletingLastPathComponent()
        
        // Keep process output - prevents early termination
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // Important: Don't inherit environment that might cause issues
        var environment = ProcessInfo.processInfo.environment
        environment["TERM"] = "xterm-256color"
        process.environment = environment
        
        process.terminationHandler = { terminatedProcess in
            let status = terminatedProcess.terminationStatus
            Task { @MainActor [weak self] in
                self?.proxyStatus.running = false
                self?.process = nil
                if status != 0 {
                    self?.lastError = "Process exited with code: \(status)"
                    NotificationManager.shared.notifyProxyCrashed(exitCode: status)
                }
            }
        }
        
        do {
            try process.run()
            self.process = process
            
            try await Task.sleep(nanoseconds: 1_500_000_000)
            
            if process.isRunning {
                proxyStatus.running = true
            } else {
                throw ProxyError.startupFailed
            }
        } catch {
            lastError = error.localizedDescription
            throw error
        }
    }
    
    func stop() {
        process?.terminate()
        process?.waitUntilExit()
        process = nil
        proxyStatus.running = false
    }
    
    func toggle() async throws {
        if proxyStatus.running {
            stop()
        } else {
            try await start()
        }
    }
    
    func copyEndpointToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(proxyStatus.endpoint, forType: .string)
    }
    
    func revealInFinder() {
        NSWorkspace.shared.selectFile(binaryPath, inFileViewerRootedAtPath: (binaryPath as NSString).deletingLastPathComponent)
    }
}

enum ProxyError: LocalizedError {
    case binaryNotFound
    case startupFailed
    case networkError(String)
    case noCompatibleBinary
    case extractionFailed
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .binaryNotFound:
            return "CLIProxyAPI binary not found. Click 'Install' to download."
        case .startupFailed:
            return "Failed to start proxy server."
        case .networkError(let msg):
            return "Network error: \(msg)"
        case .noCompatibleBinary:
            return "No compatible binary found for your system."
        case .extractionFailed:
            return "Failed to extract binary from archive."
        case .downloadFailed:
            return "Failed to download binary."
        }
    }
}
