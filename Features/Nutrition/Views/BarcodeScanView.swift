import SwiftUI
import AVFoundation
#if canImport(VisionKit)
import VisionKit
#endif
#if canImport(Vision)
import Vision
#endif

struct BarcodeScanView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var permissionDenied = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var lastScannedAt: Date = .distantPast
    @State private var didScan = false

    let onScanned: (String) -> Void

    private let debounceInterval: TimeInterval = 1.2

    var body: some View {
        ZStack {
            scannerBody

            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.ultraThinMaterial)
                            .symbolRenderingMode(.multicolor)
                    }
                    .padding()
                    Spacer()
                }
                Spacer()

                VStack(spacing: 10) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                    Text(LocalizationKeys.Nutrition.FoodSelection.title.localized)
                        .font(.headline)
                        .foregroundColor(.white)
                        .shadow(radius: 3)
                        .padding(.bottom, 8)
                }
                .padding(.bottom, 30)
            }

            // Framing overlay
            Rectangle()
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 260, height: 160)
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear { checkPermission() }
        .alert(LocalizationKeys.Common.error.localized, isPresented: $permissionDenied) {
            Button(LocalizationKeys.Common.close.localized, role: .cancel) { dismiss() }
            Button("Ayarlar") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Barkod tarama için kamera izni gereklidir.")
        }
        .alert(LocalizationKeys.Common.error.localized, isPresented: .constant(errorMessage != nil)) {
            Button(LocalizationKeys.Common.ok.localized) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var scannerBody: some View {
        if permissionDenied {
            Color.black
        } else {
            if #available(iOS 17.0, *), DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                DataScannerContainer(
                    symbologies: [.ean8, .ean13, .upce, .code128],
                    onCode: handleScanned(code:)
                )
            } else {
                AVScannerContainer(
                    onCode: handleScanned(code:),
                    onError: { error in
                        DispatchQueue.main.async {
                            errorMessage = error
                        }
                    }
                )
            }
        }
    }

    private func handleScanned(code: String) {
        // Debounce rapid scans
        guard !didScan else { return }
        let now = Date()
        guard now.timeIntervalSince(lastScannedAt) > debounceInterval else { return }
        lastScannedAt = now

        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
        
        // Move state changes to async to avoid "Modifying state during view update"
        DispatchQueue.main.async {
            didScan = true
            isLoading = true
        }
        
        // Hand off to caller and dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            onScanned(code)
            isLoading = false
            dismiss()
        }
    }

    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionDenied = false
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { self.permissionDenied = !granted }
            }
        default:
            permissionDenied = true
        }
    }
}

#if canImport(VisionKit)
@available(iOS 17.0, *)
private struct DataScannerContainer: UIViewControllerRepresentable {
    let symbologies: [VNBarcodeSymbology]
    let onCode: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let vc = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: symbologies)],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        guard uiViewController.isScanning == false else { return }
        do {
            try uiViewController.startScanning()
        } catch {
            // Surface the error via an overlay alert by bridging through NotificationCenter
            // or simply print and rely on parent alert binding if needed later
            print("DataScanner startScanning error: \(error)")
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(onCode: onCode) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let onCode: (String) -> Void
        init(onCode: @escaping (String) -> Void) { self.onCode = onCode }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            process(items: addedItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            process(items: updatedItems)
        }

        private func process(items: [RecognizedItem]) {
            for item in items {
                if case .barcode(let barcode) = item, let payload = barcode.payloadStringValue, !payload.isEmpty {
                    onCode(payload)
                    break
                }
            }
        }
    }
}
#endif

// MARK: - AVFoundation fallback
private struct AVScannerContainer: UIViewControllerRepresentable {
    final class ScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
        private let session = AVCaptureSession()
        private let previewLayer = AVCaptureVideoPreviewLayer()
        private let onCode: (String) -> Void
        private let onError: (String) -> Void

        init(onCode: @escaping (String) -> Void, onError: @escaping (String) -> Void) {
            self.onCode = onCode
            self.onError = onError
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .black
            setupSession()
        }

        private func setupSession() {
            guard let device = AVCaptureDevice.default(for: .video), let input = try? AVCaptureDeviceInput(device: device) else {
                onError("Kamera başlatılamadı")
                return
            }
            session.beginConfiguration()
            if session.canAddInput(input) { session.addInput(input) }

            let output = AVCaptureMetadataOutput()
            if session.canAddOutput(output) { session.addOutput(output) }
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.ean8, .ean13, .upce, .code128]

            previewLayer.session = session
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)

            session.commitConfiguration()
            session.startRunning()
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject, let str = obj.stringValue, !str.isEmpty else { return }
            session.stopRunning()
            onCode(str)
        }
    }

    let onCode: (String) -> Void
    let onError: (String) -> Void

    func makeUIViewController(context: Context) -> ScannerController {
        ScannerController(onCode: onCode, onError: onError)
    }

    func updateUIViewController(_ uiViewController: ScannerController, context: Context) {}
}


