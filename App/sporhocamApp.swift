import SwiftUI
import SwiftData

@main
struct SporHocamApp: App {
    // Model Container
    let container: ModelContainer
    
    // Theme ve Language Manager'ları ekle
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var tabRouter = TabRouter()
    
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
                .environmentObject(themeManager)
                .environmentObject(languageManager)
                .environmentObject(tabRouter)
                .environment(\.theme, themeManager.designTheme)
                .tint(themeManager.designTheme.colors.accent)
                .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
                .task {
                    DataSeeder.seedDatabaseIfNeeded(
                        modelContext: container.mainContext
                    )
                }
        }
        .modelContainer(container)
    }
}
