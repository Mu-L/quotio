//
//  DaemonProxyService.swift
//  Quotio
//

import Foundation

@MainActor @Observable
final class DaemonProxyService {
    static let shared = DaemonProxyService()
    
    private(set) var isRunning = false
    private(set) var isStarting = false
    private(set) var port: UInt16 = 8080
    private(set) var lastError: String?
    
    private let daemonManager = DaemonManager.shared
    private let ipcClient = DaemonIPCClient.shared
    private var healthCheckTask: Task<Void, Never>?
    
    private init() {
        let savedPort = UserDefaults.standard.integer(forKey: "proxyPort")
        if savedPort > 0 && savedPort < 65536 {
            port = UInt16(savedPort)
        }
    }
    
    var endpoint: String {
        "http://127.0.0.1:\(port)"
    }
    
    func start() async throws {
        guard !isRunning else { return }
        
        isStarting = true
        lastError = nil
        defer { isStarting = false }
        
        do {
            try await daemonManager.start()
            
            let result = try await ipcClient.startProxy(port: Int(port))
            
            if result.success {
                isRunning = true
                port = UInt16(result.port)
                startHealthMonitoring()
            } else {
                throw DaemonProxyError.startFailed
            }
        } catch {
            lastError = error.localizedDescription
            throw error
        }
    }
    
    func stop() async {
        healthCheckTask?.cancel()
        healthCheckTask = nil
        
        do {
            let result = try await ipcClient.stopProxy()
            if result.success {
                isRunning = false
            }
        } catch {
            isRunning = false
        }
    }
    
    func toggle() async throws {
        if isRunning {
            await stop()
        } else {
            try await start()
        }
    }
    
    func checkHealth() async -> Bool {
        do {
            let result = try await ipcClient.proxyHealth()
            return result.healthy
        } catch {
            return false
        }
    }
    
    func refreshStatus() async {
        do {
            let status = try await ipcClient.proxyStatus()
            isRunning = status.running
            if let statusPort = status.port {
                port = UInt16(statusPort)
            }
        } catch {
            isRunning = false
        }
    }
    
    private func startHealthMonitoring() {
        healthCheckTask?.cancel()
        healthCheckTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                
                if Task.isCancelled { break }
                
                let healthy = await self?.checkHealth() ?? false
                if !healthy {
                    await MainActor.run {
                        self?.isRunning = false
                        self?.lastError = "Proxy health check failed"
                    }
                }
            }
        }
    }
}

enum DaemonProxyError: LocalizedError {
    case startFailed
    case daemonNotRunning
    case connectionFailed
    
    var errorDescription: String? {
        switch self {
        case .startFailed:
            return "Failed to start proxy via daemon"
        case .daemonNotRunning:
            return "Daemon is not running"
        case .connectionFailed:
            return "Failed to connect to daemon"
        }
    }
}
