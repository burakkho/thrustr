import SwiftUI
import SwiftData

@main
struct SporHocamApp: App {
    let container: ModelContainer
    
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
                .task {
                    // await kaldırıldı çünkü fonksiyon async değil
                    DataSeeder.seedDatabaseIfNeeded(
                        modelContext: container.mainContext
                    )
                }
        }
        .modelContainer(container)
    }
}
