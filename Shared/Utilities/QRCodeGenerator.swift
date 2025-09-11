import SwiftUI
@preconcurrency import CoreImage
@preconcurrency import CoreImage.CIFilterBuiltins

final class QRCodeGenerator: Sendable {
    static let shared = QRCodeGenerator()
    private nonisolated(unsafe) let context = CIContext()
    
    private init() {}
    
    func generateQRCode(from string: String, size: CGSize = CGSize(width: 300, height: 300)) -> UIImage? {
        // Check data size (QR codes have limits)
        guard string.utf8.count < 2953 else { // QR Code version 40 limit
            print("QR data too large: \(string.utf8.count) bytes")
            return nil
        }
        
        // Create QR filter
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M" // Medium error correction
        
        guard let ciImage = filter.outputImage else { return nil }
        
        // Scale the image to desired size
        let scaleX = size.width / ciImage.extent.size.width
        let scaleY = size.height / ciImage.extent.size.height
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        // Convert to UIImage
        if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        
        return nil
    }
    
    func generateQRCodeView(from string: String, size: CGFloat = 250) -> some View {
        QRCodeView(data: string, size: size)
    }
}

// SwiftUI View for QR Code
struct QRCodeView: View {
    let data: String
    let size: CGFloat
    @State private var qrImage: UIImage?
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: theme.spacing.m) {
            if let qrImage = qrImage {
                Image(uiImage: qrImage)
                    .interpolation(.none) // Prevents blurring
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .background(Color.white)
                    .cornerRadius(theme.radius.m)
                    .shadow(radius: 5)
            } else {
                // Loading or error state
                RoundedRectangle(cornerRadius: theme.radius.m)
                    .fill(theme.colors.backgroundSecondary)
                    .frame(width: size, height: size)
                    .overlay(
                        VStack(spacing: theme.spacing.m) {
                            ProgressView()
                            Text("Generating QR Code...")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                    )
            }
            
            // Instructions
            VStack(spacing: theme.spacing.s) {
                Label("Scan to Start WOD", systemImage: "qrcode.viewfinder")
                    .font(theme.typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text("Friends can scan this code to start the same workout")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .onAppear {
            generateQRCode()
        }
        .onChange(of: data) { oldValue, newValue in
            generateQRCode()
        }
    }
    
    private func generateQRCode() {
        Task {
            let image = await Task.detached {
                QRCodeGenerator.shared.generateQRCode(
                    from: data,
                    size: CGSize(width: size * 3, height: size * 3) // Higher res for quality
                )
            }.value
            
            await MainActor.run {
                withAnimation {
                    self.qrImage = image
                }
            }
        }
    }
}

// Preview helper
struct QRCodeView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeView(data: "Sample WOD Data", size: 250)
            .padding()
            .background(Color.gray.opacity(0.1))
    }
}