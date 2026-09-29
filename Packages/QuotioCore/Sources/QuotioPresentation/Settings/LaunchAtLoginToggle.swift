import AppKit
import QuotioApplication
import QuotioDomain
import SwiftUI

struct LaunchAtLoginToggle: View {
    @Environment(LaunchAtLoginScreenModel.self) private var launchModel
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showLocationWarning = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle("settings.launchAtLogin".localized(), isOn: Binding(
                get: { launchModel.snapshot.status.isEnabled },
                set: { newValue in
                    if !launchModel.setEnabled(newValue) {
                        errorMessage = launchModel.errorMessage ?? ""
                        showError = true
                    }
                    showLocationWarning = newValue && !launchModel.snapshot.isInApplicationsFolder
                }
            ))

            // Show location warning inline
            if showLocationWarning {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                    Text("launchAtLogin.warning.notInApplications".localized())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.leading, 2)
            }
        }
        .onAppear {
            // Refresh status when view appears to sync with System Settings
            launchModel.refresh()
        }
        .alert("launchAtLogin.error.title".localized(), isPresented: $showError) {
            Button("OK".localized()) { showError = false }
            Button("launchAtLogin.openSystemSettings".localized()) {
                launchModel.openSystemSettings()
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
    }
}
