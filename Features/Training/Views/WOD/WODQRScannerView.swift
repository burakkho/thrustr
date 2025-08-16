import SwiftUI
import AVFoundation
import SwiftData

struct WODQRScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Query private var user: [User]
    
    @State private var scannedWOD: WOD?
    @State private var showingTimer = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var isProcessing = false
    
    private var currentUser: User? {
        user.first
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Camera View
                QRScannerViewRepresentable(
                    onCodeScanned: handleScannedCode,
                    isProcessing: $isProcessing
                )
                .ignoresSafeArea()
                
                // Overlay
                VStack {
                    // Top Bar
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(theme.radius.m)
                        
                        Spacer()
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Scanning Frame
                    RoundedRectangle(cornerRadius: theme.radius.l)
                        .stroke(theme.colors.accent, lineWidth: 3)
                        .frame(width: 250, height: 250)
                        .overlay(
                            // Corner markers
                            GeometryReader { geometry in
                                let cornerLength: CGFloat = 20
                                let lineWidth: CGFloat = 4
                                
                                // Top-left
                                Path { path in
                                    path.move(to: CGPoint(x: 0, y: cornerLength))
                                    path.addLine(to: CGPoint(x: 0, y: 0))
                                    path.addLine(to: CGPoint(x: cornerLength, y: 0))
                                }
                                .stroke(theme.colors.accent, lineWidth: lineWidth)
                                
                                // Top-right
                                Path { path in
                                    path.move(to: CGPoint(x: geometry.size.width - cornerLength, y: 0))
                                    path.addLine(to: CGPoint(x: geometry.size.width, y: 0))
                                    path.addLine(to: CGPoint(x: geometry.size.width, y: cornerLength))
                                }
                                .stroke(theme.colors.accent, lineWidth: lineWidth)
                                
                                // Bottom-left
                                Path { path in
                                    path.move(to: CGPoint(x: 0, y: geometry.size.height - cornerLength))
                                    path.addLine(to: CGPoint(x: 0, y: geometry.size.height))
                                    path.addLine(to: CGPoint(x: cornerLength, y: geometry.size.height))
                                }
                                .stroke(theme.colors.accent, lineWidth: lineWidth)
                                
                                // Bottom-right
                                Path { path in
                                    path.move(to: CGPoint(x: geometry.size.width - cornerLength, y: geometry.size.height))
                                    path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                                    path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height - cornerLength))
                                }
                                .stroke(theme.colors.accent, lineWidth: lineWidth)
                            }
                        )
                    
                    Spacer()
                    
                    // Instructions
                    VStack(spacing: theme.spacing.m) {
                        if isProcessing {
                            HStack {
                                ProgressView()
                                    .tint(theme.colors.accent)
                                Text("Processing WOD...")
                                    .font(theme.typography.body)
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(theme.radius.m)
                        } else {
                            Text("Scan WOD QR Code")
                                .font(theme.typography.headline)
                                .foregroundColor(.white)
                            
                            Text("Position the QR code within the frame")
                                .font(theme.typography.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding()
                    .padding(.bottom, 50)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {
                    errorMessage = nil
                    isProcessing = false
                }
            } message: {
                Text(errorMessage ?? "Unknown error occurred")
            }
            .fullScreenCover(isPresented: $showingTimer) {
                if let wod = scannedWOD {
                    EnhancedWODTimerView(
                        wod: wod,
                        movements: wod.movements,
                        isRX: true
                    )
                }
            }
        }
    }
    
    private func handleScannedCode(_ code: String) {
        guard !isProcessing else { return }
        isProcessing = true
        
        // Haptic feedback
        HapticManager.shared.notification(.success)
        
        // Parse QR code
        do {
            let qrData = try WODQRData.fromQRString(code)
            let wod = qrData.toWOD()
            
            // Set default weights based on user gender
            for movement in wod.movements {
                if let rxWeight = movement.rxWeight(for: currentUser?.gender) {
                    // Parse weight value
                    let numbers = rxWeight.filter { "0123456789.".contains($0) }
                    if let weight = Double(numbers) {
                        movement.userWeight = weight
                        movement.isRX = true
                    }
                }
            }
            
            scannedWOD = wod
            
            // Small delay for UI feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isProcessing = false
                showingTimer = true
                dismiss() // Dismiss scanner when timer opens
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
            isProcessing = false
        }
    }
}

// MARK: - Camera View Representable
struct QRScannerViewRepresentable: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void
    @Binding var isProcessing: Bool
    
    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {
        uiViewController.isProcessing = isProcessing
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeScanned: onCodeScanned)
    }
    
    class Coordinator: NSObject, QRScannerDelegate {
        let onCodeScanned: (String) -> Void
        
        init(onCodeScanned: @escaping (String) -> Void) {
            self.onCodeScanned = onCodeScanned
        }
        
        func didScanCode(_ code: String) {
            onCodeScanned(code)
        }
    }
}

// MARK: - QR Scanner View Controller
protocol QRScannerDelegate: AnyObject {
    func didScanCode(_ code: String)
}

class QRScannerViewController: UIViewController {
    weak var delegate: QRScannerDelegate?
    var isProcessing = false
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startScanning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let captureSession = captureSession,
              let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                return
            }
            
            let metadataOutput = AVCaptureMetadataOutput()
            
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            } else {
                return
            }
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.videoGravity = .resizeAspectFill
            
            if let previewLayer = previewLayer {
                view.layer.addSublayer(previewLayer)
            }
        } catch {
            print("Failed to setup camera: \(error)")
        }
    }
    
    private func startScanning() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    private func stopScanning() {
        captureSession?.stopRunning()
    }
}

// MARK: - Metadata Output Delegate
extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                       didOutput metadataObjects: [AVMetadataObject],
                       from connection: AVCaptureConnection) {
        guard !isProcessing else { return }
        
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           metadataObject.type == .qr,
           let stringValue = metadataObject.stringValue {
            delegate?.didScanCode(stringValue)
        }
    }
}