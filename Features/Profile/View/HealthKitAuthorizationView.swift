import SwiftUI
import HealthKit

struct HealthKitAuthorizationView: View {
    @State private var healthKitService = HealthKitService.shared
    @Environment(\.theme) private var theme
    @State private var unitSettings = UnitSettings.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Header
                VStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 50))
                        .foregroundColor(theme.colors.accent)
                    
                    Text(CommonKeys.HealthKit.authorizationTitle.localized)
                        .font(theme.typography.heading1)
                        .fontWeight(.bold)
                    
                    Text(CommonKeys.HealthKit.authorizationSubtitle.localized)
                        .font(theme.typography.body)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // MARK: - Authorization Summary
                AuthorizationSummaryCard()
                
                // MARK: - Detailed Permissions
                VStack(spacing: 16) {
                    Text(CommonKeys.HealthKit.detailedPermissions.localized)
                        .font(theme.typography.heading2)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(healthDataCategories, id: \.title) { category in
                            HealthDataCategoryCard(category: category)
                        }
                    }
                }
                
                // MARK: - Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await healthKitService.requestPermissions()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text(CommonKeys.HealthKit.refreshPermissions.localized)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.colors.accent)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button(action: openHealthApp) {
                        HStack {
                            Image(systemName: "heart.text.square")
                            Text(CommonKeys.HealthKit.openHealthApp.localized)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.colors.cardBackground)
                        .foregroundColor(theme.colors.textPrimary)
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .navigationTitle(CommonKeys.HealthKit.authorizationTitle.localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await healthKitService.readTodaysData()
            }
        }
    }
    
    private func openHealthApp() {
        if let url = URL(string: "x-apple-health://") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Authorization Summary Card
struct AuthorizationSummaryCard: View {
    @State private var healthKitService = HealthKitService.shared
    @Environment(\.theme) private var theme
    
    var body: some View {
        let summary = healthKitService.getAuthorizationStatusSummary()
        
        HStack(spacing: 20) {
            VStack {
                Text("\(summary.authorized)")
                    .font(theme.typography.heading1)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Text(CommonKeys.HealthKit.authorized.localized)
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            Divider()
                .frame(height: 40)
            
            VStack {
                Text("\(summary.denied)")
                    .font(theme.typography.heading1)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                
                Text(CommonKeys.HealthKit.denied.localized)
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            Divider()
                .frame(height: 40)
            
            VStack {
                Text("\(summary.notDetermined)")
                    .font(theme.typography.heading1)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                
                Text(CommonKeys.HealthKit.notDetermined.localized)
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
        .padding(20)
        .background(theme.colors.cardBackground)
        .cornerRadius(12)
        .cardStyle()
    }
}

// MARK: - Health Data Category Card
struct HealthDataCategoryCard: View {
    let category: HealthDataCategory
    @State private var healthKitService = HealthKitService.shared
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(category.color)
                
                Spacer()
                
                StatusBadge(status: getAuthorizationStatus())
            }
            
            Text(category.title)
                .font(theme.typography.body)
                .fontWeight(.medium)
            
            Text(category.description)
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.colors.textSecondary)
                .lineLimit(2)
        }
        .padding(12)
        .background(theme.colors.cardBackground)
        .cornerRadius(10)
        .cardStyle()
    }
    
    private func getAuthorizationStatus() -> HKAuthorizationStatus {
        // Get the first data type from this category
        if let firstIdentifier = category.dataTypes.first {
            return healthKitService.authorizationStatuses[firstIdentifier] ?? .notDetermined
        }
        return .notDetermined
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: HKAuthorizationStatus
    @Environment(\.theme) private var theme
    
    var body: some View {
        Text(statusText)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor)
            .foregroundColor(.white)
            .cornerRadius(6)
    }
    
    private var statusText: String {
        switch status {
        case .sharingAuthorized:
            return "✓"
        case .sharingDenied:
            return "✗"
        case .notDetermined:
            return "?"
        @unknown default:
            return "?"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .sharingAuthorized:
            return .green
        case .sharingDenied:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .gray
        }
    }
}

// MARK: - Health Data Category Model
struct HealthDataCategory {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let dataTypes: [String]
}

// MARK: - Health Data Categories
let healthDataCategories: [HealthDataCategory] = [
    HealthDataCategory(
        title: CommonKeys.HealthKit.activityCategory.localized,
        description: CommonKeys.HealthKit.activityDescription.localized,
        icon: "figure.walk",
        color: .blue,
        dataTypes: [
            HKQuantityTypeIdentifier.stepCount.rawValue,
            HKQuantityTypeIdentifier.activeEnergyBurned.rawValue,
            HKQuantityTypeIdentifier.basalEnergyBurned.rawValue,
            HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue
        ]
    ),
    HealthDataCategory(
        title: CommonKeys.HealthKit.heartCategory.localized,
        description: CommonKeys.HealthKit.heartDescription.localized,
        icon: "heart.fill",
        color: .red,
        dataTypes: [
            HKQuantityTypeIdentifier.heartRate.rawValue,
            HKQuantityTypeIdentifier.restingHeartRate.rawValue,
            HKQuantityTypeIdentifier.heartRateVariabilitySDNN.rawValue,
            HKQuantityTypeIdentifier.vo2Max.rawValue
        ]
    ),
    HealthDataCategory(
        title: CommonKeys.HealthKit.bodyCategory.localized,
        description: CommonKeys.HealthKit.bodyDescription.localized,
        icon: "scalemass.fill",
        color: .green,
        dataTypes: [
            HKQuantityTypeIdentifier.bodyMass.rawValue,
            HKQuantityTypeIdentifier.height.rawValue,
            HKQuantityTypeIdentifier.bodyMassIndex.rawValue,
            HKQuantityTypeIdentifier.bodyFatPercentage.rawValue
        ]
    ),
    HealthDataCategory(
        title: CommonKeys.HealthKit.sleepCategory.localized,
        description: CommonKeys.HealthKit.sleepDescription.localized,
        icon: "bed.double.fill",
        color: .purple,
        dataTypes: [
            HKCategoryTypeIdentifier.sleepAnalysis.rawValue
        ]
    ),
    HealthDataCategory(
        title: CommonKeys.HealthKit.workoutCategory.localized,
        description: CommonKeys.HealthKit.workoutDescription.localized,
        icon: "dumbbell.fill",
        color: .orange,
        dataTypes: [
            HKWorkoutType.workoutType().identifier
        ]
    ),
    HealthDataCategory(
        title: CommonKeys.HealthKit.nutritionCategory.localized,
        description: CommonKeys.HealthKit.nutritionDescription.localized,
        icon: "fork.knife",
        color: .yellow,
        dataTypes: [
            HKQuantityTypeIdentifier.dietaryEnergyConsumed.rawValue,
            HKQuantityTypeIdentifier.dietaryProtein.rawValue,
            HKQuantityTypeIdentifier.dietaryCarbohydrates.rawValue
        ]
    )
]

#Preview {
    NavigationView {
        HealthKitAuthorizationView()
    }
}