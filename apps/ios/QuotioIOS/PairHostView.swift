import SwiftUI
import AVFoundation
import UIKit
import VisionKit
import QuotioMobile

struct PairHostView: View {
    @Environment(HostStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var origin = ""
    @State private var token = ""
    @State private var payload: Pairing?
    @State private var scanner = false
    @State private var advanced = false
    @State private var working = false
    @State private var connected = false
    @State private var error: String?
    @State private var task: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            Form {
                if connected {
                    Section {
                        Label("Connected", systemImage: "checkmark.circle.fill")
                            .font(.title2.weight(.semibold)).foregroundStyle(.green)
                        TextField("Computer name", text: $name).textContentType(.nickname)
                        if let payload { Text("Access expires \(payload.expiresAt.formatted(date: .abbreviated, time: .shortened))") }
                    } footer: {
                        Text("You can now view this computer's quota and add widgets.")
                    }
                    Section { Button("Done") { store.renameSelected(to: name); dismiss() } }
                } else if working {
                    Section {
                        HStack {
                            ProgressView()
                            Text("Connecting to \(name)…")
                        }
                    }
                } else {
                    Section {
                        Text("1. On your Mac, open Quotio and choose Pair iPhone.\n2. Choose Local network or Tailscale IP, then create a pairing code.\n3. Scan or paste the code here.")
                    }
                    Section {
                        Button("Scan pairing code", systemImage: "qrcode.viewfinder") { requestScanner() }
                            .buttonStyle(.borderedProminent)
                        PasteButton(payloadType: String.self) { values in
                            if let text = values.first { acceptCode(text) }
                        }
                        Text("The code grants read-only access. Keep it private.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Section {
                        DisclosureGroup("Advanced: HTTPS proxy", isExpanded: $advanced) {
                            TextField("Computer name", text: $name).textContentType(.nickname)
                            TextField("https://computer.example", text: $origin)
                                .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                                .onChange(of: origin) { if payload?.origin != origin { payload = nil } }
                            SecureField("Read-only device token", text: $token)
                                .textInputAutocapitalization(.never).autocorrectionDisabled()
                                .onChange(of: token) { if payload?.token != token { payload = nil } }
                            Button("Connect") { connect() }
                                .disabled(origin.isEmpty || token.isEmpty)
                        }
                    } footer: {
                        Text("For custom HTTPS proxies only. Check the address before connecting.")
                    }
                    if let error {
                        Section {
                            Label(error, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red)
                            if payload != nil { Button("Try again") { connect() } }
                        }
                    }
                }
            }
                .navigationTitle("Add computer").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { task?.cancel(); dismiss() } } }
                .sheet(isPresented: $scanner) {
                    QRScanner { text in
                        scanner = false
                        acceptCode(text)
                    }
                    .ignoresSafeArea()
                    .overlay(alignment: .bottom) {
                        VStack(spacing: 16) {
                            Text("Point the camera at the code on your Mac.")
                                .padding(10).background(.regularMaterial, in: Capsule())
                            Button("Cancel") { scanner = false }.buttonStyle(.borderedProminent)
                        }.padding(30)
                    }
                }
        }.onDisappear { task?.cancel(); token = ""; payload = nil }
    }

    private func requestScanner() {
        Task {
            if !DataScannerViewController.isSupported { error = String(localized: "QR scanning is unavailable. Paste the pairing code instead.") }
            else if await AVCaptureDevice.requestAccess(for: .video) { scanner = true }
            else { error = String(localized: "Camera access is off. Paste the code, or allow Camera access in Settings.") }
        }
    }

    private func acceptCode(_ text: String) {
        do {
            let decoded = try Pairing.decode(Data(text.utf8))
            name = decoded.hostName; origin = decoded.origin; token = decoded.token
            payload = decoded; error = nil
            if decoded.certificate != nil { connect() }
            else { advanced = true }
        } catch { self.error = String(localized: "This pairing code is invalid or has expired.") }
    }

    private func connect() {
        guard !working else { return }
        working = true; error = nil
        task = Task {
            do {
                try await store.pair(name: name, origin: origin, token: token, pairing: payload)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                connected = true
            } catch is CancellationError { }
            catch { self.error = HostStore.message(error) }
            working = false
        }
    }
}

struct QRScanner: UIViewControllerRepresentable {
    let scanned: (String) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(scanned: scanned) }
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(recognizedDataTypes: [.barcode(symbologies: [.qr])],
                                                   qualityLevel: .balanced, recognizesMultipleItems: false,
                                                   isGuidanceEnabled: true, isHighlightingEnabled: true)
        controller.delegate = context.coordinator
        return controller
    }
    func updateUIViewController(_ controller: DataScannerViewController, context: Context) {
        guard !controller.isScanning else { return }
        do { try controller.startScanning() }
        catch { context.coordinator.scanned("") }
    }
    static func dismantleUIViewController(_ controller: DataScannerViewController, coordinator: Coordinator) { controller.stopScanning() }
    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let scanned: (String) -> Void
        private var didScan = false
        init(scanned: @escaping (String) -> Void) { self.scanned = scanned }
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard !didScan else { return }
            for case .barcode(let code) in addedItems {
                if let value = code.payloadStringValue { didScan = true; dataScanner.stopScanning(); scanned(value); return }
            }
        }
    }
}
