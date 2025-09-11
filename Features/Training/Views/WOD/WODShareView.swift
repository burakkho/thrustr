import SwiftUI
import SwiftData

struct WODShareView: View {
    let wod: WOD
    let result: WODResult?
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var shareImage: UIImage?
    @State private var isSharing = false
    @State private var qrCodeString: String = ""
    @State private var showingQRCode = true
    @State private var errorMessage: String?
    
    private var shareText: String {
        var text = "🏋️ WOD: \(wod.name)\n"
        text += "Type: \(wod.wodType.displayName)\n\n"
        
        // Add movements
        text += "Movements:\n"
        for (index, movement) in (wod.movements ?? []).enumerated() {
            text += "\(index + 1). \(movement.fullDisplayText)\n"
        }
        
        // Add rep scheme
        if !wod.repScheme.isEmpty {
            text += "\nRep Scheme: \(wod.formattedRepScheme)\n"
        }
        
        // Add time cap
        if let timeCap = wod.formattedTimeCap {
            text += "Time Cap: \(timeCap)\n"
        }
        
        // Add result if available
        if let result = result {
            text += "\n🏆 My Result: \(result.displayScore)"
            if result.isRX {
                text += " (RX)"
            }
            if let notes = result.notes {
                text += "\nNotes: \(notes)"
            }
        }
        
        text += "\n\n#CrossFit #WOD #Thrustr"
        
        return text
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.xl) {
                    // Tab Selector
                    Picker("Share Mode", selection: $showingQRCode) {
                        Text("QR Code").tag(true)
                        Text("Image").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    if showingQRCode {
                        // QR Code View
                        VStack(spacing: theme.spacing.l) {
                            if !qrCodeString.isEmpty {
                                QRCodeView(data: qrCodeString, size: 280)
                                    .padding()
                            } else if let error = errorMessage {
                                VStack(spacing: theme.spacing.m) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.largeTitle)
                                        .foregroundColor(theme.colors.error)
                                    Text(error)
                                        .font(theme.typography.body)
                                        .foregroundColor(theme.colors.textSecondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding()
                            } else {
                                ProgressView("Generating QR Code...")
                                    .padding()
                            }
                        }
                    } else {
                        // Preview Card
                        WODShareCard(wod: wod, result: result)
                            .scaleEffect(0.9)
                            .background(
                                GeometryReader { geometry in
                                    Color.clear
                                        .onAppear {
                                            generateShareImage(size: geometry.size)
                                        }
                                }
                            )
                    }
            
                    // Share Options
                    VStack(spacing: theme.spacing.m) {
                        if showingQRCode {
                            Button(action: shareQRCode) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share QR Code")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(theme.colors.accent)
                                .foregroundColor(.white)
                                .cornerRadius(theme.radius.m)
                            }
                        } else {
                            Button(action: shareAsImage) {
                                HStack {
                                    Image(systemName: "photo")
                                    Text("Share as Image")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(theme.colors.accent)
                                .foregroundColor(.white)
                                .cornerRadius(theme.radius.m)
                            }
                        }
                        
                        Button(action: shareAsText) {
                            HStack {
                                Image(systemName: "text.quote")
                                Text("Share as Text")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(theme.colors.backgroundSecondary)
                            .foregroundColor(theme.colors.textPrimary)
                            .cornerRadius(theme.radius.m)
                        }
                        
                        Button(action: copyToClipboard) {
                            HStack {
                                Image(systemName: "doc.on.clipboard")
                                Text(showingQRCode ? "Copy QR Data" : "Copy to Clipboard")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(theme.colors.backgroundSecondary)
                            .foregroundColor(theme.colors.textPrimary)
                            .cornerRadius(theme.radius.m)
                        }
                    }
                    .padding()
                }
                .padding(.bottom)
            }
            .navigationTitle(TrainingKeys.Navigation.shareWOD.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(TrainingKeys.Common.done.localized) { dismiss() }
                }
            }
            .sheet(isPresented: $isSharing) {
                if let image = shareImage {
                    ShareSheet(items: [image, shareText])
                } else {
                    ShareSheet(items: [shareText])
                }
            }
            .onAppear {
                generateQRCode()
            }
        }
    }
    
    private func generateShareImage(size: CGSize) {
        let hostingController = UIHostingController(
            rootView: WODShareCard(wod: wod, result: result)
                .frame(width: size.width, height: size.height)
                .background(Color.white)
        )
        hostingController.view.bounds = CGRect(origin: .zero, size: size)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        shareImage = renderer.image { _ in
            hostingController.view.drawHierarchy(in: hostingController.view.bounds, afterScreenUpdates: true)
        }
    }
    
    private func shareAsImage() {
        isSharing = true
    }
    
    private func shareAsText() {
        isSharing = true
    }
    
    private func copyToClipboard() {
        if showingQRCode {
            UIPasteboard.general.string = qrCodeString
        } else {
            UIPasteboard.general.string = shareText
        }
        HapticManager.shared.notification(.success)
    }
    
    private func generateQRCode() {
        do {
            let qrData = WODQRData(from: wod)
            qrCodeString = try qrData.toQRString()
        } catch {
            errorMessage = "Unable to generate QR code: \(error.localizedDescription)"
        }
    }
    
    private func shareQRCode() {
        // Generate QR image for sharing
        if let qrImage = QRCodeGenerator.shared.generateQRCode(from: qrCodeString, size: CGSize(width: 512, height: 512)) {
            shareImage = qrImage
            isSharing = true
        }
    }
}

// MARK: - WOD Share Card
struct WODShareCard: View {
    let wod: WOD
    let result: WODResult?
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            wodDetailsSection
            footerSection
        }
        .background(Color.white)
        .cornerRadius(theme.radius.l)
        .shadow(radius: 10)
    }
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: theme.spacing.m) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .font(.title)
                    .foregroundColor(.white)
                
                Text("Thrustr")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Text(Date().formatted(date: .abbreviated, time: .omitted))
                .font(theme.typography.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            LinearGradient(
                colors: [theme.colors.accent, theme.colors.accent.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    @ViewBuilder
    private var wodDetailsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.l) {
            wodNameAndTypeRow
            Divider()
            movementsSection
            personalRecordBadge
        }
        .padding()
    }
    
    @ViewBuilder  
    private var wodNameAndTypeRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(wod.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                HStack(spacing: theme.spacing.m) {
                    Label(wod.wodType.displayName, systemImage: "timer")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                    
                    if !wod.repScheme.isEmpty {
                        repSchemeChip
                    }
                }
            }
            
            Spacer()
            
            if let result = result {
                resultDisplay(result)
            }
        }
    }
    
    @ViewBuilder
    private var repSchemeChip: some View {
        Text(wod.formattedRepScheme)
            .font(theme.typography.caption)
            .fontWeight(.medium)
            .padding(.horizontal, theme.spacing.s)
            .padding(.vertical, 2)
            .background(theme.colors.accent.opacity(0.1))
            .foregroundColor(theme.colors.accent)
            .cornerRadius(theme.radius.s)
    }
    
    @ViewBuilder
    private func resultDisplay(_ result: WODResult) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(result.displayScore)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.success)
            
            if result.isRX {
                rxBadge
            }
        }
    }
    
    @ViewBuilder
    private var rxBadge: some View {
        Text("RX")
            .font(theme.typography.caption)
            .fontWeight(.bold)
            .padding(.horizontal, theme.spacing.s)
            .padding(.vertical, 2)
            .background(theme.colors.success)
            .foregroundColor(.white)
            .cornerRadius(theme.radius.s)
    }
    
    @ViewBuilder
    private var movementsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            Text("MOVEMENTS")
                .font(theme.typography.caption)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textSecondary)
            
            ForEach(Array((wod.movements ?? []).enumerated()), id: \.element.id) { index, movement in
                movementRow(index: index, movement: movement)
            }
        }
    }
    
    @ViewBuilder
    private func movementRow(index: Int, movement: WODMovement) -> some View {
        HStack(spacing: theme.spacing.m) {
            Text("\(index + 1).")
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
                .frame(width: 20)
            
            Text(movement.fullDisplayText)
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textPrimary)
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var personalRecordBadge: some View {
        if let pr = wod.personalRecord, pr.id == result?.id {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(theme.colors.warning)
                Text("PERSONAL RECORD!")
                    .font(theme.typography.caption)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.warning)
            }
            .frame(maxWidth: .infinity)
            .padding(theme.spacing.m)
            .background(theme.colors.warning.opacity(0.1))
            .cornerRadius(theme.radius.m)
        }
    }
    
    @ViewBuilder
    private var footerSection: some View {
        HStack {
            Text("#CrossFit #WOD #Fitness")
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
            
            Spacer()
            
            Text("thrustr.app")
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.accent)
        }
        .padding()
        .background(theme.colors.backgroundSecondary)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
