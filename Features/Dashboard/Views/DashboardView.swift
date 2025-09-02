import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var tabRouter: TabRouter
    @EnvironmentObject private var healthKitService: HealthKitService
    @EnvironmentObject private var unitSettings: UnitSettings
    
    @StateObject private var viewModel: DashboardViewModel
    
    init() {
        // Initialize with dependency injection
        self._viewModel = StateObject(wrappedValue: DashboardViewModel(healthKitService: HealthKitService()))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: theme.spacing.l) {
                    // Progressive Loading - Show content as it becomes available
                    
                    // Welcome Section - Show when user data is loaded
                    if viewModel.isUserDataLoaded, let user = viewModel.currentUser {
                        WelcomeSection(user: user)
                    } else {
                        SkeletonWelcomeSection()
                    }
                    
                    // Quick Status Section - Show when health/workout data is loaded
                    if viewModel.isHealthDataLoaded && viewModel.isWorkoutDataLoaded {
                        QuickStatusSection(viewModel: viewModel)
                    } else {
                        HStack(spacing: theme.spacing.m) {
                            SkeletonActionableStatCard()
                            SkeletonActionableStatCard()
                            SkeletonActionableStatCard()
                        }
                    }
                    
                    // Recent Activity Section - Show when all data is loaded
                    if viewModel.isWorkoutDataLoaded && viewModel.isNutritionDataLoaded {
                        RecentActivitySection(viewModel: viewModel)
                    } else if viewModel.isUserDataLoaded {
                        // Show activity skeleton if we have user data but not activity data
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                SkeletonView(height: 20, width: 150)
                                Spacer()
                                SkeletonView(height: 16, width: 80)
                            }
                            SkeletonList(itemCount: 3, spacing: 8)
                        }
                        .padding()
                    }
                }
                .padding(theme.spacing.m)
            }
            .safeAreaInset(edge: .bottom) {
                // Reserve space for tab bar to prevent content overlap
                Color.clear.frame(height: 49)
            }
            .navigationTitle(DashboardKeys.title.localized)
            .background(theme.colors.backgroundPrimary)
            .refreshable {
                await viewModel.refreshHealthData(modelContext: modelContext)
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(DashboardKeys.title.localized)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
        .onAppear {
            viewModel.unitSettings = unitSettings
            Task {
                await viewModel.loadData(with: modelContext)
            }
        }
        .onChange(of: unitSettings.unitSystem) { _, _ in
            viewModel.updateUnitSettings(unitSettings)
        }
        .onChange(of: healthKitService.todaySteps) { _, _ in
            Task {
                await viewModel.refreshHealthData(modelContext: modelContext)
            }
        }
        .onChange(of: healthKitService.todayCalories) { _, _ in
            Task {
                await viewModel.refreshHealthData(modelContext: modelContext)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .activityLogged)) { _ in
            Task {
                await viewModel.loadData(with: modelContext)
            }
        }
    }
}

// MARK: - Loading Overlay Component
private struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle())
        }
    }
}


#Preview {
    DashboardView()
        .modelContainer(for: [User.self, LiftSession.self, Exercise.self, Food.self, NutritionEntry.self, ActivityEntry.self])
        .environmentObject(TabRouter())
        .environmentObject(HealthKitService())
        .environmentObject(UnitSettings.shared)
}