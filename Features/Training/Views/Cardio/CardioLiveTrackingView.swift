import SwiftUI
import SwiftData

struct CardioLiveTrackingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var unitSettings: UnitSettings
    
    @State private var viewModel: CardioTimerViewModel
    @State private var showingStopConfirmation = false
    @State private var showingBluetoothSheet = false
    
    let activityType: CardioTimerViewModel.CardioActivityType
    let isOutdoor: Bool
    let user: User
    
    init(activityType: CardioTimerViewModel.CardioActivityType, isOutdoor: Bool, user: User) {
        self.activityType = activityType
        self.isOutdoor = isOutdoor
        self.user = user
        self._viewModel = State(initialValue: CardioTimerViewModel(
            activityType: activityType,
            isOutdoor: isOutdoor,
            user: user
        ))
    }
    
    var body: some View {
        ZStack {
            // Background
            theme.colors.backgroundPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                ScrollView {
                    VStack(spacing: theme.spacing.l) {
                        // Timer Display
                        timerSection
                        
                        // Metrics Grid
                        metricsGrid
                        
                        // Heart Rate Section (always shown)
                        heartRateSection
                        
                        
                        // Splits (outdoor only)
                        if isOutdoor && !viewModel.splits.isEmpty {
                            splitsSection
                        }
                    }
                    .padding(theme.spacing.m)
                }
                
                // Control Buttons
                controlButtons
            }
            
            // Countdown Overlay - Moved to highest Z-index
            if viewModel.timerViewModel.showingCountdown {
                countdownOverlay
                    .zIndex(1000) // Ensure it's above everything else
            }
        }
        .onAppear {
            viewModel.startSession()
        }
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            // Force UI update on main thread
            DispatchQueue.main.async {
                viewModel.updateMetrics()
            }
        }
        .sheet(isPresented: $showingBluetoothSheet) {
            BluetoothDeviceSheet(viewModel: viewModel)
        }
        .confirmationDialog(TrainingKeys.Status.finishWorkout.localized, isPresented: $showingStopConfirmation) {
            Button(TrainingKeys.Status.finishAndSave.localized, role: .destructive) {
                completeSession()
            }
            Button(TrainingKeys.Status.cancel.localized, role: .cancel) { }
        } message: {
            Text(TrainingKeys.Status.confirmFinishMessage.localized)
        }
        .fullScreenCover(isPresented: $viewModel.showingCompletionView) {
            if let session = createSession() {
                CardioSessionSummaryView(
                    session: session, 
                    user: user,
                    onDismiss: {
                        // Dismiss both summary and live tracking views
                        viewModel.showingCompletionView = false
                        dismiss()
                    }
                )
            }
        }
    }
    
    // MARK: - Countdown Overlay
    private var countdownOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: theme.spacing.xl) {
                Text(TrainingKeys.Status.preparing.localized.uppercased())
                    .font(theme.typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("\(viewModel.timerViewModel.countdownValue)")
                    .font(.system(size: 120, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .scaleEffect(viewModel.timerViewModel.countdownValue == 0 ? 1.5 : 1.0)
                    .animation(.easeOut(duration: 0.3), value: viewModel.timerViewModel.countdownValue)
                
                if viewModel.timerViewModel.countdownValue == 0 {
                    Text(TrainingKeys.Status.start.localized.uppercased() + "!")
                        .font(theme.typography.title1)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.accent)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .transition(.opacity)
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(activityType.displayName)
                    .font(theme.typography.headline)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
                
                HStack(spacing: theme.spacing.s) {
                    Image(systemName: isOutdoor ? "location.fill" : "house.fill")
                        .font(.caption)
                    Text(isOutdoor ? TrainingKeys.Cardio.outdoor.localized : TrainingKeys.Cardio.indoor.localized)
                        .font(theme.typography.caption)
                    
                    if isOutdoor {
                        Text("•")
                        Text(viewModel.gpsAccuracy)
                            .foregroundColor(viewModel.gpsAccuracyColor)
                    }
                }
                .foregroundColor(theme.colors.textSecondary)
            }
            
            Spacer()
            
            Button(action: { showingStopConfirmation = true }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
        .padding(theme.spacing.m)
        .background(theme.colors.backgroundSecondary)
    }
    
    // MARK: - Timer Section
    private var timerSection: some View {
        VStack(spacing: theme.spacing.s) {
            TimerDisplay(
                formattedTime: viewModel.formattedDuration,
                isRunning: viewModel.timerViewModel.isRunning,
                size: .huge
            )
            
            if viewModel.timerViewModel.isPaused {
                Text(TrainingKeys.Status.paused.localized.uppercased())
                    .font(theme.typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.warning)
                    .padding(.horizontal, theme.spacing.m)
                    .padding(.vertical, theme.spacing.xs)
                    .background(theme.colors.warning.opacity(0.2))
                    .cornerRadius(theme.radius.s)
            }
        }
        .padding(.vertical, theme.spacing.l)
    }
    
    // MARK: - Metrics Grid
    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: theme.spacing.m) {
            if isOutdoor {
                // Outdoor metrics: GPS-based performance data
                MetricCard(
                    icon: "speedometer",
                    title: TrainingKeys.Cardio.speed.localized,
                    value: viewModel.formattedSpeed,
                    unit: UnitsFormatter.formatSpeedUnit(system: unitSettings.unitSystem),
                    color: theme.colors.accent
                )
                
                MetricCard(
                    icon: "location.fill",
                    title: TrainingKeys.Cardio.distance.localized,
                    value: viewModel.formattedDistance,
                    unit: "",
                    color: theme.colors.success
                )
                
                MetricCard(
                    icon: "flame.fill",
                    title: TrainingKeys.Cardio.calories.localized,
                    value: "\(viewModel.currentCalories)",
                    unit: "kcal",
                    color: theme.colors.warning
                )
                .id("calories-\(viewModel.currentCalories)")
                
                MetricCard(
                    icon: "gauge.medium",
                    title: TrainingKeys.Cardio.pace.localized,
                    value: viewModel.formattedPace,
                    unit: UnitsFormatter.formatPaceUnit(system: unitSettings.unitSystem),
                    color: theme.colors.accent.opacity(0.8)
                )
                .id("pace-\(viewModel.currentPace)")
            } else {
                // Indoor metrics: Focus on effort and physiological data
                MetricCard(
                    icon: "flame.fill",
                    title: TrainingKeys.Cardio.calories.localized,
                    value: "\(viewModel.currentCalories)",
                    unit: "kcal",
                    color: theme.colors.warning
                )
                .id("calories-\(viewModel.currentCalories)")
                
                MetricCard(
                    icon: "heart.fill",
                    title: TrainingKeys.Cardio.heartRate.localized,
                    value: viewModel.formattedHeartRate,
                    unit: "BPM",
                    color: theme.colors.error
                )
                
                MetricCard(
                    icon: "bolt.fill",
                    title: TrainingKeys.Cardio.effort.localized,
                    value: viewModel.perceivedEffortLevel,
                    unit: TrainingKeys.Cardio.rpe.localized,
                    color: theme.colors.accent
                )
                
                MetricCard(
                    icon: "target",
                    title: TrainingKeys.Cardio.zone.localized,
                    value: viewModel.heartRateZone,
                    unit: "",
                    color: viewModel.heartRateZoneColor
                )
            }
        }
    }
    
    // MARK: - Heart Rate Section
    private var heartRateSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(theme.colors.error)
                Text(TrainingKeys.HeartRate.heartRate.localized)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Spacer()
                
                if !viewModel.bluetoothManager.isConnected {
                    Button(action: { showingBluetoothSheet = true }) {
                        Text(TrainingKeys.HeartRate.connect.localized)
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.accent)
                    }
                }
            }
            
            if viewModel.bluetoothManager.isConnected {
                HStack(spacing: theme.spacing.xl) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.formattedHeartRate)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(theme.colors.textPrimary)
                        Text("BPM")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    
                    VStack(alignment: .leading, spacing: theme.spacing.s) {
                        HStack {
                            Circle()
                                .fill(viewModel.heartRateZoneColor)
                                .frame(width: 12, height: 12)
                            Text(viewModel.heartRateZone)
                                .font(theme.typography.body)
                                .foregroundColor(theme.colors.textPrimary)
                        }
                        
                        if let device = viewModel.bluetoothManager.connectedDevice {
                            Text(device.name)
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                        
                        if let battery = viewModel.bluetoothManager.batteryLevel {
                            HStack(spacing: 4) {
                                Image(systemName: "battery.100")
                                    .font(.caption2)
                                Text("\(battery)%")
                                    .font(theme.typography.caption)
                            }
                            .foregroundColor(theme.colors.textSecondary)
                        }
                    }
                    
                    Spacer()
                }
            } else {
                Text(TrainingKeys.HeartRate.notConnected.localized)
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(theme.spacing.m)
                    .background(theme.colors.backgroundSecondary)
                    .cornerRadius(theme.radius.s)
            }
        }
        .cardStyle()
    }
    
    // MARK: - Splits Section
    private var splitsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Image(systemName: "flag.checkered")
                    .foregroundColor(theme.colors.accent)
                Text(TrainingKeys.Intervals.intervals.localized)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
            }
            
            VStack(spacing: theme.spacing.s) {
                ForEach(Array(viewModel.splits.enumerated()), id: \.offset) { index, split in
                    HStack {
                        Text(UnitsFormatter.formatSplitDistance(splitNumber: index + 1, system: unitSettings.unitSystem))
                            .font(theme.typography.body)
                            .fontWeight(.medium)
                            .foregroundColor(theme.colors.textPrimary)
                            .frame(width: 50, alignment: .leading)
                        
                        Text(formatSplitTime(split.time))
                            .font(theme.typography.body)
                            .foregroundColor(theme.colors.textSecondary)
                        
                        Spacer()
                        
                        Text("\(formatPace(split.pace)) /\(unitSettings.unitSystem == .metric ? "km" : "mi")")
                            .font(theme.typography.body)
                            .fontWeight(.medium)
                            .foregroundColor(theme.colors.accent)
                        
                        if let hr = split.heartRate {
                            Text("❤️ \(hr)")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                    }
                    .padding(.vertical, theme.spacing.xs)
                    
                    if index < viewModel.splits.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Control Buttons
    private var controlButtons: some View {
        HStack(spacing: theme.spacing.m) {
            if viewModel.timerViewModel.isPaused {
                Button(action: { viewModel.resumeSession() }) {
                    VStack(spacing: 4) {
                        Image(systemName: "play.fill")
                            .font(.title2)
                        Text(TrainingKeys.Status.resume.localized)
                            .font(theme.typography.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, theme.spacing.l)
                    .background(theme.colors.success)
                    .cornerRadius(theme.radius.m)
                }
            } else {
                Button(action: { viewModel.pauseSession() }) {
                    VStack(spacing: 4) {
                        Image(systemName: "pause.fill")
                            .font(.title2)
                        Text(TrainingKeys.Status.pause.localized)
                            .font(theme.typography.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, theme.spacing.l)
                    .background(theme.colors.warning)
                    .cornerRadius(theme.radius.m)
                }
            }
            
            Button(action: { showingStopConfirmation = true }) {
                VStack(spacing: 4) {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                    Text(TrainingKeys.Status.finish.localized)
                        .font(theme.typography.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacing.l)
                .background(theme.colors.error)
                .cornerRadius(theme.radius.m)
            }
        }
        .padding(theme.spacing.m)
        .background(theme.colors.backgroundSecondary)
    }
    
    // MARK: - Helper Methods
    private func formatSplitTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func formatPace(_ pace: Double) -> String {
        return UnitsFormatter.formatDetailedPace(minPerKm: pace, system: unitSettings.unitSystem)
    }
    
    private func createSession() -> CardioSession? {
        viewModel.createCardioSession()
    }
    
    private func completeSession() {
        viewModel.stopSession()
    }
}

// MARK: - Metric Card
struct MetricCard: View {
    @Environment(\.theme) private var theme
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(title)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
                Spacer()
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(theme.colors.textPrimary)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
        .padding(theme.spacing.m)
        .background(theme.colors.backgroundSecondary)
        .cornerRadius(theme.radius.m)
    }
    
}

// MARK: - Bluetooth Device Sheet
struct BluetoothDeviceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    let viewModel: CardioTimerViewModel
    
    var body: some View {
        NavigationStack {
            List {
                if viewModel.bluetoothManager.isScanning {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(TrainingKeys.HeartRate.searchingDevices.localized)
                            .font(theme.typography.body)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    .padding(.vertical, theme.spacing.m)
                }
                
                ForEach(viewModel.bluetoothManager.discoveredDevices) { device in
                    Button(action: { viewModel.selectHeartRateDevice(device) }) {
                        HStack {
                            Image(systemName: "heart.circle.fill")
                                .font(.title2)
                                .foregroundColor(theme.colors.error)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(device.name)
                                    .font(theme.typography.body)
                                    .foregroundColor(theme.colors.textPrimary)
                                Text("\(TrainingKeys.HeartRate.signal.localized): \(device.signalStrength)")
                                    .font(theme.typography.caption)
                                    .foregroundColor(theme.colors.textSecondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, theme.spacing.s)
                    }
                }
            }
            .navigationTitle(TrainingKeys.HeartRate.selectDevice.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(TrainingKeys.Status.cancel.localized) { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.bluetoothManager.isScanning {
                        Button(TrainingKeys.HeartRate.rescan.localized) {
                            viewModel.bluetoothManager.startScanning()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    CardioLiveTrackingView(
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
    .environmentObject(UnitSettings.shared)
}