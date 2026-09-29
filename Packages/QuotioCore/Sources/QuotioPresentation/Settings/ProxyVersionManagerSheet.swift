import AppKit
import QuotioApplication
import QuotioDomain
import SwiftUI

struct ProxyVersionManagerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ProxyScreenModel.self) private var proxyManager

    @State private var availableVersions: [ProxyVersionInfo] = []
    @State private var installedVersions: [InstalledProxyVersion] = []
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var installingVersion: String?
    @State private var installError: String?

    // State for deletion warning
    @State private var showDeleteWarning = false
    @State private var pendingInstallVersion: ProxyVersionInfo?
    @State private var versionsToDelete: [String] = []

    private var installedVersionItems: [NamespacedInstalledVersionItem] {
        installedVersions.map { version in
            NamespacedInstalledVersionItem(id: "installed-\(version.id)", version: version)
        }
    }

    private var availableVersionItems: [NamespacedAvailableVersionItem] {
        availableVersions.map { versionInfo in
            NamespacedAvailableVersionItem(id: "available-\(versionInfo.id)", versionInfo: versionInfo)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("settings.proxyUpdate.advanced.title".localized())
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("settings.proxyUpdate.advanced.description".localized())
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
            .padding()

            Divider()

            // Content
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("settings.proxyUpdate.advanced.loading".localized())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = loadError {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                    Text("settings.proxyUpdate.advanced.fetchError".localized())
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("action.refresh".localized()) {
                        Task { await loadReleases() }
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Installed Versions Section
                if !installedVersions.isEmpty {
                            sectionHeader("settings.proxyUpdate.advanced.installedVersions".localized())

                            ForEach(installedVersionItems) { item in
                                InstalledVersionRow(
                                    version: item.version,
                                    onActivate: { activateVersion(item.version.version) },
                                    onDelete: { deleteVersion(item.version.version) }
                                )
                                Divider().padding(.leading, 16)
                            }
                        }

                        // Available Versions Section
                        sectionHeader("settings.proxyUpdate.advanced.availableVersions".localized())

                        if availableVersions.isEmpty {
                            HStack {
                                Text("settings.proxyUpdate.advanced.noReleases".localized())
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        } else {
                            ForEach(availableVersionItems) { item in
                                AvailableVersionRow(
                                    versionInfo: item.versionInfo,
                                    isInstalled: isVersionInstalled(item.versionInfo.version),
                                    isInstalling: installingVersion == item.versionInfo.version,
                                    onInstall: { installVersion(item.versionInfo) }
                                )
                                Divider().padding(.leading, 16)
                            }
                        }
                    }
                    .padding(.bottom)
                }
            }

            // Error footer
            if let error = installError {
                Divider()
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        installError = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
            }
        }
        .frame(width: 500, height: 500)
        .task {
            await loadReleases()
        }
        .alert("settings.proxyUpdate.deleteWarning.title".localized(), isPresented: $showDeleteWarning) {
            Button("action.cancel".localized(), role: .cancel) {
                pendingInstallVersion = nil
                versionsToDelete = []
            }
            Button("settings.proxyUpdate.deleteWarning.confirm".localized(), role: .destructive) {
                if let versionInfo = pendingInstallVersion {
                    performInstall(versionInfo)
                }
                pendingInstallVersion = nil
                versionsToDelete = []
            }
        } message: {
            Text(String(format: "settings.proxyUpdate.deleteWarning.message".localized(), AppConstants.maxInstalledVersions, versionsToDelete.joined(separator: ", ")))
        }
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
    }

    private func isVersionInstalled(_ version: String) -> Bool {
        installedVersions.contains { $0.version == version }
    }

    private func refreshInstalledVersions() {
        installedVersions = proxyManager.installedVersions
    }

    private func loadReleases() async {
        isLoading = true
        loadError = nil

        do {
            availableVersions = try await proxyManager.fetchAvailableVersions(limit: 15)
            refreshInstalledVersions()
            isLoading = false
        } catch {
            loadError = proxyManager.errorMessage(for: error)
            isLoading = false
        }
    }

    private func installVersion(_ versionInfo: ProxyVersionInfo) {
        Task { @MainActor in
            let toDelete = await proxyManager.versionsToBeDeleted(
                keeping: AppConstants.maxInstalledVersions
            )
            if !toDelete.isEmpty {
                versionsToDelete = toDelete
                pendingInstallVersion = versionInfo
                showDeleteWarning = true
                return
            }

            performInstall(versionInfo)
        }
    }

    private func performInstall(_ versionInfo: ProxyVersionInfo) {
        installingVersion = versionInfo.version
        installError = nil

        Task { @MainActor in
            do {
                try await proxyManager.performManagedUpgrade(to: versionInfo)
                installingVersion = nil
                refreshInstalledVersions()
            } catch {
                installError = proxyManager.errorMessage(for: error)
                installingVersion = nil
            }
        }
    }

    private func activateVersion(_ version: String) {
        Task { @MainActor in
            do {
                try await proxyManager.activateVersion(version)
                refreshInstalledVersions()
            } catch {
                installError = proxyManager.errorMessage(for: error)
            }
        }
    }

    private func deleteVersion(_ version: String) {
        Task { @MainActor in
            do {
                try await proxyManager.deleteVersion(version)
                refreshInstalledVersions()
            } catch {
                installError = proxyManager.errorMessage(for: error)
            }
        }
    }
}

private struct NamespacedInstalledVersionItem: Identifiable {
    let id: String
    let version: InstalledProxyVersion
}

private struct NamespacedAvailableVersionItem: Identifiable {
    let id: String
    let versionInfo: ProxyVersionInfo
}

private struct InstalledVersionRow: View {
    let version: InstalledProxyVersion
    let onActivate: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Version info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("v\(version.version)")
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)

                    if version.isCurrent {
                        Text("settings.proxyUpdate.advanced.current".localized())
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .clipShape(Capsule())
                    }
                }

                Text(version.installedAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Actions
            if !version.isCurrent {
                Button("settings.proxyUpdate.advanced.activate".localized()) {
                    onActivate()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .foregroundStyle(.red)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

private struct AvailableVersionRow: View {
    let versionInfo: ProxyVersionInfo
    let isInstalled: Bool
    let isInstalling: Bool
    let onInstall: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Version info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("v\(versionInfo.version)")
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)

                    if versionInfo.version.contains("-rc") {
                        Text("settings.proxyUpdate.advanced.prerelease".localized())
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .clipShape(Capsule())
                    }

                    if isInstalled {
                        Text("settings.proxyUpdate.advanced.installed".localized())
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

            }

            Spacer()

            // Install button
            if !isInstalled {
                Button {
                    onInstall()
                } label: {
                    if isInstalling {
                        SmallProgressView()
                    } else {
                        Text("settings.proxyUpdate.advanced.install".localized())
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(isInstalling)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
