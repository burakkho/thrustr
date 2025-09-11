import SwiftUI
import SwiftData
import CoreLocation

struct CardioPreparationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    
    let activityType: CardioTimerViewModel.CardioActivityType
    let isOutdoor: Bool
    let user: User
    
    @State private var locationManager = LocationManager.shared
    @State private var bluetoothManager = BluetoothManager()
    
    @State private var gpsStatus: GPSStatus = .checking
    @State private var bluetoothStatus: BluetoothStatus = .notConnected
    @State private var showingBluetoothSheet = false
    @State private var showingLiveTracking = false
    @State private var isReady = false
    
    // GPS Status
    enum GPSStatus {
        case checking, ready, weak, noSignal, notNeeded
        
        var icon: String {
            switch self {
            case .checking: return "location.circle"
            case .ready: return "location.fill"
            case .weak: return "location.slash"
            case .noSignal: return "location.slash.fill"
            case .notNeeded: return "location"
            }
        }
        
        var color: Color {
            switch self {
            case .checking: return .orange
            case .ready: return .green
            case .weak: return .yellow
            case .noSignal: return .red
            case .notNeeded: return .gray
            }
        }
        
        var message: String {
            switch self {
            case .checking: return "GPS aranıyor..."
            case .ready: return "GPS hazır"
            case .weak: return "GPS sinyali zayıf"
            case .noSignal: return "GPS sinyali yok"
            case .notNeeded: return "İç mekan - GPS gerekmez"
            }
        }
    }
    
    // Bluetooth Status
    enum BluetoothStatus {
        case notConnected, scanning, connected
        
        var icon: String {
            switch self {
            case .notConnected: return "heart.slash"
            case .scanning: return "heart.circle"
            case .connected: return "heart.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .notConnected: return .gray
            case .scanning: return .orange
            case .connected: return .green
            }
        }
        
        var message: String {
            switch self {
            case .notConnected: return TrainingKeys.CardioPreparation.heartRateBandNotConnected.localized
            case .scanning: return TrainingKeys.CardioPreparation.heartRateBandScanning.localized
            case .connected: return TrainingKeys.CardioPreparation.heartRateBandConnected.localized
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView
                
                ScrollView {
                    VStack(spacing: theme.spacing.xl) {
                        // Activity Info
                        activityInfoCard
                        
                        // GPS Status (if outdoor)
                        if isOutdoor {
                            gpsStatusCard
                        }
                        
                        // Heart Rate Status
                        heartRateStatusCard
                        
                        // Ready Status
                        readyStatusCard
                        
                        // Start Button
                        startButton
                    }
                    .padding(theme.spacing.m)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                prepareServices()
            }
            .sheet(isPresented: $showingBluetoothSheet) {
                BluetoothDeviceSelectionSheet(
                    bluetoothManager: bluetoothManager,
                    onDeviceSelected: { device in
                        connectToDevice(device)
                    }
                )
            }
            .fullScreenCover(isPresented: $showingLiveTracking) {
                CardioLiveTrackingView(
                    activityType: activityType,
                    isOutdoor: isOutdoor,
                    user: user
                )
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(TrainingKeys.CardioPreparation.preparation.localized)
                    .font(theme.typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(TrainingKeys.CardioPreparation.preparingWorkout.localized)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
        .padding(theme.spacing.m)
        .background(theme.colors.backgroundSecondary)
    }
    
    // MARK: - Activity Info Card
    private var activityInfoCard: some View {
        VStack(spacing: theme.spacing.m) {
            Image(systemName: activityType.icon)
                .font(.system(size: 48))
                .foregroundColor(theme.colors.accent)
            
            Text(activityType.displayName)
                .font(theme.typography.title3)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
            
            Text(isOutdoor ? "Dış Mekan" : "İç Mekan")
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(theme.spacing.l)
        .background(theme.colors.backgroundSecondary)
        .cornerRadius(theme.radius.m)
    }
    
    // MARK: - GPS Status Card
    private var gpsStatusCard: some View {
        HStack(spacing: theme.spacing.m) {
            // Icon with animation
            ZStack {
                if gpsStatus == .checking {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: gpsStatus.icon)
                        .font(.title2)
                        .foregroundColor(gpsStatus.color)
                }
            }
            .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("GPS Durumu")
                    .font(theme.typography.headline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(gpsStatus.message)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
                
                if locationManager.locationAccuracy != LocationManager.LocationAccuracy.noSignal {
                    HStack(spacing: 4) {
                        ForEach(0..<4) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(signalBarColor(for: index))
                                .frame(width: 4, height: CGFloat(8 + index * 3))
                        }
                    }
                }
            }
            
            Spacer()
            
            if gpsStatus == .ready {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.green)
            }
        }
        .padding(theme.spacing.m)
        .background(theme.colors.backgroundSecondary)
        .cornerRadius(theme.radius.m)
    }
    
    // MARK: - Heart Rate Status Card
    private var heartRateStatusCard: some View {
        HStack(spacing: theme.spacing.m) {
            // Icon
            ZStack {
                if bluetoothStatus == .scanning {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: bluetoothStatus.icon)
                        .font(.title2)
                        .foregroundColor(bluetoothStatus.color)
                }
            }
            .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Nabız Bandı")
                    .font(theme.typography.headline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(bluetoothStatus.message)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
                
                if bluetoothStatus == .connected,
                   let device = bluetoothManager.connectedDevice {
                    Text(device.name)
                        .font(theme.typography.caption2)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            
            Spacer()
            
            if bluetoothStatus == .notConnected {
                Button(action: { showingBluetoothSheet = true }) {
                    Text(TrainingKeys.CardioPreparation.connect.localized)
                        .font(theme.typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.accent)
                        .padding(.horizontal, theme.spacing.m)
                        .padding(.vertical, theme.spacing.s)
                        .background(theme.colors.accent.opacity(0.1))
                        .cornerRadius(theme.radius.s)
                }
            } else if bluetoothStatus == .connected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.green)
            }
        }
        .padding(theme.spacing.m)
        .background(theme.colors.backgroundSecondary)
        .cornerRadius(theme.radius.m)
    }
    
    // MARK: - Ready Status Card
    private var readyStatusCard: some View {
        VStack(spacing: theme.spacing.m) {
            if isReady {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                    .symbolRenderingMode(.hierarchical)
                
                Text(TrainingKeys.CardioPreparation.allReady.localized)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(TrainingKeys.CardioPreparation.canStartWorkout.localized)
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textSecondary)
            } else {
                Image(systemName: "clock.circle")
                    .font(.system(size: 60))
                    .foregroundColor(theme.colors.textSecondary)
                    .symbolRenderingMode(.hierarchical)
                
                Text(TrainingKeys.CardioPreparation.preparing.localized)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(getNotReadyReason())
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(theme.spacing.l)
        .background(
            RoundedRectangle(cornerRadius: theme.radius.m)
                .fill(isReady ? Color.green.opacity(0.1) : theme.colors.backgroundSecondary)
        )
    }
    
    // MARK: - Start Button
    private var startButton: some View {
        Button(action: startWorkout) {
            HStack {
                Image(systemName: "play.fill")
                    .font(.title3)
                Text(TrainingKeys.CardioPreparation.start.localized)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(theme.spacing.l)
            .background(
                isReady ? theme.colors.accent : theme.colors.textSecondary.opacity(0.5)
            )
            .cornerRadius(theme.radius.m)
        }
        .disabled(!isReady)
    }
    
    // MARK: - Helper Methods
    private func prepareServices() {
        // GPS Setup (if outdoor)
        if isOutdoor {
            // Only request authorization if not already authorized
            if !locationManager.isAuthorized {
                locationManager.requestAuthorization()
            }
            
            // Check GPS status after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                checkGPSStatus()
            }
            
            // Start monitoring GPS
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                Task { @MainActor in
                    checkGPSStatus()
                }
            }
        } else {
            gpsStatus = .notNeeded
        }
        
        // Bluetooth Setup
        if bluetoothManager.isBluetoothEnabled {
            bluetoothStatus = .notConnected
        }
        
        // Check readiness
        checkReadiness()
    }
    
    private func checkGPSStatus() {
        guard isOutdoor else {
            gpsStatus = .notNeeded
            checkReadiness()
            return
        }
        
        if !locationManager.isAuthorized {
            gpsStatus = .noSignal
        } else {
            switch locationManager.locationAccuracy {
            case .excellent, .good:
                gpsStatus = .ready
                locationManager.startTracking() // Start early for better accuracy
            case .poor:
                gpsStatus = .weak
            case .noSignal:
                gpsStatus = .checking
            }
        }
        
        checkReadiness()
    }
    
    private func checkReadiness() {
        if isOutdoor {
            isReady = (gpsStatus == .ready || gpsStatus == .weak)
        } else {
            isReady = true
        }
    }
    
    private func getNotReadyReason() -> String {
        if isOutdoor && (gpsStatus == .checking || gpsStatus == .noSignal) {
            return "GPS sinyali bekleniyor..."
        }
        return "Lütfen bekleyin..."
    }
    
    private func signalBarColor(for index: Int) -> Color {
        switch locationManager.locationAccuracy {
        case .excellent:
            return theme.colors.success
        case .good:
            return index < 3 ? theme.colors.success : theme.colors.backgroundSecondary
        case .poor:
            return index < 2 ? theme.colors.warning : theme.colors.backgroundSecondary
        case .noSignal:
            return theme.colors.backgroundSecondary
        }
    }
    
    private func connectToDevice(_ device: BluetoothManager.BluetoothDevice) {
        bluetoothStatus = .scanning
        bluetoothManager.connect(to: device)
        
        // Monitor connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if bluetoothManager.isConnected {
                bluetoothStatus = .connected
            } else {
                bluetoothStatus = .notConnected
            }
        }
        
        showingBluetoothSheet = false
    }
    
    private func startWorkout() {
        showingLiveTracking = true
    }
}

// MARK: - Bluetooth Device Selection Sheet
struct BluetoothDeviceSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    
    var bluetoothManager: BluetoothManager
    let onDeviceSelected: (BluetoothManager.BluetoothDevice) -> Void
    
    var body: some View {
        NavigationStack {
            List {
                if bluetoothManager.isScanning {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Nabız bantları aranıyor...")
                            .font(theme.typography.body)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    .padding(.vertical, theme.spacing.m)
                }
                
                ForEach(bluetoothManager.discoveredDevices) { device in
                    Button(action: { onDeviceSelected(device) }) {
                        HStack {
                            Image(systemName: "heart.circle.fill")
                                .font(.title2)
                                .foregroundColor(theme.colors.error)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(device.name)
                                    .font(theme.typography.body)
                                    .foregroundColor(theme.colors.textPrimary)
                                
                                Text("Sinyal: \(device.signalStrength)")
                                    .font(theme.typography.caption)
                                    .foregroundColor(theme.colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                        .padding(.vertical, theme.spacing.s)
                    }
                }
                
                if !bluetoothManager.isScanning && bluetoothManager.discoveredDevices.isEmpty {
                    VStack(spacing: theme.spacing.m) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 48))
                            .foregroundColor(theme.colors.textSecondary)
                        
                        Text(TrainingKeys.CardioPreparation.deviceNotFound.localized)
                            .font(theme.typography.headline)
                            .foregroundColor(theme.colors.textPrimary)
                        
                        Text(TrainingKeys.CardioPreparation.ensureDeviceOn.localized)
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            }
            .navigationTitle(TrainingKeys.CardioPreparation.selectHeartRateBand.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(TrainingKeys.CardioPreparation.cancel.localized) { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Yeniden Tara") {
                        bluetoothManager.startScanning()
                    }
                    .disabled(bluetoothManager.isScanning)
                }
            }
        }
        .onAppear {
            bluetoothManager.startScanning()
        }
    }
}

#Preview {
    CardioPreparationView(
        activityType: .running,
        isOutdoor: true,
        user: User(
            name: "Test User",
            age: 30,
            gender: .male,
            height: 180,
            currentWeight: 75,
            fitnessGoal: .maintain,
            activityLevel: .moderate,
            selectedLanguage: "tr"
        )
    )
}