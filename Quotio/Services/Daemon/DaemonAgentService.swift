//
//  DaemonAgentService.swift
//  Quotio
//

import Foundation

@MainActor @Observable
final class DaemonAgentService {
    static let shared = DaemonAgentService()
    
    private(set) var isLoading = false
    private(set) var lastError: String?
    private(set) var agents: [AgentStatus] = []
    private(set) var lastDetected: Date?
    
    private let ipcClient = DaemonIPCClient.shared
    private let daemonManager = DaemonManager.shared
    
    private init() {}
    
    // MARK: - Agent Detection
    
    func detectAllAgents(forceRefresh: Bool = false) async -> [AgentStatus] {
        var isDaemonReady = daemonManager.isRunning
        if !isDaemonReady {
            isDaemonReady = await daemonManager.checkHealth()
        }
        guard isDaemonReady else {
            lastError = "Daemon not running"
            return []
        }
        
        isLoading = true
        lastError = nil
        defer { isLoading = false }
        
        do {
            let result = try await ipcClient.detectAgents(forceRefresh: forceRefresh)
            agents = convertAgents(result.agents)
            lastDetected = Date()
            return agents
        } catch {
            lastError = error.localizedDescription
            return []
        }
    }
    
    // MARK: - Agent Configuration
    
    func configureAgent(
        agent: CLIAgent,
        mode: ConfigurationMode
    ) async -> AgentConfigResult? {
        var isDaemonReady = daemonManager.isRunning
        if !isDaemonReady {
            isDaemonReady = await daemonManager.checkHealth()
        }
        guard isDaemonReady else {
            lastError = "Daemon not running"
            return nil
        }
        
        isLoading = true
        lastError = nil
        defer { isLoading = false }
        
        do {
            let result = try await ipcClient.configureAgent(
                agent: agent.rawValue,
                mode: mode.rawValue
            )
            
            if result.success {
                _ = await detectAllAgents(forceRefresh: true)
                
                return AgentConfigResult.success(
                    type: agent.configType,
                    mode: mode,
                    configPath: result.configPath,
                    instructions: "Configured via daemon",
                    backupPath: result.backupPath
                )
            } else {
                return AgentConfigResult.failure(error: "Configuration failed")
            }
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }
    
    // MARK: - Helpers
    
    func getAgentStatus(for agent: CLIAgent) -> AgentStatus? {
        agents.first { $0.agent == agent }
    }
    
    func installedAgents() -> [AgentStatus] {
        agents.filter { $0.installed }
    }
    
    func configuredAgents() -> [AgentStatus] {
        agents.filter { $0.configured }
    }
    
    func unconfiguredInstalledAgents() -> [AgentStatus] {
        agents.filter { $0.installed && !$0.configured }
    }
    
    // MARK: - Conversion
    
    private func convertAgents(_ ipcAgents: [IPCDetectedAgent]) -> [AgentStatus] {
        ipcAgents.compactMap { ipcAgent in
            guard let agent = CLIAgent(rawValue: ipcAgent.id) else { return nil }
            
            return AgentStatus(
                agent: agent,
                installed: ipcAgent.installed,
                configured: ipcAgent.configured,
                binaryPath: ipcAgent.binaryPath,
                version: ipcAgent.version,
                lastConfigured: nil // daemon doesn't track this currently
            )
        }.sorted { $0.agent.displayName < $1.agent.displayName }
    }
}
