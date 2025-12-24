//
//  DashboardScreen.swift
//  Quotio
//

import SwiftUI

struct DashboardScreen: View {
    @Environment(QuotaViewModel.self) private var viewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if !viewModel.proxyManager.isBinaryInstalled {
                    installBinarySection
                } else if !viewModel.proxyManager.proxyStatus.running {
                    startProxySection
                } else {
                    kpiSection
                    providerSection
                    endpointSection
                }
            }
            .padding(24)
        }
        .navigationTitle("nav.dashboard".localized())
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await viewModel.refreshData() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(!viewModel.proxyManager.proxyStatus.running)
            }
        }
    }
    
    // MARK: - Install Binary
    
    private var installBinarySection: some View {
        ContentUnavailableView {
            Label("dashboard.cliNotInstalled".localized(), systemImage: "arrow.down.circle")
        } description: {
            Text("dashboard.clickToInstall".localized())
        } actions: {
            if viewModel.proxyManager.isDownloading {
                ProgressView(value: viewModel.proxyManager.downloadProgress)
                    .progressViewStyle(.linear)
                    .frame(width: 200)
            } else {
                Button("dashboard.installCLI".localized()) {
                    Task {
                        do {
                            try await viewModel.proxyManager.downloadAndInstallBinary()
                        } catch {
                            viewModel.errorMessage = error.localizedDescription
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            
            if let error = viewModel.proxyManager.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    // MARK: - Start Proxy
    
    private var startProxySection: some View {
        ContentUnavailableView {
            Label("empty.proxyNotRunning".localized(), systemImage: "power")
        } description: {
            Text("dashboard.startToBegin".localized())
        } actions: {
            Button("action.startProxy".localized()) {
                Task { await viewModel.startProxy() }
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    // MARK: - KPI Section
    
    private var kpiSection: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 16)], spacing: 16) {
            KPICard(
                title: "dashboard.accounts".localized(),
                value: "\(viewModel.totalAccounts)",
                subtitle: "\(viewModel.readyAccounts) " + "dashboard.ready".localized(),
                icon: "person.2.fill",
                color: .blue
            )
            
            KPICard(
                title: "dashboard.requests".localized(),
                value: "\(viewModel.usageStats?.usage?.totalRequests ?? 0)",
                subtitle: "dashboard.total".localized(),
                icon: "arrow.up.arrow.down",
                color: .green
            )
            
            KPICard(
                title: "dashboard.tokens".localized(),
                value: (viewModel.usageStats?.usage?.totalTokens ?? 0).formattedCompact,
                subtitle: "dashboard.processed".localized(),
                icon: "text.word.spacing",
                color: .purple
            )
            
            KPICard(
                title: "dashboard.successRate".localized(),
                value: String(format: "%.0f%%", viewModel.usageStats?.usage?.successRate ?? 0.0),
                subtitle: "\(viewModel.usageStats?.usage?.failureCount ?? 0) " + "dashboard.failed".localized(),
                icon: "checkmark.circle.fill",
                color: .orange
            )
        }
    }
    
    // MARK: - Provider Section
    
    private var providerSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                FlowLayout(spacing: 8) {
                    ForEach(viewModel.connectedProviders) { provider in
                        ProviderChip(provider: provider, count: viewModel.authFilesByProvider[provider]?.count ?? 0)
                    }
                    
                    ForEach(viewModel.disconnectedProviders) { provider in
                        Button {
                            Task { await viewModel.startOAuth(for: provider) }
                        } label: {
                            Label(provider.displayName, systemImage: "plus.circle")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .tint(.secondary)
                    }
                }
            }
        } label: {
            Label("dashboard.providers".localized(), systemImage: "cpu")
        }
    }
    
    // MARK: - Endpoint Section
    
    private var endpointSection: some View {
        GroupBox {
            HStack {
                Text(viewModel.proxyManager.proxyStatus.endpoint)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                
                Spacer()
                
                Button {
                    viewModel.proxyManager.copyEndpointToClipboard()
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.bordered)
            }
        } label: {
            Label("dashboard.apiEndpoint".localized(), systemImage: "link")
        }
    }
}

// MARK: - KPI Card

struct KPICard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Label(title, systemImage: icon)
                .foregroundStyle(color)
        }
    }
}

// MARK: - Provider Chip

struct ProviderChip: View {
    let provider: AIProvider
    let count: Int
    
    var body: some View {
        HStack(spacing: 6) {
            ProviderIcon(provider: provider, size: 16)
            Text(provider.displayName)
            if count > 1 {
                Text("×\(count)")
                    .fontWeight(.semibold)
            }
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(provider.color.opacity(0.15))
        .foregroundStyle(provider.color)
        .clipShape(Capsule())
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        
        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}
