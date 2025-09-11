import SwiftUI
import SwiftData
import HealthKit
import UserNotifications

@main
struct ThrusterApp: App {
    // Model Container
    let container: ModelContainer
    
    // Theme ve Language Manager'ları ekle
    @State private var themeManager = ThemeManager()
    @State private var languageManager = LanguageManager.shared
    @State private var tabRouter = TabRouter()
    @State private var healthKitService = HealthKitService()
    let unitSettings = UnitSettings.shared
    @State private var notificationManager = NotificationManager.shared
    
    // CloudKit Services
    @State private var cloudAvailability = CloudKitAvailabilityService.shared
    @State private var cloudSyncManager = CloudSyncManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var isSeedingDatabase = false  // Loading state
    @State private var seedingProgress: SeedingProgress? = nil  // Progress tracking
    @State private var seedingRetryCount = 0  // Retry counter

    init() {
        do {
            // CloudKit + Local Dual Configuration Setup
            container = try Self.createModelContainer()
            Logger.success("✅ ModelContainer created successfully with CloudKit support")
        } catch {
            // Graceful fallback: Try creating a temporary in-memory container
            print("⚠️ Failed to create persistent ModelContainer: \(error)")
            print("🔄 Falling back to temporary in-memory storage...")
            
            do {
                // Create in-memory container as fallback (without CloudKit)
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
                    EquipmentItem.self,
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
    
    // MARK: - CloudKit ModelContainer Creation
    
    /**
     * Creates ModelContainer with CloudKit support and intelligent fallback.
     * 
     * Priority Strategy:
     * 1. CloudKit + Local (if iCloud available)
     * 2. Local only (if CloudKit unavailable) 
     * 3. In-memory (emergency fallback)
     */
    private static func createModelContainer() throws -> ModelContainer {
        // Define all model types
        let modelTypes: [any PersistentModel.Type] = [
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
            EquipmentItem.self,
            // Strength Test models
            StrengthTest.self,
            StrengthTestResult.self,
            // Activity tracking
            ActivityEntry.self,
            // Notifications
            UserNotificationSettings.self
        ]
        
        // Check CloudKit availability
        let cloudAvailability = CloudKitAvailabilityService.shared
        
        if cloudAvailability.isAvailable {
            // Strategy 1: CloudKit + Local Dual Configuration
            do {
                let localConfig = ModelConfiguration("Local")
                let cloudConfig = ModelConfiguration(
                    "Cloud",
                    cloudKitDatabase: .private("iCloud.burakkho.thrustr")
                )
                
                let schema = Schema(modelTypes)
                let container = try ModelContainer(
                    for: schema,
                    configurations: [localConfig, cloudConfig]
                )
                
                Logger.success("☁️ CloudKit + Local dual configuration created")
                return container
                
            } catch {
                Logger.warning("⚠️ CloudKit configuration failed, falling back to local: \(error)")
                // Fall through to local-only
            }
        } else {
            Logger.info("📱 CloudKit unavailable, using local storage only")
        }
        
        // Strategy 2: Local-only Configuration  
        do {
            let localConfig = ModelConfiguration("Local")
            let schema = Schema(modelTypes)
            let container = try ModelContainer(
                for: schema,
                configurations: [localConfig]
            )
            
            Logger.success("📱 Local-only configuration created")
            return container
            
        } catch {
            Logger.error("❌ Local configuration failed: \(error)")
            throw error
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
                        .environment(themeManager)
                        .environment(languageManager)
                        .environment(tabRouter)
                        .environment(unitSettings)
                        .environment(healthKitService)
                        .environment(notificationManager)
                        .environment(cloudAvailability)
                        .environment(cloudSyncManager)
                        .environment(\.theme, themeManager.designTheme)
                        .tint(themeManager.designTheme.colors.accent)
                        .onAppear {
                            // Tek kanal tema uygulaması: UIWindow üzerinden override
                            themeManager.refreshTheme()
                            
                            // Configure CloudKit sync with container
                            cloudSyncManager.configure(with: container)
                            
                            // Start automatic sync if CloudKit is available
                            if cloudAvailability.isAvailable {
                                cloudSyncManager.startAutomaticSync()
                                
                                // Perform initial sync
                                Task {
                                    await cloudSyncManager.sync()
                                }
                            }
                            
                            // Clear badge when app becomes active
                            Task {
                                await notificationManager.clearBadge()
                            }
                            
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
                                    // HealthKit setup
                                    if HKHealthStore.isHealthDataAvailable() {
                                        let status = healthKitService.getAuthorizationStatus()
                                        let anyAuthorized = [status.steps, status.calories, status.weight].contains(.sharingAuthorized)
                                        if anyAuthorized {
                                            healthKitService.enableBackgroundDelivery()
                                            healthKitService.startObserverQueries()
                                        }
                                    }
                                    
                                    // CloudKit sync on app active
                                    if cloudSyncManager.canSync {
                                        await cloudSyncManager.syncOnAppActive()
                                    }
                                }
                            case .background:
                                // App going to background - stop observers to save battery
                                Task { @MainActor in
                                    await healthKitService.stopObserverQueries()
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
