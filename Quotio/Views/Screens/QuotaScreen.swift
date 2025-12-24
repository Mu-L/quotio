//
//  QuotaScreen.swift
//  Quotio
//

import SwiftUI

struct QuotaScreen: View {
    @Environment(QuotaViewModel.self) private var viewModel
    
    private var antigravityAccounts: [AuthFile] {
        viewModel.authFiles.filter { $0.providerType == .antigravity }
    }
    
    private var otherProviderGroups: [(AIProvider, [AuthFile])] {
        let grouped = Dictionary(grouping: viewModel.authFiles) { $0.providerType }
        return AIProvider.allCases.compactMap { provider in
            guard provider != .antigravity,
                  let files = grouped[provider], !files.isEmpty else { return nil }
            return (provider, files)
        }
    }
    
    private var totalReady: Int {
        viewModel.authFiles.filter { $0.isReady }.count
    }
    
    private var totalAccounts: Int {
        viewModel.authFiles.count
    }
    
    var body: some View {
        Group {
            if !viewModel.proxyManager.proxyStatus.running {
                ContentUnavailableView(
                    "empty.proxyNotRunning".localized(),
                    systemImage: "bolt.slash",
                    description: Text("empty.startProxyToView".localized())
                )
            } else if viewModel.authFiles.isEmpty {
                ContentUnavailableView(
                    "empty.noAccounts".localized(),
                    systemImage: "person.crop.circle.badge.questionmark",
                    description: Text("empty.addProviderAccounts".localized())
                )
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        SummaryCard(
                            totalReady: totalReady,
                            totalAccounts: totalAccounts,
                            providerCount: antigravityAccounts.count + otherProviderGroups.count
                        )
                        
                        LazyVStack(spacing: 16) {
                            if !antigravityAccounts.isEmpty {
                                Section {
                                    ForEach(antigravityAccounts) { account in
                                        AccountQuotaCard(
                                            account: account,
                                            quotaData: viewModel.providerQuotas[.antigravity]?[account.email ?? ""]
                                        )
                                    }
                                } header: {
                                    HStack {
                                        ProviderIcon(provider: .antigravity, size: 20)
                                        Text("Antigravity")
                                            .font(.headline)
                                        Spacer()
                                        Text("\(antigravityAccounts.count) " + "quota.accounts".localized())
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.horizontal, 4)
                                }
                            }
                            
                            ForEach(otherProviderGroups, id: \.0) { provider, accounts in
                                QuotaCard(
                                    provider: provider,
                                    accounts: accounts,
                                    quotaData: viewModel.providerQuotas[provider]
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("nav.quota".localized())
    }
}

// MARK: - Account Quota Card (Individual account with real quota)

struct AccountQuotaCard: View {
    let account: AuthFile
    let quotaData: ProviderQuotaData?
    
    private var hasQuotaData: Bool {
        guard let data = quotaData else { return false }
        return !data.models.isEmpty
    }
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Circle()
                        .fill(account.statusColor)
                        .frame(width: 10, height: 10)
                    
                    Text(account.email ?? account.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    if let data = quotaData, data.isForbidden {
                        Label("Forbidden", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else {
                        Text(account.status.capitalized)
                            .font(.caption)
                            .foregroundStyle(account.statusColor)
                    }
                }
                
                if hasQuotaData, let data = quotaData {
                    Divider()
                    
                    ForEach(data.models.sorted { $0.name < $1.name }) { model in
                        ModelQuotaRow(model: model)
                    }
                } else if let message = account.statusMessage, !message.isEmpty {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(4)
        }
    }
}

// MARK: - Model Quota Row

private struct ModelQuotaRow: View {
    let model: ModelQuota
    
    private var tint: Color {
        if model.usedPercentage < 50 { return .green }
        if model.usedPercentage < 80 { return .orange }
        return .red
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(model.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text(verbatim: "\(model.usedPercentage)% used")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    if model.formattedResetTime != "—" {
                        HStack(spacing: 2) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text(model.formattedResetTime)
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
            
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.quaternary)
                    Capsule()
                        .fill(tint.gradient)
                        .frame(width: proxy.size.width * min(1, Double(model.usedPercentage) / 100))
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Summary Card

private struct SummaryCard: View {
    let totalReady: Int
    let totalAccounts: Int
    let providerCount: Int
    
    private var readyPercent: Double {
        guard totalAccounts > 0 else { return 0 }
        return Double(totalReady) / Double(totalAccounts) * 100
    }
    
    var body: some View {
        GroupBox {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("quota.overallStatus".localized())
                            .font(.headline)
                        Text("\(providerCount) " + "quota.providers".localized() + ", \(totalAccounts) " + "quota.accounts".localized())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(totalReady)/\(totalAccounts)")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(totalReady > 0 ? .green : .secondary)
                        Text("status.ready".localized())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                QuotaProgressBar(
                    percent: readyPercent,
                    tint: readyPercent >= 75 ? .green : (readyPercent >= 50 ? .orange : .red),
                    height: 12
                )
                
                Text("\(Int(readyPercent))% " + "quota.accountsReady".localized())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(4)
        }
    }
}

#Preview {
    QuotaScreen()
        .environment(QuotaViewModel())
        .frame(width: 600, height: 500)
}
