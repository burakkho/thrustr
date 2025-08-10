import SwiftUI
import SwiftData

@main
struct SporHocamApp: App {
    // Model Container
    let container: ModelContainer
    
    // Theme ve Language Manager'ları ekle
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var languageManager = LanguageManager.shared
    
    init() {
        do {
            container = try ModelContainer(for:
                User.self,
                Exercise.self,
                Food.self,
                Workout.self,
                WorkoutPart.self,
                ExerciseSet.self,
                NutritionEntry.self,
                BodyMeasurement.self,
                Goal.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)      // ⬅️ ThemeManager eklendi
                .environmentObject(languageManager)    // ⬅️ LanguageManager eklendi
                .preferredColorScheme(themeManager.isDarkMode ? .dark : .light) // ⬅️ Dark mode desteği
                .task {
                    DataSeeder.seedDatabaseIfNeeded(
                        modelContext: container.mainContext
                    )
                }
        }
        .modelContainer(container)
    }
}
