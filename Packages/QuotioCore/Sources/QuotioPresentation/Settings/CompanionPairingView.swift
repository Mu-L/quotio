import CoreImage.CIFilterBuiltins
import QuotioDomain
import SwiftUI

struct CompanionPairingView: View {
    @Bindable var model: CompanionScreenModel
    let presentation: CompanionScreenModel.Presentation
    @Environment(PasteboardScreenModel.self) private var pasteboard

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Label("companion.pair".localized(), systemImage: "iphone")
                    .font(.title2.weight(.semibold))
                Spacer()
                Button("action.close".localized(), systemImage: "xmark") { model.hidePairing(in: presentation) }
                    .labelStyle(.iconOnly).buttonStyle(.plain)
                    .keyboardShortcut(.cancelAction)
            }
            if let pairing = model.pairing {
                CompanionCodeView(pairing: pairing, copyCode: { pasteboard.copy(pairing.payload) })
                    .id(pairing.device.id)
                HStack {
                    Text("companion.codeCreated".localized()).font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button("action.done".localized()) { model.finishPairing() }
                        .buttonStyle(.borderedProminent).disabled(model.busy)
                }
            } else {
                Text("companion.summary".localized()).foregroundStyle(.secondary)
                if !model.enabled {
                    CompanionConnectionSetupView(model: model).disabled(model.busy)
                    HStack {
                        if model.busy { ProgressView().controlSize(.small) }
                        Spacer()
                        Button("companion.enableContinue".localized()) { Task { await model.configure(enabled: true) } }
                            .buttonStyle(.borderedProminent).disabled(model.busy || !model.canEnable)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(model.origin).font(.system(.callout, design: .monospaced)).textSelection(.enabled)
                        Text("companion.listening".localized()).font(.caption).foregroundStyle(.secondary)
                        TextField("companion.deviceName".localized(), text: $model.label).textFieldStyle(.roundedBorder)
                        Label("companion.readOnly".localized(), systemImage: "eye").font(.callout)
                        Text("companion.qrPrivate".localized()).font(.caption).foregroundStyle(.secondary)
                    }
                    HStack {
                        if model.busy { ProgressView().controlSize(.small) }
                        Button("companion.changeNetwork".localized()) { Task { await model.configure(enabled: false) } }
                            .disabled(model.busy)
                        Spacer()
                        Button("companion.issue".localized()) { Task { await model.issue() } }
                            .buttonStyle(.borderedProminent).disabled(model.busy || model.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            if let failure = model.failure {
                Label(failure.message, systemImage: "exclamationmark.triangle").foregroundStyle(.red).font(.callout)
                if !model.busy {
                    Button("action.retry".localized()) { Task { await model.reload() } }
                }
            }
        }
        .padding(24)
        .fixedSize(horizontal: false, vertical: true)
        .task {
            while !Task.isCancelled {
                model.clearExpiredPairing()
                await model.reload()
                do { try await Task.sleep(for: .seconds(15)) } catch { return }
            }
        }
    }
}

private struct CompanionCodeView: View {
    let pairing: CompanionPairing
    let copyCode: () -> Void
    @State private var image: CGImage?

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 24) { instructions.frame(width: 270); code }
            VStack(alignment: .leading, spacing: 16) { code.frame(maxWidth: .infinity); instructions }
        }
        .task(id: pairing.device.id) {
            let filter = CIFilter.qrCodeGenerator()
            filter.message = Data(pairing.payload.utf8)
            filter.correctionLevel = "M"
            if let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 6, y: 6)) {
                image = CIContext().createCGImage(output, from: output.extent)
            }
        }
    }

    private var instructions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(pairing.device.label).font(.headline)
            Text("companion.scanInstruction".localized())
            Text(pairing.origin).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
            Label("companion.readOnly".localized(), systemImage: "eye").font(.callout)
            Text("\("companion.expires".localized()) \(pairing.device.expiresAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption).foregroundStyle(.secondary)
            DisclosureGroup("companion.manual".localized()) {
                Text("companion.manualHint".localized()).font(.caption).foregroundStyle(.secondary)
                Button("companion.copyCode".localized(), action: copyCode)
            }
        }
    }

    private var code: some View {
        Group {
            if let image { Image(decorative: image, scale: 1).interpolation(.none).resizable() }
            else { ProgressView().tint(.black) }
        }
        .frame(width: 232, height: 232).padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("companion.scan".localized())
    }
}
