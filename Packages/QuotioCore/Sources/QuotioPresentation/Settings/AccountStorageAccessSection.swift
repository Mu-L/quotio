import SwiftUI

struct AccountStorageAccessSection: View {
    @Environment(AccountsScreenModel.self) private var accounts
    @Environment(QuotaFeatureController.self) private var quota
    @State private var showExplanation = false
    @State private var failed = false
    @State private var isSubmitting = false

    var body: some View {
        if accounts.storageAccessRequired {
            Section {
                Label("settings.vaultAccess.title".localized(), systemImage: "lock")
                Text("settings.vaultAccess.reason".localized()).foregroundStyle(.secondary)
                Button("settings.authorize".localized()) { showExplanation = true }
            }
            .sheet(isPresented: $showExplanation) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("settings.vaultAccess.title".localized()).font(.title2)
                    Text("settings.vaultAccess.explanation".localized())
                        .fixedSize(horizontal: false, vertical: true)
                    if failed { Text((accounts.nativeAuthorizationFailure ?? .unknown).message).foregroundStyle(.red) }
                    if isSubmitting {
                        ProgressView("settings.authorization.pending".localized())
                            .controlSize(.small)
                    }
                    HStack {
                        Spacer()
                        Button((isSubmitting ? "action.close" : "action.cancel").localized()) { showExplanation = false }.keyboardShortcut(.cancelAction)
                        Button("onboarding.button.continue".localized()) {
                            isSubmitting = true
                            failed = false
                            Task {
                                defer { isSubmitting = false }
                                do {
                                    try await accounts.authorizeAccountStorage()
                                    await quota.refreshAll(force: true)
                                    showExplanation = false
                                } catch { failed = true }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                        .disabled(isSubmitting || accounts.authorizingStorage)
                    }
                }
                .padding(24)
                .frame(width: 460)
            }
        }
    }
}
