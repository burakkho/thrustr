//
//  MainTabView.swift
//  SporHocam
//
//  Created by Assistant on 10/8/25.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @State private var selectedTab = 0
    
    private var currentUser: User {
        users.first ?? createDefaultUser()
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Ana Sayfa")
                }
                .tag(0)
            
            TrainingView()
                .tabItem {
                    Image(systemName: "dumbbell.fill")
                    Text("Antrenman")
                }
                .tag(1)
            
            NutritionView()
                .tabItem {
                    Image(systemName: "fork.knife")
                    Text("Beslenme")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profil")
                }
                .tag(3)
        }
        .accentColor(.blue)
        .onAppear {
            if users.isEmpty {
                let defaultUser = createDefaultUser()
                modelContext.insert(defaultUser)
            }
        }
    }
    
    private func createDefaultUser() -> User {
        User(
            name: "Kullanıcı",
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
        .modelContainer(for: [User.self, Workout.self, Exercise.self, Food.self, NutritionEntry.self])
}
