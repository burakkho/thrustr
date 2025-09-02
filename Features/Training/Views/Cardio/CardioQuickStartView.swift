import SwiftUI
import SwiftData

struct CardioQuickStartView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var unitSettings: UnitSettings
    @Query private var user: [User]
    
    @State private var selectedActivity: CardioTimerViewModel.CardioActivityType = .running
    @State private var isOutdoor = true
    @State private var selectedPreset: DistancePreset?
    @State private var showingPreparation = false
    
    private var currentUser: User? {
        user.first
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.xl) {
                    // Header
                    VStack(spacing: theme.spacing.s) {
                        Image(systemName: "figure.run.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(theme.colors.accent)
                            .symbolRenderingMode(.hierarchical)
                        
                        Text(TrainingKeys.Cardio.quickStart.localized)
                            .font(theme.typography.title2)
                            .fontWeight(.bold)
                            .foregroundColor(theme.colors.textPrimary)
                        
                        Text(TrainingKeys.Cardio.selectActivityToStart.localized)
                            .font(theme.typography.body)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    .padding(.top, theme.spacing.l)
                    
                    // Activity Selection
                    VStack(alignment: .leading, spacing: theme.spacing.m) {
                        Text(TrainingKeys.Cardio.activityType.localized)
                            .font(theme.typography.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.colors.textPrimary)
                            .padding(.horizontal)
                        
                        VStack(spacing: theme.spacing.m) {
                            ForEach(CardioTimerViewModel.CardioActivityType.allCases, id: \.self) { activity in
                                ActivityCard(
                                    activity: activity,
                                    isSelected: selectedActivity == activity,
                                    action: { selectedActivity = activity }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Indoor/Outdoor Toggle
                    VStack(alignment: .leading, spacing: theme.spacing.m) {
                        Text(TrainingKeys.Cardio.modalLocation.localized)
                            .font(theme.typography.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.colors.textPrimary)
                            .padding(.horizontal)
                        
                        HStack(spacing: theme.spacing.m) {
                            LocationCard(
                                title: TrainingKeys.Cardio.outdoor.localized,
                                icon: "sun.max.fill",
                                description: TrainingKeys.Cardio.gpsRealTimeTracking.localized,
                                isSelected: isOutdoor,
                                action: { isOutdoor = true }
                            )
                            
                            LocationCard(
                                title: TrainingKeys.Cardio.indoor.localized,
                                icon: "house.fill",
                                description: TrainingKeys.Cardio.manualDistanceInput.localized,
                                isSelected: !isOutdoor,
                                action: { isOutdoor = false }
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Quick Distance Presets
                    quickPresetsSection
                    
                    // Features Info
                    FeaturesInfoCard(isOutdoor: isOutdoor)
                        .padding(.horizontal)
                    
                    // Start Button
                    Button(action: startActivity) {
                        HStack {
                            Image(systemName: "play.fill")
                                .font(.title3)
                            Text(TrainingKeys.Cardio.start.localized)
                                .font(theme.typography.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(theme.spacing.l)
                        .background(theme.colors.accent)
                        .cornerRadius(theme.radius.m)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, theme.spacing.xl)
                }
            }
            .navigationTitle("Cardio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(TrainingKeys.Cardio.cancel.localized) { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showingPreparation) {
                if let user = currentUser {
                    CardioPreparationView(
                        activityType: selectedActivity,
                        isOutdoor: isOutdoor,
                        user: user
                    )
                }
            }
        }
    }
    
    private var quickPresetsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text("Quick Distance")
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
                .padding(.horizontal)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: theme.spacing.s) {
                ForEach(DistancePreset.allCases, id: \.self) { preset in
                    PresetCard(
                        preset: preset,
                        isSelected: selectedPreset == preset,
                        unitSystem: unitSettings.unitSystem,
                        action: { selectedPreset = preset }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func startActivity() {
        guard currentUser != nil else { return }
        showingPreparation = true
    }
}

// MARK: - Activity Card
struct ActivityCard: View {
    @Environment(\.theme) private var theme
    let activity: CardioTimerViewModel.CardioActivityType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: theme.spacing.m) {
                Image(systemName: activity.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : theme.colors.accent)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.displayName)
                        .font(theme.typography.headline)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : theme.colors.textPrimary)
                    
                    Text("MET: \(String(format: "%.1f", activity.metValue))")
                        .font(theme.typography.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : theme.colors.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            }
            .padding(theme.spacing.m)
            .background(
                RoundedRectangle(cornerRadius: theme.radius.m)
                    .fill(isSelected ? theme.colors.accent : theme.colors.backgroundSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.m)
                    .stroke(isSelected ? Color.clear : theme.colors.backgroundSecondary, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Location Card
struct LocationCard: View {
    @Environment(\.theme) private var theme
    let title: String
    let icon: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: theme.spacing.s) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(isSelected ? .white : theme.colors.accent)
                
                Text(title)
                    .font(theme.typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : theme.colors.textPrimary)
                
                Text(description)
                    .font(theme.typography.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(theme.spacing.m)
            .background(
                RoundedRectangle(cornerRadius: theme.radius.m)
                    .fill(isSelected ? theme.colors.accent : theme.colors.backgroundSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.m)
                    .stroke(isSelected ? Color.clear : theme.colors.backgroundSecondary, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Features Info Card
struct FeaturesInfoCard: View {
    @Environment(\.theme) private var theme
    let isOutdoor: Bool
    
    private var features: [(icon: String, text: String)] {
        if isOutdoor {
            return [
                ("location.fill", TrainingKeys.Cardio.gpsRealTimeTracking.localized),
                ("map.fill", TrainingKeys.Cardio.routeMapAfterWorkout.localized),
                ("speedometer", TrainingKeys.Cardio.instantSpeedPace.localized),
                ("arrow.up.arrow.down", TrainingKeys.Cardio.elevationChanges.localized)
            ]
        } else {
            return [
                ("timer", TrainingKeys.Cardio.timeTracking.localized),
                ("flame.fill", TrainingKeys.Cardio.estimatedCalories.localized),
                ("heart.fill", TrainingKeys.Cardio.heartRateSupport.localized),
                ("pencil", TrainingKeys.Cardio.manualDistanceInput.localized)
            ]
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(theme.colors.accent)
                Text(TrainingKeys.Cardio.modalFeatures.localized)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: theme.spacing.s) {
                ForEach(features, id: \.text) { feature in
                    HStack(spacing: theme.spacing.s) {
                        Image(systemName: feature.icon)
                            .font(.caption)
                            .foregroundColor(theme.colors.accent)
                            .frame(width: 20)
                        
                        Text(feature.text)
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(theme.spacing.m)
        .background(
            RoundedRectangle(cornerRadius: theme.radius.m)
                .fill(theme.colors.backgroundSecondary.opacity(0.5))
        )
    }
}

// MARK: - Distance Presets
enum DistancePreset: CaseIterable {
    case oneK, fiveK, tenK, halfMarathon, marathon, custom
    
    var distanceMeters: Double {
        switch self {
        case .oneK: return 1000
        case .fiveK: return 5000
        case .tenK: return 10000
        case .halfMarathon: return 21097
        case .marathon: return 42195
        case .custom: return 0
        }
    }
    
    func displayText(for unitSystem: UnitSystem) -> String {
        switch self {
        case .oneK: return unitSystem == .metric ? "1K" : "0.6mi"
        case .fiveK: return unitSystem == .metric ? "5K" : "3.1mi"
        case .tenK: return unitSystem == .metric ? "10K" : "6.2mi"
        case .halfMarathon: return unitSystem == .metric ? "Half" : "13.1mi"
        case .marathon: return unitSystem == .metric ? "Marathon" : "26.2mi"
        case .custom: return "Custom"
        }
    }
}

// MARK: - Preset Card Component
struct PresetCard: View {
    @Environment(\.theme) private var theme
    
    let preset: DistancePreset
    let isSelected: Bool
    let unitSystem: UnitSystem
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: theme.spacing.xs) {
                Text(preset.displayText(for: unitSystem))
                    .font(theme.typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : theme.colors.textPrimary)
                
                if preset != .custom {
                    Text(UnitsFormatter.formatDistance(meters: preset.distanceMeters, system: unitSystem))
                        .font(theme.typography.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : theme.colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacing.s)
            .background(
                RoundedRectangle(cornerRadius: theme.radius.s)
                    .fill(isSelected ? theme.colors.accent : theme.colors.backgroundSecondary)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CardioQuickStartView()
        .environmentObject(UnitSettings.shared)
        .modelContainer(for: User.self, inMemory: true)
}