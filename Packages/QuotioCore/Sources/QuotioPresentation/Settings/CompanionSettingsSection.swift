import SwiftUI
import CoreImage.CIFilterBuiltins

struct CompanionSettingsSection: View {
    @Bindable var model: CompanionScreenModel
    var body: some View {
        Section("companion.title".localized()) {
            TextField("companion.origin".localized(), text: $model.origin).disabled(model.enabled)
            TextField("companion.port".localized(), value: $model.port, format: .number.grouping(.never)).disabled(model.enabled)
            Button((model.enabled ? "companion.disable" : "companion.enable").localized()) {
                Task { await model.configure(enabled: !model.enabled) }
            }
            Text("companion.explanation".localized()).font(.caption).foregroundStyle(.secondary)
            if model.enabled {
                Label("companion.listening".localized(), systemImage: "network")
                TextField("companion.deviceName".localized(), text: $model.label)
                Button("companion.issue".localized()) { Task { await model.issue() } }
            }
            ForEach(model.devices) { device in
                HStack {
                    VStack(alignment: .leading) {
                        Text(device.label)
                        Text(device.expiresAt, format: .dateTime.year().month().day()).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("companion.revoke".localized(), role: .destructive) { Task { await model.revoke(device.id) } }
                }
            }
            if model.failure { Text("companion.error".localized()).foregroundStyle(.red) }
        }.disabled(model.busy).task { await model.reload() }
            .sheet(isPresented: Binding(get: { model.pairing != nil }, set: { if !$0 { model.pairing = nil } })) {
                VStack(spacing: 16) {
                    Text("companion.scan".localized()).font(.title2)
                    if let pairing = model.pairing, let image = qrImage(pairing) {
                        Image(decorative: image, scale: 1).interpolation(.none).resizable().frame(width: 300, height: 300)
                    }
                    Text("companion.qrPrivate".localized()).font(.caption).frame(maxWidth: 360)
                    if let pairing = model.pairing {
                        DisclosureGroup("companion.manual".localized()) {
                            Text(pairing).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                        }.frame(width: 360)
                    }
                    Button("action.done".localized()) { model.pairing = nil }
                }.padding(24)
            }
    }
    private func qrImage(_ value: String) -> CGImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(value.utf8)
        filter.correctionLevel = "M"
        guard let image = filter.outputImage else { return nil }
        let scaled = image.transformed(by: CGAffineTransform(scaleX: 6, y: 6))
        return CIContext().createCGImage(scaled, from: scaled.extent)
    }
}
