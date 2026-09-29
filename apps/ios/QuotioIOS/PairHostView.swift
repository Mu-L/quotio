import SwiftUI
import AVFoundation
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
    @State private var working = false
    @State private var error: String?
    @State private var task: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("On your computer, issue a read-only device credential in Quotio. Connect through your LAN or private VPN using HTTPS.")
                    Button("Scan QR code", systemImage: "qrcode.viewfinder") {
                        Task {
                            if !DataScannerViewController.isSupported { error = String(localized: "QR scanning is unavailable. Enter the connection below.") }
                            else if await AVCaptureDevice.requestAccess(for: .video) { scanner = true }
                            else { error = String(localized: "Camera access is off. Enter the connection below, or enable Camera in Settings.") }
                        }
                    }
                }
                Section {
                    TextField("Host name", text: $name).textContentType(.nickname)
                    TextField("https://computer.example", text: $origin).textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                        .onChange(of: origin) { if payload?.origin != origin { payload = nil } }
                    SecureField("Read-only device token", text: $token).textInputAutocapitalization(.never).autocorrectionDisabled()
                        .onChange(of: token) { if payload?.token != token { payload = nil } }
                } header: { Text("Connection") } footer: {
                    Text("Check the host address before connecting. Your device token will be sent to this address after you tap Connect.")
                }
                if let payload { Section { Text("Credential expires \(payload.expiresAt.formatted())") } }
                if let error { Section { Text(error).foregroundStyle(.red) } }
                Section {
                    Button {
                        working = true; error = nil
                        task = Task {
                            do {
                                try await store.pair(name: name, origin: origin, token: token, pairing: payload)
                                dismiss()
                            } catch is CancellationError { }
                            catch { self.error = HostStore.message(error) }
                            working = false
                        }
                    } label: {
                        HStack { Text("Connect"); Spacer(); if working { ProgressView() } }
                    }.disabled(working || origin.isEmpty || token.isEmpty)
                }
            }.disabled(working)
                .navigationTitle("Add host").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { task?.cancel(); dismiss() } } }
                .sheet(isPresented: $scanner) {
                    QRScanner { text in
                        scanner = false
                        do {
                            let decoded = try Pairing.decode(Data(text.utf8))
                            origin = decoded.origin; token = decoded.token
                            payload = decoded; error = nil
                        } catch { self.error = String(localized: "This is not a valid Quotio device code, or it has expired.") }
                    }.ignoresSafeArea()
                        .overlay(alignment: .bottom) { Button("Cancel") { scanner = false }.buttonStyle(.borderedProminent).padding(30) }
                }
        }.onDisappear { task?.cancel(); token = ""; payload = nil }
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
