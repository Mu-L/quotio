//
//  TunnelSheet.swift
//  Quotio - Cloudflare Tunnel Configuration Sheet
//

import SwiftUI

struct TunnelSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(QuotaViewModel.self) private var viewModel
    
    private var tunnelManager: TunnelManager { TunnelManager.shared }
    private var proxyPort: UInt16 { viewModel.proxyManager.port }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !tunnelManager.installation.isInstalled {
                        installationBanner
                    } else {
                        tunnelControlSection
                        
                        if tunnelManager.tunnelState.isActive {
                            urlSection
                        }
                        
                        if let error = tunnelManager.tunnelState.errorMessage {
                            errorSection(error)
                        }
                        
                        infoSection
                    }
                }
                .padding(20)
            }
            
            Divider()
            footerView
        }
        .frame(width: 480, height: 400)
    }
    
    private var headerView: some View {
        HStack(spacing: 16) {
            Image(systemName: "globe")
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("tunnel.title".localized())
                    .font(.headline)
                
                Text("tunnel.subtitle".localized())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
    }
    
    private var installationBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("tunnel.notInstalled.title".localized())
                        .font(.headline)
                    
                    Text("tunnel.notInstalled.message".localized())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("tunnel.install.title".localized())
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text("brew install cloudflared")
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                    
                    Spacer()
                    
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString("brew install cloudflared", forType: .string)
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.plain)
                }
                .padding(8)
                .background(Color(.textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                
                Link(destination: URL(string: "https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/")!) {
                    Label("tunnel.install.docs".localized(), systemImage: "arrow.up.right.square")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private var tunnelControlSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("tunnel.status".localized())
                    .font(.headline)
                
                Spacer()
                
                TunnelStatusBadge(status: tunnelManager.tunnelState.status)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("tunnel.localProxy".localized())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("localhost:" + String(proxyPort))
                        .font(.system(.body, design: .monospaced))
                }
                
                Spacer()
                
                Button {
                    Task {
                        await tunnelManager.toggle(port: proxyPort)
                    }
                } label: {
                    Text(tunnelManager.tunnelState.isActive || tunnelManager.tunnelState.status == .starting
                         ? "tunnel.action.stop".localized()
                         : "tunnel.action.start".localized())
                        .frame(width: 100)
                }
                .buttonStyle(.borderedProminent)
                .tint(tunnelManager.tunnelState.isActive ? .red : .blue)
                .disabled(tunnelManager.tunnelState.isTransitioning)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var urlSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("tunnel.publicURL".localized())
                .font(.headline)
            
            HStack {
                Text(tunnelManager.tunnelState.publicURL ?? "—")
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .lineLimit(1)
                
                Spacer()
                
                Button {
                    tunnelManager.copyURLToClipboard()
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.plain)
                .help("action.copy".localized())
            }
            .padding(10)
            .background(Color.green.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            
            if let startTime = tunnelManager.tunnelState.startTime {
                Text(String(format: "tunnel.uptime".localized(), formatUptime(since: startTime)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func errorSection(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            
            Text(message)
                .font(.subheadline)
            
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("tunnel.info.title".localized())
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                Label("tunnel.info.quick".localized(), systemImage: "bolt.fill")
                Label("tunnel.info.temporary".localized(), systemImage: "clock")
                Label("tunnel.info.noAccount".localized(), systemImage: "person.badge.minus")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var footerView: some View {
        HStack {
            if tunnelManager.installation.isInstalled {
                if let version = tunnelManager.installation.version {
                    Text("cloudflared v" + version)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            Button("action.close".localized()) {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding(20)
    }
    
    private func formatUptime(since date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)
        let seconds = Int(interval.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    TunnelSheet()
        .environment(QuotaViewModel())
}
