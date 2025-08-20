import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var tabRouter: TabRouter
    @EnvironmentObject private var healthKitService: HealthKitService
    
    @StateObject private var viewModel: DashboardViewModel
    
    init() {
        // Initialize with dependency injection
        self._viewModel = StateObject(wrappedValue: DashboardViewModel(healthKitService: HealthKitService()))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DashboardSpacing.sectionSpacing) {
                    if let user = viewModel.currentUser {
                        WelcomeSection(user: user)
                        HealthStatsGrid(user: user)
                    }
                    
                    QuickActionsSection(onWeightEntryTap: {
                        viewModel.showingWeightEntry = true
                    })
                    
                    RecentWorkoutsSection()
                    WeeklyProgressSection(stats: viewModel.weeklyStats)
                }
                .padding(DashboardSpacing.contentPadding)
            }
            .navigationTitle(LocalizationKeys.Dashboard.title.localized)
            .background(theme.colors.backgroundPrimary)
            .refreshable {
                await viewModel.refreshHealthData(modelContext: modelContext)
            }
            .sheet(isPresented: $viewModel.showingWeightEntry) {
                if let user = viewModel.currentUser {
                    WeightEntrySheet(user: user)
                }
            }
        }
        .overlay(alignment: .center) {
            if viewModel.isLoading {
                LoadingOverlay()
            }
        }
        .onAppear {
            Task {
                await viewModel.loadData(with: modelContext)
            }
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
        .modelContainer(for: [User.self, LiftSession.self, Exercise.self, Food.self, NutritionEntry.self])
        .environmentObject(TabRouter())
        .environmentObject(HealthKitService())
}