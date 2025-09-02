import SwiftUI
import SwiftData
import HealthKit
import UserNotifications

@main
struct ThrusterApp: App {
    // Model Container
    let container: ModelContainer
    
    // Theme ve Language Manager'ları ekle
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var tabRouter = TabRouter()
    @StateObject private var healthKitService = HealthKitService()
    let unitSettings = UnitSettings.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var isSeedingDatabase = false  // Loading state
    @State private var seedingProgress: SeedingProgress? = nil  // Progress tracking
    @State private var seedingRetryCount = 0  // Retry counter

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
                // Strength Test models
                StrengthTest.self,
                StrengthTestResult.self,
                // Activity tracking
                ActivityEntry.self,
                // Notifications
                UserNotificationSettings.self
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
                        // Strength Test models
                    StrengthTest.self,
                    StrengthTestResult.self,
                    // Activity tracking
                    ActivityEntry.self,
                    // Notifications
                    UserNotificationSettings.self,
                    configurations: config
                )
            } catch {
                // Last resort: Create minimal container for basic functionality
                print("❌ Critical: Cannot create any ModelContainer: \(error)")
                print("🆘 Creating minimal fallback container...")
                
                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                do {
                    container = try ModelContainer(for: User.self, configurations: config)
                    Logger.info("✅ Minimal fallback container created successfully")
                } catch {
                    // Last resort: Create absolute minimal container for app to function
                    Logger.error("❌ Complete database failure: \(error)")
                    print("⚠️ App running in emergency safe mode - limited functionality")
                    
                    // Emergency fallback: try with even more minimal configuration
                    let emergencyConfig = ModelConfiguration(isStoredInMemoryOnly: true, allowsSave: false)
                    do {
                        container = try ModelContainer(for: User.self, configurations: emergencyConfig)
                        print("🆘 Emergency container created - app will function with limited data persistence")
                    } catch {
                        // If this fails, create the most basic container possible
                        print("🔥 Creating absolute minimal container as last resort")
                        container = try! ModelContainer(for: User.self)
                    }
                }
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isSeedingDatabase {
                    LoadingView(
                        progress: seedingProgress,
                        onRetry: {
                            seedingRetryCount += 1
                            Task {
                                await seedDatabaseIfNeeded()
                            }
                        },
                        onSkip: {
                            isSeedingDatabase = false
                            seedingProgress = nil
                        }
                    )
                } else {
                    ContentView()
                        .environmentObject(themeManager)
                        .environmentObject(languageManager)
                        .environmentObject(tabRouter)
                        .environmentObject(unitSettings)
                        .environmentObject(healthKitService)
                        .environmentObject(notificationManager)
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
                                // App going to background - stop observers to save battery
                                Task { @MainActor in
                                    healthKitService.stopObserverQueries()
                                }
                                print("📱 App entering background - HealthKit observers stopped for battery optimization")
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
            seedingProgress = .starting
        }
        
        // DataSeeder with improved thread safety and sequential approach
        Logger.info("🔄 Starting DataSeeder with progress tracking (retry count: \(seedingRetryCount))")
        
        await DataSeeder.seedDatabaseIfNeeded(
            modelContext: container.mainContext,
            progressCallback: { progress in
                await MainActor.run {
                    seedingProgress = progress
                    
                    // Auto-dismiss after completion with delay
                    if case .completed = progress {
                        Task {
                            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                            await MainActor.run {
                                isSeedingDatabase = false
                                seedingProgress = nil
                            }
                        }
                    }
                }
            }
        )
        
        // Fallback: Ensure UI is dismissed even if completion callback fails
        await MainActor.run {
            if seedingProgress != .completed && !seedingProgress!.id.starts(with: "error") {
                isSeedingDatabase = false
                seedingProgress = nil
            }
        }
    }
}
