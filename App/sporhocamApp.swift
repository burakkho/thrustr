import SwiftUI
import SwiftData
import HealthKit

@main
struct SporHocamApp: App {
    // Model Container
    let container: ModelContainer
    
    // Theme ve Language Manager'ları ekle
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var tabRouter = TabRouter()
    @StateObject private var healthKitService = HealthKitService()
    @StateObject private var unitSettings = UnitSettings()
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        do {
            container = try ModelContainer(for:
                User.self,
                Exercise.self,
                Food.self,
                FoodAlias.self,
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
                .environmentObject(unitSettings)
                .environment(\.theme, themeManager.designTheme)
                .tint(themeManager.designTheme.colors.accent)
                .onAppear {
                    // Tek kanal tema uygulaması: UIWindow üzerinden override
                    themeManager.refreshTheme()
                    // HealthKit arkaplan güncellemeleri: app aktifken etkinleştir ve gözlem başlat
                    Task { @MainActor in
                        // Sadece HealthKit mevcut ve yetki verilmişse gözlemle
                        if HKHealthStore.isHealthDataAvailable() {
                            let status = healthKitService.getAuthorizationStatus()
                            let anyAuthorized = [status.steps, status.calories, status.weight].contains(.sharingAuthorized)
                            if anyAuthorized {
                                healthKitService.enableBackgroundDelivery()
                                healthKitService.startObserverQueries()
                            } else {
                                // Yetki henüz yoksa ilk açılışta izin istendiğinde devreye girecek
                                print("HealthKit not authorized yet; background delivery will start after authorization.")
                            }
                        }
                    }
                }
                .task {
                    DataSeeder.seedDatabaseIfNeeded(
                        modelContext: container.mainContext
                    )
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        Task { @MainActor in
                            if HKHealthStore.isHealthDataAvailable() {
                                let status = healthKitService.getAuthorizationStatus()
                                let anyAuthorized = [status.steps, status.calories, status.weight].contains(.sharingAuthorized)
                                if anyAuthorized {
                                    healthKitService.enableBackgroundDelivery()
                                    healthKitService.startObserverQueries()
                                }
                            }
                        }
                    }
                }
        }
        .modelContainer(container)
    }
}
