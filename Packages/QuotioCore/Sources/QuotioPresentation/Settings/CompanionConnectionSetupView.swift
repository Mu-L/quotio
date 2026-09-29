import QuotioDomain
import SwiftUI

struct CompanionConnectionSetupView: View {
    @Bindable var model: CompanionScreenModel
    var includesAdvanced = true
    @State private var showAdvanced = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            option(.localNetwork, title: "companion.localNetwork", hint: "companion.localHint", symbol: "wifi")
            option(.tailscale, title: "companion.tailscale", hint: "companion.tailscaleHint", symbol: "network")
            if model.mode != .proxy {
                if model.availableAddresses.isEmpty {
                    Label((model.mode == .tailscale ? "companion.noTailscale" : "companion.noLocalNetwork").localized(), systemImage: "info.circle")
                        .font(.callout).foregroundStyle(.secondary)
                    Button("companion.findAddresses".localized()) { Task { await model.reload() } }
                } else if model.availableAddresses.count > 1 {
                    Picker("companion.address".localized(), selection: Binding(get: { model.selectedAddress }, set: { model.address = $0 })) {
                        ForEach(model.availableAddresses, id: \.address) { value in
                            Text(value.address + " · " + value.interface).tag(value.address)
                        }
                    }
                } else {
                    Label(model.selectedAddress, systemImage: "checkmark.circle")
                        .font(.system(.callout, design: .monospaced)).textSelection(.enabled)
                }
            }
            if includesAdvanced {
                DisclosureGroup("companion.advanced".localized(), isExpanded: $showAdvanced) {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("companion.customHTTPS".localized(), isOn: Binding(
                            get: { model.mode == .proxy }, set: { model.mode = $0 ? .proxy : .localNetwork }
                        ))
                        if model.mode == .proxy {
                            TextField("https://mac.example.com", text: $model.origin)
                                .textFieldStyle(.roundedBorder).accessibilityLabel("companion.origin".localized())
                            Text("companion.setupHint".localized()).font(.caption).foregroundStyle(.secondary)
                        }
                        TextField("companion.port".localized(), value: $model.port, format: .number.grouping(.never))
                            .textFieldStyle(.roundedBorder)
                        Text("companion.explanation".localized()).font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .onChange(of: model.mode, initial: true) { _, mode in
            if mode == .proxy { showAdvanced = true }
        }
    }

    private func option(_ mode: CompanionConnectionMode, title: String, hint: String, symbol: String) -> some View {
        Button { model.mode = mode } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: model.mode == mode ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(model.mode == mode ? Color.accentColor : .secondary)
                VStack(alignment: .leading, spacing: 4) {
                    Label(title.localized(), systemImage: symbol).fontWeight(.medium)
                    Text(hint.localized()).font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }.contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(model.mode == mode ? .isSelected : [])
    }
}
