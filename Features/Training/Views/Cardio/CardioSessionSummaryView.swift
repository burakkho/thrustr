import SwiftUI
import MapKit
import SwiftData

struct CardioSessionSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(UnitSettings.self) var unitSettings
    @Environment(HealthKitService.self) var healthKitService

    let session: CardioSession
    let user: User
    let onDismiss: (() -> Void)?

    @State private var viewModel: CardioSessionSummaryViewModel
    @State private var feeling: SessionFeeling = .good
    @State private var notes: String = ""
    @State private var showingShareSheet = false
    @State private var mapSnapshot: UIImage?

    // Edit modals
    @State private var showingDurationEdit = false
    @State private var showingDistanceEdit = false
    @State private var showingCaloriesEdit = false
    @State private var showingHeartRateEdit = false

    init(session: CardioSession, user: User, onDismiss: (() -> Void)? = nil) {
        self.session = session
        self.user = user
        self.onDismiss = onDismiss
        self._viewModel = State(initialValue: CardioSessionSummaryViewModel(unitSettings: UnitSettings.shared))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.l) {
                    // Success Header
                    successHeader
                    
                    // Main Stats
                    mainStatsSection
                    
                    // Route Map (if available)
                    if !viewModel.routeCoordinates.isEmpty {
                        routeMapSection
                    }
                    
                    // Detailed Stats
                    detailedStatsSection
                    
                    // Heart Rate Stats (always visible)
                    heartRateStatsSection
                    
                    // Feeling Selection
                    feelingSection
                    
                    // Notes
                    notesSection
                    
                    // Action Buttons
                    actionButtons
                }
                .padding(theme.spacing.m)
            }
            .navigationTitle(CardioKeys.SessionSummary.workoutSummaryTitle.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadSessionData(for: session)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = viewModel.createShareImage(for: session) {
                CardioShareSheet(items: [image, viewModel.createShareText(for: session)])
            }
        }
        .sheet(isPresented: $showingDurationEdit) {
            DurationEditSheet(
                hours: $viewModel.editHours,
                minutes: $viewModel.editMinutes,
                seconds: $viewModel.editSeconds,
                onSave: {
                    viewModel.updateSessionDuration(session)
                    showingDurationEdit = false
                },
                onCancel: { showingDurationEdit = false }
            )
        }
        .sheet(isPresented: $showingDistanceEdit) {
            DistanceEditSheet(
                distance: $viewModel.editDistance,
                unitSystem: unitSettings.unitSystem,
                onSave: {
                    viewModel.updateSessionDistance(session)
                    showingDistanceEdit = false
                },
                onCancel: { showingDistanceEdit = false }
            )
        }
        .sheet(isPresented: $showingHeartRateEdit) {
            HeartRateEditSheet(
                avgHeartRate: $viewModel.editAvgHeartRate,
                maxHeartRate: $viewModel.editMaxHeartRate,
                onSave: {
                    viewModel.updateSessionHeartRate(session)
                    showingHeartRateEdit = false
                },
                onCancel: { showingHeartRateEdit = false }
            )
        }
        .sheet(isPresented: $showingCaloriesEdit) {
            CaloriesEditSheet(
                calories: $viewModel.editCalories,
                onSave: {
                    viewModel.updateSessionCalories(session)
                    showingCaloriesEdit = false
                },
                onCancel: { showingCaloriesEdit = false }
            )
        }
    }
    
    // MARK: - Success Header
    private var successHeader: some View {
        VStack(spacing: theme.spacing.m) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(theme.colors.success)
                .symbolRenderingMode(.hierarchical)
            
            Text("Tebrikler!")
                .font(theme.typography.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)
            
            Text(CardioKeys.SessionSummary.workoutCompleted.localized)
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
        }
        .padding(.vertical, theme.spacing.l)
    }
    
    // MARK: - Main Stats
    private var mainStatsSection: some View {
        HStack(spacing: theme.spacing.m) {
            MainStatCard(
                icon: "timer",
                value: session.formattedDuration,
                label: TrainingKeys.Cardio.duration.localized,
                color: theme.colors.accent,
                onEdit: { 
                    initializeDurationEdit()
                    showingDurationEdit = true 
                },
                isEdited: session.isDurationManuallyEdited
            )
            
            MainStatCard(
                icon: "location.fill",
                value: session.formattedDistance(using: unitSettings.unitSystem),
                label: TrainingKeys.Cardio.distance.localized,
                color: theme.colors.success,
                onEdit: { 
                    initializeDistanceEdit()
                    showingDistanceEdit = true 
                },
                isEdited: session.isDistanceManuallyEdited
            )
            
            MainStatCard(
                icon: "flame.fill",
                value: "\(session.totalCaloriesBurned ?? 0)",
                label: TrainingKeys.Cardio.calories.localized,
                color: theme.colors.warning,
                onEdit: { 
                    initializeCaloriesEdit()
                    showingCaloriesEdit = true 
                },
                isEdited: session.isCaloriesManuallyEdited
            )
        }
    }
    
    // MARK: - Route Map
    private var routeMapSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Image(systemName: "map.fill")
                    .foregroundColor(theme.colors.accent)
                Text(CardioKeys.SessionSummary.yourRoute.localized)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
            }
            
            Map(position: $viewModel.mapCameraPosition) {
                MapPolyline(coordinates: viewModel.routeCoordinates)
                    .stroke(.blue, lineWidth: 4)

                if let start = viewModel.routeCoordinates.first {
                    Marker(CardioKeys.SessionSummary.startMarker.localized, coordinate: start)
                        .tint(.green)
                }

                if let end = viewModel.routeCoordinates.last {
                    Marker(CardioKeys.SessionSummary.finishMarker.localized, coordinate: end)
                        .tint(.red)
                }
            }
            .frame(height: 300)
            .cornerRadius(theme.radius.m)
        }
        .cardStyle()
    }
    
    // MARK: - Detailed Stats
    private var detailedStatsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(theme.colors.accent)
                Text(CardioKeys.SessionSummary.detailedStatistics.localized)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
            }
            
            VStack(spacing: theme.spacing.s) {
                DetailStatRow(label: TrainingKeys.Cardio.averagePace.localized, value: session.formattedAveragePace(using: unitSettings.unitSystem) ?? "--:--")
                Divider()
                DetailStatRow(label: TrainingKeys.Cardio.avgSpeed.localized, value: session.formattedSpeed(using: unitSettings.unitSystem) ?? "-- \(UnitsFormatter.formatSpeedUnit(system: unitSettings.unitSystem))")
                
                if let elevation = session.elevationGain, elevation > 0 {
                    Divider()
                    DetailStatRow(label: TrainingKeys.Cardio.elevation.localized, value: UnitsFormatter.formatDistance(meters: elevation, system: unitSettings.unitSystem))
                }
                
                if let effort = session.perceivedEffort {
                    Divider()
                    DetailStatRow(label: CardioKeys.SessionSummary.perceivedEffort.localized, value: "\(effort)/10")
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Heart Rate Stats
    private var heartRateStatsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(theme.colors.error)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(CardioKeys.SessionSummary.heartRateStats.localized)
                        .font(theme.typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    if viewModel.isHeartRateEdited {
                        Text(CardioKeys.SessionSummary.edited.localized)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(theme.colors.accent)
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                Button(action: { 
                    initializeHeartRateEdit()
                    showingHeartRateEdit = true 
                }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title3)
                        .foregroundColor(theme.colors.accent)
                }
            }
            
            if let avgHR = session.averageHeartRate, avgHR > 0 {
                // Show existing heart rate data
                HStack(spacing: theme.spacing.xl) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(CardioKeys.HeartRateStats.average.localized)
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("\(avgHR)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(theme.colors.textPrimary)
                            Text("bpm")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(CardioKeys.HeartRateStats.maximum.localized)
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("\(session.maxHeartRate ?? 0)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(theme.colors.error)
                            Text("bpm")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                    }
                    
                    Spacer()
                }
            } else {
                // Show add heart rate option
                Button(action: { 
                    initializeHeartRateEdit()
                    showingHeartRateEdit = true 
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(theme.colors.accent)
                        Text(CardioKeys.SessionSummary.addHeartRateData.localized)
                            .font(theme.typography.body)
                            .foregroundColor(theme.colors.accent)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    .padding(theme.spacing.m)
                    .background(theme.colors.accent.opacity(0.1))
                    .cornerRadius(theme.radius.m)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .cardStyle()
    }
    
    // MARK: - Feeling Section
    private var feelingSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text(CardioKeys.SessionSummary.howDoYouFeel.localized)
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
            
            HStack(spacing: theme.spacing.s) {
                ForEach(SessionFeeling.allCases, id: \.self) { feelingOption in
                    Button(action: { feeling = feelingOption }) {
                        VStack(spacing: 4) {
                            Text(feelingOption.emoji)
                                .font(.title2)
                            Text(feelingOption.displayName)
                                .font(.caption2)
                                .fontWeight(feeling == feelingOption ? .semibold : .regular)
                        }
                        .foregroundColor(feeling == feelingOption ? .white : theme.colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, theme.spacing.s)
                        .background(
                            RoundedRectangle(cornerRadius: theme.radius.s)
                                .fill(feeling == feelingOption ? theme.colors.accent : theme.colors.backgroundSecondary)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            Text("Notlar (Opsiyonel)")
                .font(theme.typography.body)
                .fontWeight(.medium)
                .foregroundColor(theme.colors.textPrimary)
            
            TextField(CardioKeys.SessionSummary.notesPlaceholder.localized, text: $notes, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(theme.spacing.m)
                .background(theme.colors.backgroundSecondary)
                .cornerRadius(theme.radius.m)
                .lineLimit(3...5)
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: theme.spacing.m) {
            Button(action: saveSession) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                    Text(CardioKeys.Actions.save.localized)
                        .font(theme.typography.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(theme.spacing.l)
                .background(theme.colors.accent)
                .cornerRadius(theme.radius.m)
            }
            
            Button(action: discardSession) {
                Text(CardioKeys.SessionSummary.exitWithoutSaving.localized)
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
        .padding(.vertical, theme.spacing.l)
    }
    
    // MARK: - Helper Methods
    
    private func saveSession() {
        Task {
            await viewModel.saveSession(
                session,
                feeling: feeling,
                notes: notes,
                user: user,
                modelContext: modelContext,
                healthKitService: healthKitService
            )

            // Show achievement notifications
            await showAchievementNotifications()

            // Dismiss with callback
            if let onDismiss = onDismiss {
                onDismiss()
            } else {
                dismiss()
            }
        }
    }

    private func showAchievementNotifications() async {
        do {
            let durationMinutes = Int(TimeInterval(session.totalDuration) / 60)
            let calories = session.totalCaloriesBurned ?? 0

            // Schedule system notification
            try await NotificationManager.shared.scheduleAchievementNotification(
                title: CardioKeys.SessionSummary.achievementTitle.localized,
                description: String(format: CardioKeys.SessionSummary.achievementBody.localized,
                                  session.workoutName, durationMinutes, calories),
                delay: 2.0
            )

            // Show in-app notification
            await MainActor.run {
                InAppNotificationManager.shared.showAchievement(
                    title: CardioKeys.SessionSummary.achievementTitle.localized,
                    description: String(format: CardioKeys.SessionSummary.achievementInApp.localized,
                                      session.workoutName, durationMinutes)
                )
            }
        } catch {
            Logger.error("Failed to send achievement notification: \(error)")
        }
    }
    
    private func discardSession() {
        if let onDismiss = onDismiss {
            onDismiss()
        } else {
            dismiss()
        }
    }
    
    
    // MARK: - Edit Methods
    private func initializeDurationEdit() {
        let totalSeconds = session.totalDuration
        viewModel.editHours = totalSeconds / 3600
        viewModel.editMinutes = (totalSeconds % 3600) / 60
        viewModel.editSeconds = totalSeconds % 60
    }
    
    private func saveDurationEdit() {
        let newDuration = viewModel.editHours * 3600 + viewModel.editMinutes * 60 + viewModel.editSeconds
        
        if newDuration != session.totalDuration {
            session.updateDurationManually(newDuration)
        }
        
        showingDurationEdit = false
    }
    
    private func initializeDistanceEdit() {
        // Convert meters to user's preferred unit for editing
        switch unitSettings.unitSystem {
        case .metric:
            viewModel.editDistance = session.totalDistance / 1000.0 // Convert to km
        case .imperial:
            viewModel.editDistance = session.totalDistance * 0.000621371 // Convert to miles
        }
    }
    
    private func saveDistanceEdit() {
        // Convert user input back to meters for storage
        let newDistanceMeters: Double
        switch unitSettings.unitSystem {
        case .metric:
            newDistanceMeters = viewModel.editDistance * 1000.0 // km to meters
        case .imperial:
            newDistanceMeters = viewModel.editDistance * 1609.34 // miles to meters
        }
        
        if abs(newDistanceMeters - session.totalDistance) > 0.1 { // Allow for minor floating point differences
            session.updateDistanceManually(newDistanceMeters)
        }
        
        showingDistanceEdit = false
    }
    
    private func initializeHeartRateEdit() {
        viewModel.editAvgHeartRate = session.averageHeartRate ?? 0
        viewModel.editMaxHeartRate = session.maxHeartRate ?? 0
    }
    
    private func saveHeartRateEdit() {
        let originalAvg = session.averageHeartRate ?? 0
        let originalMax = session.maxHeartRate ?? 0
        
        if viewModel.editAvgHeartRate != originalAvg || viewModel.editMaxHeartRate != originalMax {
            viewModel.isHeartRateEdited = true
            session.averageHeartRate = viewModel.editAvgHeartRate > 0 ? viewModel.editAvgHeartRate : nil
            session.maxHeartRate = viewModel.editMaxHeartRate > 0 ? viewModel.editMaxHeartRate : nil
        }
        
        showingHeartRateEdit = false
    }
    
    private func initializeCaloriesEdit() {
        viewModel.editCalories = session.totalCaloriesBurned ?? 0
    }
    
    private func saveCaloriesEdit() {
        if viewModel.editCalories != (session.totalCaloriesBurned ?? 0) {
            session.updateCaloriesManually(viewModel.editCalories > 0 ? viewModel.editCalories : nil)
        }
        
        showingCaloriesEdit = false
    }
}

// MARK: - Main Stat Card
struct MainStatCard: View {
    @Environment(\.theme) private var theme
    let icon: String
    let value: String
    let label: String
    let color: Color
    let onEdit: (() -> Void)?
    let isEdited: Bool
    
    init(icon: String, value: String, label: String, color: Color, onEdit: (() -> Void)? = nil, isEdited: Bool = false) {
        self.icon = icon
        self.value = value
        self.label = label
        self.color = color
        self.onEdit = onEdit
        self.isEdited = isEdited
    }
    
    var body: some View {
        VStack(spacing: theme.spacing.s) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                if let onEdit = onEdit {
                    Spacer()
                    Button(action: onEdit) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title3)
                            .foregroundColor(theme.colors.accent)
                    }
                }
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(theme.colors.textPrimary)
            
            HStack(spacing: theme.spacing.xs) {
                Text(label)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
                
                if isEdited {
                    Text(CardioKeys.SessionSummary.edited.localized)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(theme.colors.accent)
                        .cornerRadius(4)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(theme.spacing.m)
        .background(theme.colors.backgroundSecondary)
        .cornerRadius(theme.radius.m)
    }
}

// MARK: - Detail Stat Row
struct DetailStatRow: View {
    @Environment(\.theme) private var theme
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
            Spacer()
            Text(value)
                .font(theme.typography.body)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
        }
        .padding(.vertical, theme.spacing.xs)
    }
}

// MARK: - Duration Edit Sheet
struct DurationEditSheet: View {
    @Environment(\.theme) private var theme
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var seconds: Int
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: theme.spacing.l) {
                // Header
                VStack(spacing: theme.spacing.s) {
                    Image(systemName: "timer")
                        .font(.system(size: 40))
                        .foregroundColor(theme.colors.accent)
                    
                    Text(CardioKeys.SessionSummary.editDuration.localized)
                        .font(theme.typography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text(CardioKeys.SessionSummary.durationDescription.localized)
                        .font(theme.typography.body)
                        .foregroundColor(theme.colors.textSecondary)
                }
                .padding(.top, theme.spacing.l)
                
                // Time Picker
                VStack(spacing: theme.spacing.m) {
                    Text(CardioKeys.SessionSummary.durationLabel.localized)
                        .font(theme.typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    HStack(spacing: theme.spacing.m) {
                        // Hours
                        VStack(spacing: theme.spacing.xs) {
                            Text(CardioKeys.TimeUnits.hour.localized)
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                            
                            Picker("Hours", selection: $hours) {
                                ForEach(0..<24, id: \.self) { hour in
                                    Text("\(hour)")
                                        .tag(hour)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 60, height: 120)
                        }
                        
                        Text(":")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(theme.colors.textPrimary)
                        
                        // Minutes
                        VStack(spacing: theme.spacing.xs) {
                            Text(CardioKeys.TimeUnits.minute.localized)
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                            
                            Picker("Minutes", selection: $minutes) {
                                ForEach(0..<60, id: \.self) { minute in
                                    Text(String(format: "%02d", minute))
                                        .tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 60, height: 120)
                        }
                        
                        Text(":")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(theme.colors.textPrimary)
                        
                        // Seconds
                        VStack(spacing: theme.spacing.xs) {
                            Text(CardioKeys.TimeUnits.second.localized)
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                            
                            Picker("Seconds", selection: $seconds) {
                                ForEach(0..<60, id: \.self) { second in
                                    Text(String(format: "%02d", second))
                                        .tag(second)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 60, height: 120)
                        }
                    }
                }
                .cardStyle()
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: theme.spacing.m) {
                    Button(action: onSave) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                            Text(CardioKeys.Actions.save.localized)
                                .font(theme.typography.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(theme.spacing.l)
                        .background(theme.colors.accent)
                        .cornerRadius(theme.radius.m)
                    }
                    
                    Button(action: onCancel) {
                        Text(CardioKeys.Actions.cancel.localized)
                            .font(theme.typography.body)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
            }
            .padding(theme.spacing.m)
            .navigationTitle(CardioKeys.SessionSummary.editDurationTitle.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(CardioKeys.Actions.cancel.localized, action: onCancel)
                }
            }
        }
    }
}

// MARK: - Distance Edit Sheet
struct DistanceEditSheet: View {
    @Environment(\.theme) private var theme
    @Binding var distance: Double
    let unitSystem: UnitSystem
    let onSave: () -> Void
    let onCancel: () -> Void
    
    private var unitLabel: String {
        unitSystem == .metric ? "km" : "mi"
    }
    
    private var unitDescription: String {
        unitSystem == .metric ? "kilometre" : "mil"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: theme.spacing.l) {
                // Header
                VStack(spacing: theme.spacing.s) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 40))
                        .foregroundColor(theme.colors.success)
                    
                    Text(CardioKeys.SessionSummary.editDistance.localized)
                        .font(theme.typography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text(String(format: CardioKeys.SessionSummary.distanceDescription.localized, unitDescription))
                        .font(theme.typography.body)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, theme.spacing.l)
                
                // Distance Input
                VStack(spacing: theme.spacing.m) {
                    Text("Mesafe (\(unitLabel))")
                        .font(theme.typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    VStack(spacing: theme.spacing.s) {
                        TextField("0.0", value: $distance, format: .number.precision(.fractionLength(1...2)))
                            .textFieldStyle(.plain)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(theme.colors.textPrimary)
                            .multilineTextAlignment(.center)
                            .keyboardType(.decimalPad)
                            .padding(theme.spacing.m)
                            .background(theme.colors.backgroundSecondary)
                            .cornerRadius(theme.radius.m)
                        
                        Text(unitLabel)
                            .font(theme.typography.body)
                            .fontWeight(.medium)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
                .cardStyle()
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: theme.spacing.m) {
                    Button(action: onSave) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                            Text(CardioKeys.Actions.save.localized)
                                .font(theme.typography.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(theme.spacing.l)
                        .background(theme.colors.success)
                        .cornerRadius(theme.radius.m)
                    }
                    
                    Button(action: onCancel) {
                        Text(CardioKeys.Actions.cancel.localized)
                            .font(theme.typography.body)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
            }
            .padding(theme.spacing.m)
            .navigationTitle(CardioKeys.SessionSummary.editDistanceTitle.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(CardioKeys.Actions.cancel.localized, action: onCancel)
                }
            }
        }
    }
}

// MARK: - Heart Rate Edit Sheet
struct HeartRateEditSheet: View {
    @Environment(\.theme) private var theme
    @Binding var avgHeartRate: Int
    @Binding var maxHeartRate: Int
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: theme.spacing.l) {
                // Header
                VStack(spacing: theme.spacing.s) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 40))
                        .foregroundColor(theme.colors.error)
                    
                    Text(CardioKeys.SessionSummary.editHeartRate.localized)
                        .font(theme.typography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text(CardioKeys.SessionSummary.heartRateDescription.localized)
                        .font(theme.typography.body)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, theme.spacing.l)
                
                // Heart Rate Inputs
                VStack(spacing: theme.spacing.xl) {
                    // Average Heart Rate
                    VStack(spacing: theme.spacing.s) {
                        Text(CardioKeys.SessionSummary.averageHeartRateBpm.localized)
                            .font(theme.typography.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.colors.textPrimary)
                        
                        TextField("0", value: $avgHeartRate, format: .number)
                            .textFieldStyle(.plain)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(theme.colors.textPrimary)
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .padding(theme.spacing.m)
                            .background(theme.colors.backgroundSecondary)
                            .cornerRadius(theme.radius.m)
                    }
                    
                    // Maximum Heart Rate
                    VStack(spacing: theme.spacing.s) {
                        Text(CardioKeys.SessionSummary.maximumHeartRateBpm.localized)
                            .font(theme.typography.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.colors.textPrimary)
                        
                        TextField("0", value: $maxHeartRate, format: .number)
                            .textFieldStyle(.plain)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(theme.colors.error)
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .padding(theme.spacing.m)
                            .background(theme.colors.backgroundSecondary)
                            .cornerRadius(theme.radius.m)
                    }
                }
                .cardStyle()
                
                // Info
                VStack(spacing: theme.spacing.xs) {
                    Text(CardioKeys.SessionSummary.tipIcon.localized)
                        .font(theme.typography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.accent)
                    
                    Text(CardioKeys.SessionSummary.heartRateTip.localized)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(theme.spacing.s)
                .background(theme.colors.accent.opacity(0.1))
                .cornerRadius(theme.radius.s)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: theme.spacing.m) {
                    Button(action: onSave) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                            Text(CardioKeys.Actions.save.localized)
                                .font(theme.typography.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(theme.spacing.l)
                        .background(theme.colors.error)
                        .cornerRadius(theme.radius.m)
                    }
                    
                    Button(action: onCancel) {
                        Text(CardioKeys.Actions.cancel.localized)
                            .font(theme.typography.body)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
            }
            .padding(theme.spacing.m)
            .navigationTitle(CardioKeys.SessionSummary.editHeartRateTitle.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(CardioKeys.Actions.cancel.localized, action: onCancel)
                }
            }
        }
    }
}

// MARK: - Calories Edit Sheet
struct CaloriesEditSheet: View {
    @Environment(\.theme) private var theme
    @Binding var calories: Int
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: theme.spacing.l) {
                // Header
                VStack(spacing: theme.spacing.s) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 40))
                        .foregroundColor(theme.colors.warning)
                    
                    Text(CardioKeys.SessionSummary.editCaloriesTitle.localized)
                        .font(theme.typography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text(CardioKeys.SessionSummary.editCaloriesDescription.localized)
                        .font(theme.typography.body)
                        .foregroundColor(theme.colors.textSecondary)
                }
                .padding(.top, theme.spacing.l)
                
                // Calories Input
                VStack(spacing: theme.spacing.m) {
                    Text(CardioKeys.SessionSummary.caloriesBurnedLabel.localized)
                        .font(theme.typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    VStack(spacing: theme.spacing.s) {
                        TextField("0", value: $calories, format: .number)
                            .textFieldStyle(.plain)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(theme.colors.textPrimary)
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .padding(theme.spacing.m)
                            .background(theme.colors.backgroundSecondary)
                            .cornerRadius(theme.radius.m)
                        
                        Text("kcal")
                            .font(theme.typography.body)
                            .fontWeight(.medium)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
                .cardStyle()
                
                // Info
                VStack(spacing: theme.spacing.xs) {
                    Text(CardioKeys.SessionSummary.tipIcon.localized)
                        .font(theme.typography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.accent)
                    
                    Text(CardioKeys.SessionSummary.caloriesTip.localized)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(theme.spacing.s)
                .background(theme.colors.accent.opacity(0.1))
                .cornerRadius(theme.radius.s)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: theme.spacing.m) {
                    Button(action: onSave) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                            Text(CardioKeys.Actions.save.localized)
                                .font(theme.typography.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(theme.spacing.l)
                        .background(theme.colors.warning)
                        .cornerRadius(theme.radius.m)
                    }
                    
                    Button(action: onCancel) {
                        Text(CardioKeys.Actions.cancel.localized)
                            .font(theme.typography.body)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
            }
            .padding(theme.spacing.m)
            .navigationTitle(CardioKeys.SessionSummary.editCaloriesTitle.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(CardioKeys.Actions.cancel.localized, action: onCancel)
                }
            }
        }
    }
}

// MARK: - Share Sheet
struct CardioShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Cardio Share Card
struct CardioShareCard: View {
    let session: CardioSession
    @Environment(\.theme) private var theme
    @Environment(UnitSettings.self) var unitSettings
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: theme.spacing.m) {
                HStack {
                    Image(systemName: "figure.run")
                        .font(.title)
                        .foregroundColor(.white)
                    
                    Text("Thrustr")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Text(session.startDate.formatted(date: .abbreviated, time: .omitted))
                    .font(theme.typography.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [theme.colors.success, theme.colors.success.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            // Session Stats
            VStack(alignment: .leading, spacing: theme.spacing.l) {
                // Main Title
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(CardioKeys.SessionSummary.workoutCompleted.localized)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(theme.colors.textPrimary)
                        
                        HStack(spacing: theme.spacing.s) {
                            Image(systemName: "heart.fill")
                                .font(.caption)
                                .foregroundColor(theme.colors.error)
                            
                            Text(CardioKeys.Common.cardioWorkout.localized)
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Achievement badge if PR
                    if !session.personalRecordsHit.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "trophy.fill")
                                .font(.caption)
                                .foregroundColor(theme.colors.warning)
                            Text("PR!")
                                .font(theme.typography.caption)
                                .fontWeight(.bold)
                                .foregroundColor(theme.colors.warning)
                        }
                        .padding(.horizontal, theme.spacing.s)
                        .padding(.vertical, 2)
                        .background(theme.colors.warning.opacity(0.1))
                        .cornerRadius(theme.radius.s)
                    }
                }
                
                Divider()
                    .background(theme.colors.border.opacity(0.3))
                
                // Stats Grid
                VStack(spacing: theme.spacing.m) {
                    HStack(spacing: theme.spacing.m) {
                        // Duration
                        ShareStatCard(
                            icon: "timer",
                            value: formatDuration(session.totalDuration),
                            label: TrainingKeys.CardioSummary.duration.localized,
                            color: theme.colors.accent
                        )
                        
                        // Distance
                        if session.totalDistance > 0 {
                            ShareStatCard(
                                icon: "location.fill",
                                value: formatDistance(session.totalDistance),
                                label: TrainingKeys.CardioSummary.distance.localized,
                                color: theme.colors.success
                            )
                        } else {
                            ShareStatCard(
                                icon: "speedometer",
                                value: "--",
                                label: TrainingKeys.CardioSummary.distance.localized,
                                color: theme.colors.success
                            )
                        }
                    }
                    
                    HStack(spacing: theme.spacing.m) {
                        // Calories
                        ShareStatCard(
                            icon: "flame.fill",
                            value: session.totalCaloriesBurned != nil ? "\(session.totalCaloriesBurned!)" : "--",
                            label: TrainingKeys.CardioSummary.calories.localized,
                            color: theme.colors.warning
                        )
                        
                        // Heart Rate
                        ShareStatCard(
                            icon: "heart.fill",
                            value: session.averageHeartRate != nil ? "\(session.averageHeartRate!) bpm" : "--",
                            label: CardioKeys.SessionSummary.averageHeartRate.localized,
                            color: theme.colors.error
                        )
                    }
                }
                
                // Personal Records Section
                if !session.personalRecordsHit.isEmpty {
                    VStack(alignment: .leading, spacing: theme.spacing.s) {
                        Text("🏆 PERSONAL RECORDS")
                            .font(theme.typography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.colors.warning)
                        
                        ForEach(session.personalRecordsHit, id: \.self) { pr in
                            HStack {
                                Image(systemName: "trophy.fill")
                                    .font(.caption2)
                                    .foregroundColor(theme.colors.warning)
                                
                                Text(pr)
                                    .font(theme.typography.caption)
                                    .foregroundColor(theme.colors.textPrimary)
                                
                                Spacer()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(theme.spacing.m)
                    .background(theme.colors.warning.opacity(0.1))
                    .cornerRadius(theme.radius.m)
                }
                
                // Notes if available
                if let notes = session.sessionNotes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        Text(CardioKeys.StatsLabels.notes.localized.uppercased())
                            .font(theme.typography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.colors.textSecondary)
                        
                        Text(notes)
                            .font(theme.typography.body)
                            .foregroundColor(theme.colors.textPrimary)
                            .lineLimit(3)
                    }
                }
            }
            .padding()
            
            // Footer
            HStack {
                Text("#Cardio #Fitness #Training")
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
        .background(Color.white)
        .cornerRadius(theme.radius.l)
        .shadow(radius: 10)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        } else {
            return String(format: "%d:%02d", minutes, remainingSeconds)
        }
    }
    
    private func formatDistance(_ meters: Double) -> String {
        if unitSettings.unitSystem == .metric {
            let km = meters / 1000.0
            return String(format: "%.1f km", km)
        } else {
            let miles = meters * 0.000621371
            return String(format: "%.1f mi", miles)
        }
    }
}

// MARK: - Share Stat Card Component
struct ShareStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: theme.spacing.xs) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)
            
            Text(label)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(theme.spacing.m)
        .background(theme.colors.backgroundSecondary)
        .cornerRadius(theme.radius.m)
    }
}