//
//  DaemonQuotaService.swift
//  Quotio
//

import Foundation

@MainActor @Observable
final class DaemonQuotaService {
    static let shared = DaemonQuotaService()
    
    private(set) var isLoading = false
    private(set) var lastError: String?
    private(set) var quotas: [AIProvider: [String: ProviderQuotaData]] = [:]
    private(set) var lastFetched: Date?
    
    private let ipcClient = DaemonIPCClient.shared
    private let daemonManager = DaemonManager.shared
    
    private init() {}
    
    func fetchAllQuotas(forceRefresh: Bool = false) async {
        var isDaemonReady = daemonManager.isRunning
        if !isDaemonReady {
            isDaemonReady = await daemonManager.checkHealth()
        }
        guard isDaemonReady else {
            lastError = "Daemon not running"
            return
        }
        
        isLoading = true
        lastError = nil
        defer { isLoading = false }
        
        do {
            let result = try await ipcClient.fetchQuotas(forceRefresh: forceRefresh)
            
            if result.success {
                quotas = convertQuotas(result.quotas)
                lastFetched = Date()
            }
            
            if let errors = result.errors, !errors.isEmpty {
                lastError = errors.map { "\($0.provider): \($0.error)" }.joined(separator: ", ")
            }
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    func fetchQuotas(for provider: AIProvider, forceRefresh: Bool = false) async -> [String: ProviderQuotaData]? {
        var isDaemonReady = daemonManager.isRunning
        if !isDaemonReady {
            isDaemonReady = await daemonManager.checkHealth()
        }
        guard isDaemonReady else {
            return nil
        }
        
        do {
            let result = try await ipcClient.fetchQuotas(provider: provider.rawValue, forceRefresh: forceRefresh)
            
            if result.success {
                let converted = convertQuotas(result.quotas)
                if let providerQuotas = converted[provider] {
                    quotas[provider] = providerQuotas
                    return providerQuotas
                }
            }
        } catch {}
        
        return nil
    }
    
    func listCachedQuotas() async -> [AIProvider: [String: ProviderQuotaData]] {
        var isDaemonReady = daemonManager.isRunning
        if !isDaemonReady {
            isDaemonReady = await daemonManager.checkHealth()
        }
        guard isDaemonReady else {
            return [:]
        }
        
        do {
            let result = try await ipcClient.listQuotas()
            return convertQuotas(result.quotas)
        } catch {
            return [:]
        }
    }
    
    private func convertQuotas(_ ipcQuotas: [IPCProviderQuotaInfo]) -> [AIProvider: [String: ProviderQuotaData]] {
        var result: [AIProvider: [String: ProviderQuotaData]] = [:]
        
        for ipcQuota in ipcQuotas {
            guard let provider = AIProvider(rawValue: ipcQuota.provider) else { continue }
            
            let models = ipcQuota.models.map { model in
                ModelQuota(
                    name: model.name,
                    percentage: model.percentage,
                    resetTime: model.resetTime,
                    used: model.used,
                    limit: model.limit
                )
            }
            
            let lastUpdated = ISO8601DateFormatter().date(from: ipcQuota.lastUpdated) ?? Date()
            
            let quotaData = ProviderQuotaData(
                models: models,
                lastUpdated: lastUpdated,
                isForbidden: ipcQuota.isForbidden
            )
            
            if result[provider] == nil {
                result[provider] = [:]
            }
            result[provider]?[ipcQuota.email] = quotaData
        }
        
        return result
    }
}
