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
    @EnvironmentObject private var unitSettings: UnitSettings
    @EnvironmentObject private var tabRouter: TabRouter
    
    @State private var showingStrengthTest = false
    @State private var showingNavyCalculator = false
    
    var body: some View {
        HStack(spacing: theme.spacing.s) {
            heightCard
            weightCard  
            bodyFatCard
            strengthLevelCard
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(DashboardKeys.Profile.profileMetrics.localized)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .fullScreenCover(isPresented: $showingStrengthTest) {
            StrengthTestView(user: user, modelContext: modelContext)
        }
        .sheet(isPresented: $showingNavyCalculator) {
            NavigationView {
                NavyMethodCalculatorView(user: user)
            }
        }
    }
    
    // MARK: - Card Components
    private var heightCard: some View {
        UserStatCard(
            icon: "ruler",
            value: formatHeight(user.height),
            title: DashboardKeys.Profile.height.localized,
            color: .blue,
            action: nil  // No action for now
        )
    }
    
    private var weightCard: some View {
        UserStatCard(
            icon: "scalemass",
            value: formatWeight(user.currentWeight),
            title: DashboardKeys.Profile.weight.localized,
            color: .green,
            action: nil  // No action for now
        )
    }
    
    private var bodyFatCard: some View {
        UserStatCard(
            icon: "percent",
            value: bodyFatDisplay,
            title: DashboardKeys.Profile.bodyFat.localized,
            color: .orange,
            action: navigateToBodyFatCalculator
        )
    }
    
    private var strengthLevelCard: some View {
        UserStatCard(
            icon: isStrengthLevelEmpty ? "plus.circle" : "chart.line.uptrend.xyaxis",
            value: isStrengthLevelEmpty ? DashboardKeys.Profile.takeTest.localized : strengthLevelDisplay,
            title: DashboardKeys.Profile.strengthLevel.localized,
            color: isStrengthLevelEmpty ? .blue : strengthLevelColor,
            action: strengthLevelAction
        )
    }
    
    // MARK: - Computed Properties
    
    private var bodyFatDisplay: String {
        if let bodyFat = user.calculateBodyFatPercentage() {
            return String(format: "%.1f%%", bodyFat)
        }
        return "--"
    }
    
    private var strengthLevelDisplay: String {
        let (levelString, _) = getOverallStrengthLevel()
        return levelString
    }
    
    private var strengthLevelColor: Color {
        let (_, strengthLevel) = getOverallStrengthLevel()
        
        guard let level = strengthLevel else { return .gray }
        
        switch level {
        case .beginner: return .red
        case .novice: return .orange
        case .intermediate: return .yellow
        case .advanced: return .green
        case .expert: return .blue
        case .elite: return .purple
        }
    }
    
    private func formatHeight(_ height: Double) -> String {
        if unitSettings.unitSystem == .metric {
            return "\(Int(height))cm"
        } else {
            let totalInches = height * 0.393701
            let feet = Int(totalInches / 12)
            let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
            return "\(feet)'\(inches)\""
        }
    }
    
    private func formatWeight(_ weight: Double) -> String {
        if unitSettings.unitSystem == .metric {
            return String(format: "%.1fkg", weight)
        } else {
            let pounds = weight * 2.20462
            return String(format: "%.1flb", pounds)
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
    
    private var isStrengthLevelEmpty: Bool {
        return strengthLevelDisplay == "--"
    }
    
    // MARK: - Actions
    private func strengthLevelAction() {
        if isStrengthLevelEmpty {
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
    let color: Color
    let action: (() -> Void)?
    
    // Computed property to detect call-to-action state
    private var isCallToAction: Bool {
        return action != nil && (value == DashboardKeys.Profile.takeTest.localized || value == "--")
    }
    
    var body: some View {
        VStack(spacing: theme.spacing.xs) {
            // Value with larger, bolder text
            Text(value)
                .font(isCallToAction ? .callout.bold() : .title3.bold())
                .foregroundColor(isCallToAction ? color : theme.colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            // Title with better spacing
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundColor(theme.colors.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, idealHeight: 60)
        .padding(theme.spacing.m)
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
        // Haptic feedback
        HapticManager.shared.impact(.light)
        
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
        .environmentObject(UnitSettings.shared)
}