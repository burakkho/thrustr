import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false
    @Query private var existingUsers: [User]

    var body: some View {
        LocalizationView {
            if onboardingCompleted {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .overlay {
            // Global error handling overlay
            ErrorAlertView()
        }
        .onAppear {
            // Gating: Eğer veritabanında kullanıcı varsa onboarding'i atla
            if !onboardingCompleted && !existingUsers.isEmpty {
                onboardingCompleted = true
            }
        }
    }
}

// MARK: - LocalizationView Wrapper
struct LocalizationView<Content: View>: View {
    @StateObject private var languageManager = LanguageManager.shared
    @State private var refreshID = UUID()
    
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .id(refreshID) // Force refresh when language changes
            .onReceive(NotificationCenter.default.publisher(for: .languageDidChange)) { _ in
                refreshID = UUID() // Force view refresh
                print("🔄 UI refreshed due to language change")
            }
            .environmentObject(languageManager)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Exercise.self, User.self, Workout.self, WorkoutPart.self, ExerciseSet.self], inMemory: true)
}
