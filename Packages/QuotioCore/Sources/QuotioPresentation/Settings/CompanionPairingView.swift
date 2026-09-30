import CoreImage.CIFilterBuiltins
import QuotioDomain
import SwiftUI

struct CompanionPairingView: View {
    @Bindable var model: CompanionScreenModel
    let presentation: CompanionScreenModel.Presentation
    @Environment(PasteboardScreenModel.self) private var pasteboard

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("companion.pairTitle".localized(), systemImage: "iphone")
                .font(.title2.weight(.semibold))
            if let pairing = model.pairing {
                CompanionCodeView(pairing: pairing, copyCode: { pasteboard.copy(pairing.payload) })
                    .id(pairing.device.id)
                HStack {
                    Button("companion.cancelCode".localized(), role: .destructive) { Task { await model.cancelPairing() } }
                        .disabled(model.busy)
                    Spacer()
                    Button("action.done".localized()) { model.finishPairing() }
                        .buttonStyle(.borderedProminent).disabled(model.busy)
                }
            } else {
                Text("companion.summary".localized()).foregroundStyle(.secondary)
                CompanionConnectionSetupView(model: model, includesAdvanced: presentation == .settings)
                    .disabled(model.busy)
                if model.enabled {
                    Label("\(model.origin) · \("companion.statusOn".localized())", systemImage: "checkmark.circle.fill")
                        .font(.callout).foregroundStyle(.secondary).textSelection(.enabled)
                }
                HStack {
                    Text("companion.deviceName".localized())
                    TextField("companion.deviceName".localized(), text: $model.label).textFieldStyle(.roundedBorder)
                }
                Label("companion.qrPrivate".localized(), systemImage: "eye").font(.caption).foregroundStyle(.secondary)
                HStack {
                    Button("action.cancel".localized()) { model.hidePairing(in: presentation) }
                        .keyboardShortcut(.cancelAction)
                    Spacer()
                    Button(model.busy ? "companion.creatingCode".localized() : "companion.issue".localized()) {
                        Task { await model.createPairing() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.busy || !model.canEnable || model.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            if let failure = model.failure {
                Label(failure.message, systemImage: "exclamationmark.triangle").foregroundStyle(.red).font(.callout)
                if !model.busy {
                    Button("action.retry".localized()) { Task { await model.createPairing() } }
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
            Text("companion.scanInstruction".localized())
            Text(pairing.origin).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
            Label("companion.readOnly".localized(), systemImage: "eye").font(.callout)
            Text("\("companion.expires".localized()) \(pairing.device.expiresAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption).foregroundStyle(.secondary)
            Text("companion.manualHint".localized()).font(.caption).foregroundStyle(.secondary)
            Button("companion.copyCode".localized(), action: copyCode)
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
