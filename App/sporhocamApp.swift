import SwiftUI
import SwiftData

@main
struct sporhocamApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var languageManager = LanguageManager.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            // Core Models
            User.self,
            Exercise.self,
            Workout.self,
            WorkoutPart.self,
            ExerciseSet.self,
            Goal.self,
            
            // Nutrition Models
            Food.self,
            NutritionEntry.self,
            
            // Body Tracking Models
            WeightEntry.self,
            BodyMeasurement.self,
            ProgressPhoto.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .environmentObject(languageManager)
                .onAppear {
                    print("🚀 App started with language: \(languageManager.currentLanguage.displayName)")
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
