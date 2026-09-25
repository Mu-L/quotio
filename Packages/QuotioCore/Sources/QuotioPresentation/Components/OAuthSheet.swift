import AppKit
import QuotioApplication
import QuotioDomain
import SwiftUI
import UniformTypeIdentifiers

struct OAuthSheet: View {
    @Environment(ProxyManagementScreenModel.self) private var proxyManagement
    @Environment(QuotaFeatureController.self) private var viewModel
    @Environment(OperatingModeManager.self) private var modeManager
    let provider: QuotaProvider
    let onDismiss: () -> Void

    @State private var hasStartedAuth = false
    @State private var selectedKiroMethod: OAuthAuthorizationMethod = .kiroImport
    @State private var manualOAuthCode = ""

    private var isPolling: Bool {
        viewModel.oauthState?.status == .polling || viewModel.oauthState?.status == .waiting
    }

    private var isSuccess: Bool {
        viewModel.oauthState?.status == .success
    }

    private var isError: Bool {
        viewModel.oauthState?.status == .error
    }

    private var kiroAuthMethods: [OAuthAuthorizationMethod] {
        if modeManager.isMonitorMode { return [.kiroAWSDeviceCode] }
        return [.kiroImport, .kiroGoogle, .kiroAWSBrowser, .kiroAWSDeviceCode]
    }

    var body: some View {
        VStack(spacing: 28) {
            ProviderIcon(provider: provider, size: 64)

            VStack(spacing: 8) {
                Text("oauth.connect".localized() + " " + provider.displayName)
                    .font(.title2)
                    .fontWeight(.bold)

                Text("oauth.authenticateWith".localized() + " " + provider.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if provider == .kiro {
                VStack(alignment: .leading, spacing: 6) {
                    Text("oauth.authMethod".localized())
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Picker("", selection: $selectedKiroMethod) {
                        ForEach(kiroAuthMethods, id: \.self) { method in
                            Text(method.displayName).tag(method)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()


                }
                .frame(maxWidth: 320)
            }

            if !modeManager.isMonitorMode,
               proxyManagement.isLegacyAuthWarningNeeded(for: provider) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(proxyManagement.upstreamCompatibilityWarning)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: 320, alignment: .leading)
                .padding(12)
                .background(Color.orange.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            if let state = viewModel.oauthState, state.provider == provider {
                OAuthStatusView(status: state.status, error: state.error, deviceCode: state.userCode, authURL: state.authURL, provider: provider)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            if modeManager.isMonitorMode, viewModel.oauthState?.requiresManualCode == true {
                HStack(spacing: 8) {
                    TextField("oauth.authorizationCode".localized(), text: $manualOAuthCode)
                        .textFieldStyle(.roundedBorder)
                    Button("oauth.complete".localized()) {
                        Task { await viewModel.completeMonitorOAuthCode(manualOAuthCode, provider: provider) }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(manualOAuthCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .frame(maxWidth: 360)
            }

            HStack(spacing: 16) {
                Button("action.cancel".localized(), role: .cancel) {
                    viewModel.cancelOAuth()
                    onDismiss()
                }
                .buttonStyle(.bordered)

                if isError {
                    Button {
                        hasStartedAuth = false
                        Task {
                            await viewModel.startOAuth(
                                for: provider,
                                method: provider == .kiro ? selectedKiroMethod : .providerDefault
                            )
                        }
                    } label: {
                        Label("oauth.retry".localized(), systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                } else if !isSuccess {
                    Button {
                        hasStartedAuth = true
                        Task {
                            await viewModel.startOAuth(
                                for: provider,
                                method: provider == .kiro ? selectedKiroMethod : .providerDefault
                            )
                        }
                    } label: {
                        if isPolling {
                            SmallProgressView()
                        } else {
                            Label("oauth.authenticate".localized(), systemImage: "key.fill")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(provider.color)
                    .disabled(isPolling)
                }
            }
        }
        .padding(40)
        .frame(width: 480)
        .frame(minHeight: 350)
        .fixedSize(horizontal: false, vertical: true)
        .animation(.easeInOut(duration: 0.2), value: viewModel.oauthState?.status)
        .onChange(of: viewModel.oauthState?.status) { _, newStatus in
            if newStatus == .success {
                Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    onDismiss()
                }
            }
        }
    }
}

private extension OAuthAuthorizationMethod {
    var displayName: String {
        switch self {
        case .providerDefault: "Default"
        case .kiroGoogle: "Google OAuth"
        case .kiroAWSDeviceCode: "AWS Builder ID (Device Code)"
        case .kiroAWSBrowser: "AWS Builder ID (Browser)"
        case .kiroImport: "Import from Kiro IDE"
        }
    }
}

private struct OAuthStatusView: View {
    let status: QuotaOAuthState.OAuthStatus
    let error: String?
    let deviceCode: String?
    let authURL: String?
    let provider: QuotaProvider
    @Environment(PasteboardScreenModel.self) private var pasteboard
    @Environment(PlatformActionScreenModel.self) private var platformActions

    /// Stable rotation angle for spinner animation (fixes UUID() infinite re-render)
    @State private var rotationAngle: Double = 0

    /// Visual feedback for copy action
    @State private var copied = false

    var body: some View {
        Group {
            switch status {
            case .waiting:
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.large)
                    Text("oauth.openingBrowser".localized())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 16)

            case .polling:
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(provider.color.opacity(0.2), lineWidth: 4)
                            .frame(width: 60, height: 60)

                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(provider.color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(rotationAngle - 90))
                            .onAppear {
                                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                                    rotationAngle = 360
                                }
                            }

                        Image(systemName: "person.badge.key.fill")
                            .font(.title2)
                            .foregroundStyle(provider.color)
                    }

                    if let deviceCode, !deviceCode.isEmpty {
                        VStack(spacing: 8) {
                            Text("oauth.enterCodeInBrowser".localized())
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 12) {
                                Text(deviceCode)
                                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                                    .foregroundStyle(provider.color)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(provider.color.opacity(0.1))
                                    .cornerRadius(8)

                                Button {
                                    pasteboard.copy(deviceCode)
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .font(.title3)
                                }
                                .buttonStyle(.subtle)
                                .help("action.copyCode".localized())
                            }

                            Text("oauth.waitingForAuth".localized())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else if (provider == .copilot || provider == .kiro), let message = error {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 350)
                    } else {
                        Text("oauth.waitingForAuth".localized())
                            .font(.subheadline)
                            .fontWeight(.medium)

                        // Show auth URL with copy/open buttons
                        if let urlString = authURL, let url = URL(string: urlString) {
                            VStack(spacing: 12) {
                                Text("oauth.copyLinkOrOpen".localized())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                HStack(spacing: 12) {
                                    Button {
                                        pasteboard.copy(urlString)
                                        copied = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            copied = false
                                        }
                                    } label: {
                                        Label(copied ? "oauth.copied".localized() : "oauth.copyLink".localized(), systemImage: copied ? "checkmark" : "doc.on.doc")
                                    }
                                    .buttonStyle(.bordered)

                                    Button {
                                        platformActions.open(url)
                                    } label: {
                                        Label("oauth.openLink".localized(), systemImage: "safari")
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(provider.color)
                                }
                            }
                        } else {
                            Text("oauth.completeBrowser".localized())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 16)

            case .success:
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)

                    Text("oauth.success".localized())
                        .font(.headline)
                        .foregroundStyle(.green)

                    Text("oauth.closingSheet".localized())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 16)

            case .error:
                VStack(spacing: 12) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.red)

                    Text("oauth.failed".localized())
                        .font(.headline)
                        .foregroundStyle(.red)

                    if let error = error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 300)
                    }
                }
                .padding(.vertical, 16)
            }
        }
        .frame(minHeight: 100)
    }
}
