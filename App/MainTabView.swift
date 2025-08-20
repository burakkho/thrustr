import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var tabRouter: TabRouter
    @Query private var users: [User]
    @State private var selectedTab = 0
    
    private var currentUser: User {
        users.first ?? createDefaultUser()
    }
    
    var body: some View {
        TabView(selection: $tabRouter.selected) {
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
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("tab.profile".localized)
                }
                .tag(3)
        }
        .tint(Color.appPrimary)
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
}

#Preview {
    MainTabView()
        .modelContainer(for: [User.self, LiftSession.self, Exercise.self, Food.self, NutritionEntry.self])
        .environmentObject(LanguageManager.shared)
}
