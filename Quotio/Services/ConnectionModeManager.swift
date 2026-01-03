//
//  ConnectionModeManager.swift
//  Quotio - CLIProxyAPI GUI Wrapper
//
//  Manages connection mode (Local/Remote) and secure storage of remote credentials
//

import Foundation
import Security

// MARK: - Connection Mode Manager

/// Singleton manager for connection mode state and remote configuration
@MainActor
@Observable
final class ConnectionModeManager {
    static let shared = ConnectionModeManager()
    
    // MARK: - Observable State
    
    /// Current connection mode
    private(set) var connectionMode: ConnectionMode
    
    /// Current remote configuration (nil if local mode)
    private(set) var remoteConfig: RemoteConnectionConfig?
    
    /// Current connection status
    private(set) var connectionStatus: ConnectionStatus = .disconnected
    
    /// Last connection error message
    private(set) var lastError: String?
    
    // MARK: - Computed Properties
    
    /// Whether currently in remote mode
    var isRemoteMode: Bool { connectionMode == .remote }
    
    /// Whether currently in local mode
    var isLocalMode: Bool { connectionMode == .local }
    
    /// Whether a valid remote config exists
    var hasValidRemoteConfig: Bool {
        remoteConfig?.isValid == true
    }
    
    /// The management key for current remote config (from Keychain)
    var remoteManagementKey: String? {
        guard let config = remoteConfig else { return nil }
        return KeychainHelper.getManagementKey(for: config.id)
    }
    
    // MARK: - Initialization
    
    private init() {
        // Load connection mode from UserDefaults
        if let stored = UserDefaults.standard.string(forKey: "connectionMode"),
           let mode = ConnectionMode(rawValue: stored) {
            self.connectionMode = mode
        } else {
            self.connectionMode = .local
        }
        
        // Load remote config from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "remoteConnectionConfig"),
           let config = try? JSONDecoder().decode(RemoteConnectionConfig.self, from: data) {
            self.remoteConfig = config
        }
    }
    
    // MARK: - Mode Management
    
    /// Set connection mode
    func setMode(_ mode: ConnectionMode) {
        connectionMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: "connectionMode")
        
        // Reset connection status when switching modes
        connectionStatus = .disconnected
        lastError = nil
    }
    
    /// Switch to local mode
    func switchToLocal() {
        setMode(.local)
    }
    
    /// Switch to remote mode with configuration
    func switchToRemote(config: RemoteConnectionConfig, managementKey: String) {
        // Save config
        saveRemoteConfig(config)
        
        // Save management key to Keychain
        KeychainHelper.saveManagementKey(managementKey, for: config.id)
        
        // Switch mode
        setMode(.remote)
    }
    
    // MARK: - Remote Config Management
    
    /// Save remote configuration (without management key)
    func saveRemoteConfig(_ config: RemoteConnectionConfig) {
        remoteConfig = config
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: "remoteConnectionConfig")
        }
    }
    
    /// Update remote configuration
    func updateRemoteConfig(
        endpointURL: String? = nil,
        displayName: String? = nil,
        verifySSL: Bool? = nil,
        timeoutSeconds: Int? = nil
    ) {
        guard var config = remoteConfig else { return }
        
        if let url = endpointURL {
            config = RemoteConnectionConfig(
                endpointURL: url,
                displayName: config.displayName,
                verifySSL: config.verifySSL,
                timeoutSeconds: config.timeoutSeconds,
                lastConnected: config.lastConnected,
                id: config.id
            )
        }
        if let name = displayName {
            config = RemoteConnectionConfig(
                endpointURL: config.endpointURL,
                displayName: name,
                verifySSL: config.verifySSL,
                timeoutSeconds: config.timeoutSeconds,
                lastConnected: config.lastConnected,
                id: config.id
            )
        }
        if let ssl = verifySSL {
            config = RemoteConnectionConfig(
                endpointURL: config.endpointURL,
                displayName: config.displayName,
                verifySSL: ssl,
                timeoutSeconds: config.timeoutSeconds,
                lastConnected: config.lastConnected,
                id: config.id
            )
        }
        if let timeout = timeoutSeconds {
            config = RemoteConnectionConfig(
                endpointURL: config.endpointURL,
                displayName: config.displayName,
                verifySSL: config.verifySSL,
                timeoutSeconds: timeout,
                lastConnected: config.lastConnected,
                id: config.id
            )
        }
        
        saveRemoteConfig(config)
    }
    
    /// Update management key for current remote config
    func updateManagementKey(_ key: String) {
        guard let config = remoteConfig else { return }
        KeychainHelper.saveManagementKey(key, for: config.id)
    }
    
    /// Clear remote configuration and credentials
    func clearRemoteConfig() {
        if let config = remoteConfig {
            KeychainHelper.deleteManagementKey(for: config.id)
        }
        remoteConfig = nil
        UserDefaults.standard.removeObject(forKey: "remoteConnectionConfig")
        
        // Switch to local mode if currently remote
        if isRemoteMode {
            switchToLocal()
        }
    }
    
    /// Mark last successful connection
    func markConnected() {
        connectionStatus = .connected
        lastError = nil
        
        // Update lastConnected timestamp
        if var config = remoteConfig {
            config = RemoteConnectionConfig(
                endpointURL: config.endpointURL,
                displayName: config.displayName,
                verifySSL: config.verifySSL,
                timeoutSeconds: config.timeoutSeconds,
                lastConnected: Date(),
                id: config.id
            )
            saveRemoteConfig(config)
        }
    }
    
    /// Mark connection status
    func setConnectionStatus(_ status: ConnectionStatus) {
        connectionStatus = status
        if case .error(let message) = status {
            lastError = message
            consecutiveFailures += 1
            
            // Check for auth ban condition (5 failures = 30min ban per CLIProxyAPI docs)
            if consecutiveFailures >= 5 {
                authBanUntil = Date().addingTimeInterval(30 * 60) // 30 minutes
            }
        } else if case .connected = status {
            // Reset failure counters on successful connection
            consecutiveFailures = 0
            authBanUntil = nil
        }
    }
    
    // MARK: - Auto-Reconnection
    
    /// Number of consecutive connection failures
    private(set) var consecutiveFailures: Int = 0
    
    /// If set, connection is banned until this time (auth failures)
    private(set) var authBanUntil: Date?
    
    /// Whether auto-reconnect is currently scheduled
    private var autoReconnectTask: Task<Void, Never>?
    
    /// Whether connection is currently banned due to auth failures
    var isAuthBanned: Bool {
        guard let banUntil = authBanUntil else { return false }
        return Date() < banUntil
    }
    
    /// Time remaining until auth ban expires (in seconds)
    var authBanTimeRemaining: TimeInterval {
        guard let banUntil = authBanUntil else { return 0 }
        return max(0, banUntil.timeIntervalSinceNow)
    }
    
    /// Calculate backoff delay based on consecutive failures
    private func backoffDelay(for attempt: Int) -> TimeInterval {
        // Exponential backoff: 2, 4, 8, 16, 30 seconds (max 30s)
        let baseDelay: TimeInterval = 2
        let maxDelay: TimeInterval = 30
        let delay = baseDelay * pow(2, Double(min(attempt - 1, 4)))
        return min(delay, maxDelay)
    }
    
    /// Schedule auto-reconnection with exponential backoff
    func scheduleAutoReconnect(onReconnect: @escaping () async -> Void) {
        // Cancel any existing reconnect task
        autoReconnectTask?.cancel()
        
        // Don't reconnect if banned
        guard !isAuthBanned else {
            let remaining = Int(authBanTimeRemaining / 60)
            setConnectionStatus(.error("remote.error.authBanned".localized() + " (\(remaining)m)"))
            return
        }
        
        // Don't auto-reconnect after too many failures
        guard consecutiveFailures < 10 else {
            setConnectionStatus(.error("remote.error.tooManyFailures".localized()))
            return
        }
        
        let delay = backoffDelay(for: consecutiveFailures + 1)
        
        autoReconnectTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            guard !Task.isCancelled else { return }
            guard connectionStatus != .connected else { return }
            
            await onReconnect()
        }
    }
    
    /// Cancel any pending auto-reconnect
    func cancelAutoReconnect() {
        autoReconnectTask?.cancel()
        autoReconnectTask = nil
    }
    
    /// Reset all failure counters (call after successful manual reconnect or config change)
    func resetFailureCounters() {
        consecutiveFailures = 0
        authBanUntil = nil
        cancelAutoReconnect()
    }
    
    /// Get user-friendly error message for common connection failures
    static func friendlyErrorMessage(for error: Error) -> String {
        let message = error.localizedDescription.lowercased()
        
        if message.contains("timeout") || message.contains("timed out") {
            return "remote.error.timeout".localized()
        } else if message.contains("ssl") || message.contains("certificate") {
            return "remote.error.sslError".localized()
        } else if message.contains("refused") || message.contains("connection refused") {
            return "remote.error.connectionRefused".localized()
        } else if message.contains("host") || message.contains("dns") || message.contains("resolve") {
            return "remote.error.hostNotFound".localized()
        } else if message.contains("401") || message.contains("unauthorized") {
            return "remote.error.unauthorized".localized()
        } else if message.contains("403") || message.contains("forbidden") {
            return "remote.error.forbidden".localized()
        } else {
            return error.localizedDescription
        }
    }
}

// MARK: - Keychain Helper

/// Helper for secure storage of management keys in macOS Keychain
enum KeychainHelper {
    private static let service = "com.quotio.remote-management"
    
    /// Save management key to Keychain
    static func saveManagementKey(_ key: String, for configId: String) {
        let account = "management-key-\(configId)"
        
        // Delete existing item first
        deleteManagementKey(for: configId)
        
        guard let data = key.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("[Keychain] Failed to save management key: \(status)")
        }
    }
    
    /// Get management key from Keychain
    static func getManagementKey(for configId: String) -> String? {
        let account = "management-key-\(configId)"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
    
    /// Delete management key from Keychain
    static func deleteManagementKey(for configId: String) {
        let account = "management-key-\(configId)"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    /// Check if management key exists
    static func hasManagementKey(for configId: String) -> Bool {
        getManagementKey(for: configId) != nil
    }
}
