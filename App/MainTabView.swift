import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LanguageManager.self) private var languageManager
    @Environment(TabRouter.self) private var tabRouter
    @Query private var users: [User]
    @State private var selectedTab = 0
    
    private var currentUser: User {
        users.first ?? createDefaultUser()
    }
    
    var body: some View {
        @Bindable var bindableRouter = tabRouter
        TabView(selection: $bindableRouter.selected) {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("tab.dashboard".localized)
                }
                .tag(0)
            
            TrainingView()
                .tabItem {
                    Image(systemName: "dumbbell.fill")
                    Text("tab.training".localized)
                }
                .tag(1)
            
            NutritionView()
                .tabItem {
                    Image(systemName: "fork.knife")
                    Text("tab.nutrition".localized)
                }
                .tag(2)
            
            AnalyticsTabView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("tab.analytics".localized)
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("tab.profile".localized)
                }
                .tag(4)
        }
        .tint(Color.appPrimary)
        .onAppear(perform: setupTabBarAppearance)
        .onAppear {
            if users.isEmpty {
                let defaultUser = createDefaultUser()
                modelContext.insert(defaultUser)
            }
        }
    }
    
    private func createDefaultUser() -> User {
        User(
            name: "profile.name".localized,
            age: 25,
            gender: .male,
            height: 170,
            currentWeight: 70,
            fitnessGoal: .maintain,
            activityLevel: .moderate
        )
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [User.self, LiftSession.self, Exercise.self, Food.self, NutritionEntry.self])
        .environment(LanguageManager.shared)
}
