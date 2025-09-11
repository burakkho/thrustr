import SwiftUI
import SwiftData

/**
 * Minimal user profile card with 4 essential metrics.
 * 
 * Shows height, weight, body fat, and strength level in QuickStatus style.
 * Ultra clean design without headers, icons, or buttons.
 * Uses real TestScoringService for accurate strength level calculations.
 */
struct AthleteProfileCard: View {
    // MARK: - Properties
    let user: User
    @Query(sort: \StrengthTest.testDate, order: .reverse) private var strengthTests: [StrengthTest]
    
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(UnitSettings.self) private var unitSettings
    @Environment(TabRouter.self) private var tabRouter
    @State private var healthKitService = HealthKitService.shared
    
    @State private var showingStrengthTest = false
    @State private var showingNavyCalculator = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Section Header
            HStack {
                Text("profile.quick_actions".localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // Quick Action Buttons Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 16) {
                quickWeightAction
                quickMeasureAction
                quickGoalsAction  
                quickAnalyticsAction
            }
        }
        .fullScreenCover(isPresented: $showingStrengthTest) {
            StrengthTestView(user: user, modelContext: modelContext)
        }
        .sheet(isPresented: $showingNavyCalculator) {
            NavigationView {
                NavyMethodCalculatorView(user: user)
            }
        }
    }
    
    // MARK: - Quick Action Components
    
    @State private var showingWeightEntry = false
    @State private var showingMeasurements = false
    
    private var quickWeightAction: some View {
        QuickActionCard(
            title: "profile.log_weight".localized,
            subtitle: formatCurrentWeight(),
            icon: "scalemass.fill",
            color: .green,
            action: { showingWeightEntry = true }
        )
        .sheet(isPresented: $showingWeightEntry) {
            WeightEntrySheet(user: user)
        }
    }
    
    private var quickMeasureAction: some View {
        QuickActionCard(
            title: "profile.measurements".localized,
            subtitle: "profile.track_progress".localized,
            icon: "ruler.fill",
            color: .blue,
            action: { showingMeasurements = true }
        )
        .sheet(isPresented: $showingMeasurements) {
            BodyMeasurementsView(user: user)
        }
    }
    
    private var quickGoalsAction: some View {
        QuickActionCard(
            title: "profile.goals".localized,
            subtitle: "profile.set_targets".localized,
            icon: "target",
            color: .purple,
            action: {
                tabRouter.selected = 1  // Training tab for goals
            }
        )
    }
    
    private var quickAnalyticsAction: some View {
        QuickActionCard(
            title: "analytics.title".localized,
            subtitle: "profile.view_progress".localized,
            icon: "chart.line.uptrend.xyaxis",
            color: .orange,
            action: {
                tabRouter.selected = 1  // Training tab analytics
            }
        )
    }
    
    // MARK: - Computed Properties
    
    private func formatCurrentWeight() -> String {
        // Use HealthKit weight if available, otherwise user's manual weight
        let weight = healthKitService.isAuthorized && healthKitService.currentWeight != nil 
                   ? healthKitService.currentWeight! 
                   : user.currentWeight
        
        if unitSettings.unitSystem == .metric {
            return String(format: "%.1f kg", weight)
        } else {
            let pounds = weight * 2.20462
            return String(format: "%.1f lb", pounds)
        }
    }
    
    
    
    private func getOverallStrengthLevel() -> (level: String, strengthLevel: StrengthLevel?) {
        guard user.hasCompleteOneRMData else { return ("--", nil) }
        
        // Validate user data
        guard user.age > 0, user.currentWeight > 0 else { return ("--", nil) }
        
        let exercises: [StrengthExerciseType] = [.benchPress, .backSquat, .deadlift, .overheadPress, .pullUp]
        var strengthLevels: [StrengthLevel] = []
        
        // Calculate strength level for each exercise using real standards
        for exercise in exercises {
            guard let oneRM = user.getCurrentOneRM(for: exercise), oneRM > 0 else { continue }
            
            let (level, _) = StrengthStandardsConfig.strengthLevel(
                for: oneRM,
                exerciseType: exercise,
                userGender: user.genderEnum,
                userAge: user.age,
                userWeight: user.currentWeight
            )
            
            strengthLevels.append(level)
        }
        
        guard !strengthLevels.isEmpty else { return ("--", nil) }
        
        // Calculate average strength level with safe bounds
        let averageRawValue = strengthLevels.map { $0.rawValue }.reduce(0, +) / strengthLevels.count
        let clampedValue = max(0, min(5, averageRawValue)) // Clamp to valid StrengthLevel range
        let overallLevel = StrengthLevel(rawValue: clampedValue) ?? .beginner
        
        // Return abbreviated form for UI
        let abbreviation: String
        switch overallLevel {
        case .beginner: abbreviation = DashboardKeys.StrengthLevels.beginnerShort.localized
        case .novice: abbreviation = DashboardKeys.StrengthLevels.noviceShort.localized
        case .intermediate: abbreviation = DashboardKeys.StrengthLevels.intermediateShort.localized
        case .advanced: abbreviation = DashboardKeys.StrengthLevels.advancedShort.localized
        case .expert: abbreviation = DashboardKeys.StrengthLevels.expertShort.localized
        case .elite: abbreviation = DashboardKeys.StrengthLevels.eliteShort.localized
        }
        
        return (abbreviation, overallLevel)
    }
    
    
    // MARK: - Actions
    private func strengthLevelAction() {
        let (levelString, _) = getOverallStrengthLevel()
        if levelString == "--" {
            // Navigate to strength test
            navigateToStrengthTest()
        } else {
            // Navigate to test results/details
            navigateToTestResults()
        }
    }
    
    private func navigateToStrengthTest() {
        // Show full screen strength test
        showingStrengthTest = true
    }
    
    private func navigateToTestResults() {
        // Navigate to Training tab's Tests section
        tabRouter.selected = 1  // Training tab
        
        // We could also add a way to directly navigate to tests section
        // by setting a coordinator state, but for now this will work
    }
    
    private func navigateToBodyFatCalculator() {
        showingNavyCalculator = true
    }
}

// MARK: - Supporting Views


/**
 * Enhanced stat card for displaying user profile metrics with icons and animations.
 * Includes hover effects and consistent sizing for better visual hierarchy.
 */
struct UserStatCard: View {
    @Environment(\.theme) private var theme
    @State private var isPressed = false
    
    let icon: String
    let value: String
    let title: String
    let subtitle: String?
    let color: Color
    let action: (() -> Void)?
    
    init(icon: String, value: String, title: String, subtitle: String? = nil, color: Color, action: (() -> Void)? = nil) {
        self.icon = icon
        self.value = value
        self.title = title
        self.subtitle = subtitle
        self.color = color
        self.action = action
    }
    
    // Computed property to detect call-to-action state
    private var isCallToAction: Bool {
        return action != nil && (value == DashboardKeys.Profile.takeTest.localized || value == "--")
    }
    
    var body: some View {
        VStack(spacing: theme.spacing.xs) {
            // Value with larger, bolder text - Enhanced sizing
            Text(value)
                .font(isCallToAction ? .headline.bold() : .title2.bold())  // Increased font sizes
                .foregroundColor(isCallToAction ? color : theme.colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            // Title with better spacing - Enhanced readability
            Text(title)
                .font(.subheadline.weight(.medium))  // Increased from .caption
                .foregroundColor(theme.colors.textSecondary)
                .lineLimit(1)
            
            // Source indicator subtitle
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(theme.colors.textTertiary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, idealHeight: 80)  // Increased from 60 to 80
        .padding(theme.spacing.l)  // Increased padding from .m to .l
        .background(
            RoundedRectangle(cornerRadius: theme.radius.m)
                .fill(theme.colors.cardBackground)
                .overlay(
                    // Call-to-action border for empty state
                    RoundedRectangle(cornerRadius: theme.radius.m)
                        .stroke(
                            isCallToAction ? color.opacity(0.3) : Color.clear,
                            style: StrokeStyle(lineWidth: 1.5, dash: isCallToAction ? [5, 3] : [])
                        )
                )
                .shadow(
                    color: isPressed ? color.opacity(0.2) : Color.black.opacity(0.08),
                    radius: isPressed ? 4 : 2,
                    y: isPressed ? 2 : 1
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .contentShape(Rectangle())
        .onTapGesture {
            if let action = action {
                performAction(action)
            }
        }
        .onLongPressGesture(minimumDuration: 0.0, maximumDistance: .infinity, perform: {}, onPressingChanged: { pressing in
            if action != nil {
                isPressed = pressing
            }
        })
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
        .accessibilityAddTraits(action != nil ? .isButton : [])
        .accessibilityHint(action != nil ? (isCallToAction ? DashboardKeys.Profile.testHint.localized : DashboardKeys.General.tapForDetails.localized) : "")
    }
    
    // MARK: - Actions
    private func performAction(_ action: @escaping () -> Void) {
        // Enhanced haptic feedback based on action type
        if isCallToAction {
            HapticManager.shared.impact(.medium)  // Stronger feedback for CTA
        } else {
            HapticManager.shared.impact(.light)   // Light feedback for info cards
        }
        
        action()
    }
}



// MARK: - Preview

#Preview("Athlete Profile Card") {
    let sampleUser: User = {
        let user = User(
            name: "Test User",
            age: 25,
            gender: .male,
            height: 175,
            currentWeight: 80
        )
        
        // Add some sample data
        user.benchPressOneRM = 85
        user.squatOneRM = 120
        user.deadliftOneRM = 140
        user.overheadPressOneRM = 60
        user.pullUpOneRM = 20
        user.strengthTestCompletionCount = 3
        
        return user
    }()
    
    AthleteProfileCard(user: sampleUser)
        .padding()
        .modelContainer(for: [User.self, StrengthTest.self], inMemory: true)
        .environment(UnitSettings.shared)
}