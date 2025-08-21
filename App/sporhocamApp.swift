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
    
    @State private var isSeedingDatabase = false  // ← Loading state ekle

    init() {
        do {
            container = try ModelContainer(for:
                User.self,
                Exercise.self,
                Food.self,
                FoodAlias.self,
                // Nutrition
                NutritionEntry.self,
                WeightEntry.self,
                BodyMeasurement.self,
                ProgressPhoto.self,
                Goal.self,
                // Training programs
                WOD.self,
                WODMovement.self,
                WODResult.self,
                CrossFitMovement.self,
                // Lift models
                Lift.self,
                LiftProgram.self,
                LiftWorkout.self,
                LiftExercise.self,
                LiftSession.self,
                LiftExerciseResult.self,
                LiftResult.self,
                ProgramExecution.self,
                CompletedWorkout.self,
                // Cardio models
                CardioWorkout.self,
                CardioExercise.self,
                CardioSession.self,
                CardioResult.self,
                // WarmUp models
                WarmUpTemplate.self,
                WarmUpSession.self
            )
        } catch {
            // Graceful fallback: Try creating a temporary in-memory container
            print("⚠️ Failed to create persistent ModelContainer: \(error)")
            print("🔄 Falling back to temporary in-memory storage...")
            
            do {
                // Create in-memory container as fallback
                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                container = try ModelContainer(for:
                    User.self,
                    Exercise.self,
                    Food.self,
                    FoodAlias.self,
                    // Nutrition
                    NutritionEntry.self,
                    WeightEntry.self,
                    BodyMeasurement.self,
                    ProgressPhoto.self,
                    Goal.self,
                    // Training programs
                    WOD.self,
                    WODMovement.self,
                    WODResult.self,
                    CrossFitMovement.self,
                    // Lift models
                    Lift.self,
                    LiftProgram.self,
                    LiftWorkout.self,
                    LiftExercise.self,
                    LiftSession.self,
                    LiftExerciseResult.self,
                    LiftResult.self,
                    ProgramExecution.self,
                    CompletedWorkout.self,
                    // Cardio models
                    CardioWorkout.self,
                    CardioExercise.self,
                    CardioSession.self,
                    CardioResult.self,
                    // WarmUp models
                    WarmUpTemplate.self,
                    WarmUpSession.self,
                    configurations: config
                )
            } catch {
                // Last resort: Create minimal container for basic functionality
                print("❌ Critical: Cannot create any ModelContainer: \(error)")
                print("🆘 Creating minimal fallback container...")
                
                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                do {
                    container = try ModelContainer(for: User.self, configurations: config)
                } catch {
                    // If we can't even create a minimal container, the app has deeper issues
                    fatalError("💥 Critical failure: Cannot initialize any data storage: \(error)")
                }
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isSeedingDatabase {
                    LoadingView()  // ← Kullanıcıya loading göster
                } else {
                    ContentView()
                        .environmentObject(themeManager)
                        .environmentObject(languageManager)
                        .environmentObject(tabRouter)
                        .environmentObject(unitSettings)
                        .environmentObject(healthKitService)
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
                        .onChange(of: scenePhase) { _, newPhase in
                            switch newPhase {
                            case .active:
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
                            case .background:
                                // App going to background - keep observers but log the state
                                print("📱 App entering background - HealthKit observers remain active")
                            case .inactive:
                                // App becoming inactive - prepare for potential cleanup
                                print("📱 App becoming inactive")
                            @unknown default:
                                break
                            }
                        }
                }
            }
            .task {
                // Database seeding'i background'da yap
                await seedDatabaseIfNeeded()
            }
            .modelContainer(container)
        }
    }
    
    // MARK: - Database Seeding
    private func seedDatabaseIfNeeded() async {
        await MainActor.run {
            isSeedingDatabase = true
        }
        
        // DataSeeder with improved thread safety and sequential approach (warmup disabled)
        Logger.info("🔄 Starting DataSeeder (warmup seeding disabled for stability)")
        
        await DataSeeder.seedDatabaseIfNeeded(
            modelContext: container.mainContext
        )
        
        await MainActor.run {
            isSeedingDatabase = false
        }
    }
}
