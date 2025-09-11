📋 THRUSTR CLEAN ARCHITECTURE REFACTORING - COMPLETE MASTER PLAN

  ---
  🎯 PROJECT OVERVIEW

  Projenin Amacı:

  Thrustr iOS fitness uygulamasını Swift 6 native, SOLID principles %100 compliant,
  enterprise-grade Clean Architecture'a migrate etmek.

  Current State:

  - Swift 6 migration tamamlanmış ama architecture debt var
  - LiftSessionView runtime crashes (SwiftData context issues)
  - Exercise addition broken
  - Mixed architecture patterns
  - SOLID compliance: 6/10

  Target State:

  - Enterprise-grade Clean Architecture
  - Zero crashes, stable 4 core features
  - SOLID compliance: 9/10
  - Professional iOS development showcase
  - Portfolio-worthy codebase

  ---
  🗂️ TARGET FOLDER STRUCTURE (Detaylı)

  thrustr/
  ├── App/                                    # Entry Point & Configuration
  │   ├── Configuration/
  │   │   ├── AppConfiguration.swift          # App-wide settings
  │   │   ├── DependencyContainer.swift       # DI container (Swift 6)
  │   │   └── Environment.swift               # Environment variables
  │   └── Main/
  │       ├── thrustr.swift                   # App entry point
  │       ├── ContentView.swift               # Root view
  │       └── MainTabView.swift               # Tab navigation
  │
  ├── Domain/                                 # 🏋️ BUSINESS LOGIC LAYER
  │   ├── Entities/                          # Core business models (pure Swift)
  │   │   ├── User/
  │   │   │   ├── User.swift                  # User business entity
  │   │   │   ├── BodyMetrics.swift          # Height, weight, body fat
  │   │   │   ├── FitnessGoals.swift         # Goals, targets, preferences
  │   │   │   └── UserPreferences.swift      # Settings, units, themes
  │   │   ├── Training/
  │   │   │   ├── Workout/
  │   │   │   │   ├── WorkoutSession.swift    # Active workout state
  │   │   │   │   ├── WorkoutTemplate.swift  # Workout blueprints
  │   │   │   │   └── WorkoutResult.swift     # Completed workout data
  │   │   │   ├── Exercise/
  │   │   │   │   ├── Exercise.swift          # Exercise definitions
  │   │   │   │   ├── ExerciseSet.swift       # Individual set data
  │   │   │   │   ├── ExerciseCategory.swift  # Muscle groups, types
  │   │   │   │   └── ExerciseVariation.swift # Exercise modifications
  │   │   │   └── Programs/
  │   │   │       ├── TrainingProgram.swift   # Structured programs
  │   │   │       └── ProgramExecution.swift  # Program progress
  │   │   ├── Nutrition/
  │   │   │   ├── Food/
  │   │   │   │   ├── Food.swift              # Food items
  │   │   │   │   ├── FoodCategory.swift      # Food classifications
  │   │   │   │   └── NutritionalInfo.swift   # Macros, calories, etc
  │   │   │   ├── Meal/
  │   │   │   │   ├── Meal.swift              # Breakfast, lunch, etc
  │   │   │   │   ├── MealEntry.swift         # Individual food entries
  │   │   │   │   └── Portion.swift           # Serving sizes
  │   │   │   └── Goals/
  │   │   │       ├── NutritionGoals.swift    # Daily calorie/macro targets
  │   │   │       └── MacroTargets.swift      # Protein/carb/fat ratios
  │   │   └── Health/
  │   │       ├── HealthMetrics.swift         # Steps, calories, heart rate
  │   │       ├── BiometricData.swift         # Health measurements
  │   │       └── HealthTrends.swift          # Progress over time
  │   │
  │   ├── UseCases/                          # Business operations (pure logic)
  │   │   ├── Training/
  │   │   │   ├── Lift/
  │   │   │   │   ├── StartLiftSessionUseCase.swift    # Session initialization
  │   │   │   │   ├── AddExerciseUseCase.swift         # Add exercise to session
  │   │   │   │   ├── CompleteSetUseCase.swift         # Mark set as complete
  │   │   │   │   └── FinishWorkoutUseCase.swift       # Session completion
  │   │   │   ├── Cardio/
  │   │   │   │   ├── StartCardioSessionUseCase.swift  # Cardio workout start
  │   │   │   │   ├── TrackCardioMetricsUseCase.swift  # Distance, time, pace
  │   │   │   │   └── FinishCardioUseCase.swift        # Cardio completion
  │   │   │   └── METCON/
  │   │   │       ├── StartWODUseCase.swift            # WOD initialization
  │   │   │       ├── TrackWODProgressUseCase.swift    # Round/rep tracking
  │   │   │       └── ScoreWODUseCase.swift           # Final scoring
  │   │   ├── Nutrition/
  │   │   │   ├── LogMealUseCase.swift                # Food entry logging
  │   │   │   ├── ScanBarcodeUseCase.swift            # Barcode food lookup
  │   │   │   ├── CalculateNutritionUseCase.swift     # Daily nutrition calc
  │   │   │   └── UpdateNutritionGoalsUseCase.swift   # Goal modifications
  │   │   ├── Health/
  │   │   │   ├── SyncHealthKitDataUseCase.swift      # HealthKit integration
  │   │   │   ├── UpdateBodyMetricsUseCase.swift      # Weight, measurements
  │   │   │   └── CalculateHealthTrendsUseCase.swift  # Progress analytics
  │   │   └── Analytics/
  │   │       ├── GenerateWorkoutInsightsUseCase.swift # Workout analysis
  │   │       ├── TrackProgressUseCase.swift           # Progress monitoring
  │   │       └── CalculatePersonalRecordsUseCase.swift # PR tracking
  │   │
  │   ├── Services/                          # Domain services (business rules)
  │   │   ├── Training/
  │   │   │   ├── WorkoutCalculationService.swift     # Volume, intensity calc
  │   │   │   ├── PersonalRecordService.swift         # PR detection/tracking
  │   │   │   └── ProgramProgressionService.swift     # Program advancement
  │   │   ├── Nutrition/
  │   │   │   ├── NutritionCalculationService.swift   # Macro calculations
  │   │   │   ├── MacroDistributionService.swift      # Macro balance logic
  │   │   │   └── CalorieCalculationService.swift     # TDEE, BMR calculations
  │   │   └── Health/
  │   │       ├── HealthMetricsCalculationService.swift # Health calculations
  │   │       └── BiometricAnalysisService.swift       # Trend analysis
  │   │
  │   └── Repositories/                      # Abstract data contracts
  │       ├── UserRepositoryProtocol.swift            # User data operations
  │       ├── WorkoutRepositoryProtocol.swift         # Workout CRUD
  │       ├── ExerciseRepositoryProtocol.swift        # Exercise database
  │       ├── NutritionRepositoryProtocol.swift       # Food/meal operations
  │       └── HealthRepositoryProtocol.swift          # Health data access
  │
  ├── Data/                                  # 💾 DATA ACCESS LAYER
  │   ├── Repositories/                      # Concrete repository implementations
  │   │   ├── SwiftData/                     # Primary persistence layer
  │   │   │   ├── SwiftDataUserRepository.swift       # User data operations
  │   │   │   ├── SwiftDataWorkoutRepository.swift    # Workout persistence
  │   │   │   ├── SwiftDataExerciseRepository.swift   # Exercise database
  │   │   │   └── SwiftDataNutritionRepository.swift  # Nutrition tracking
  │   │   └── Cache/                         # Performance optimization
  │   │       ├── InMemoryExerciseCache.swift         # Exercise caching
  │   │       └── NutritionDataCache.swift            # Food data caching
  │   │
  │   ├── DataSources/                       # External data source abstractions
  │   │   ├── Local/
  │   │   │   ├── SwiftDataManager.swift              # @MainActor SwiftData wrapper
  │   │   │   ├── UserDefaultsManager.swift           # Settings persistence
  │   │   │   └── CoreDataMigrationManager.swift      # Legacy data migration
  │   │   ├── External/
  │   │   │   ├── HealthKit/
  │   │   │   │   ├── HealthKitDataSource.swift       # HealthKit integration
  │   │   │   │   └── HealthKitPermissionManager.swift # Permission handling
  │   │   │   ├── OpenFoodFacts/
  │   │   │   │   ├── OpenFoodFactsAPI.swift          # Food database API
  │   │   │   │   └── FoodDatabaseService.swift       # Food lookup service
  │   │   │   └── Bluetooth/
  │   │   │       ├── BluetoothDataSource.swift       # Device data collection
  │   │   │       └── FitnessDeviceManager.swift      # Device management
  │   │   └── Seeding/
  │   │       ├── ExerciseSeedingService.swift        # Exercise database init
  │   │       ├── FoodSeedingService.swift            # Food database init
  │   │       └── CSVDataLoader.swift                 # CSV import utility
  │   │
  │   └── Models/                            # Data layer models
  │       ├── SwiftData/
  │       │   ├── UserEntity.swift                    # @Model User class
  │       │   ├── WorkoutEntity.swift                 # @Model Workout class
  │       │   ├── ExerciseEntity.swift                # @Model Exercise class
  │       │   └── NutritionEntity.swift               # @Model Nutrition class
  │       └── DTOs/                          # Data Transfer Objects
  │           ├── HealthKitDTO.swift                  # HealthKit data format
  │           ├── OpenFoodFactsDTO.swift              # API response format
  │           └── ExerciseDatabaseDTO.swift           # Exercise import format
  │
  ├── Presentation/                          # 🎨 UI LAYER (SwiftUI + Swift 6)
  │   ├── Features/                          # Feature-based organization
  │   │   ├── Training/
  │   │   │   ├── Lift/
  │   │   │   │   ├── Views/
  │   │   │   │   │   ├── LiftDashboardView.swift     # Lift section overview
  │   │   │   │   │   ├── LiftSessionView.swift       # ❗ MAIN PROBLEM AREA
  │   │   │   │   │   ├── ExerciseSelectionView.swift # Exercise picker
  │   │   │   │   │   └── Components/
  │   │   │   │   │       ├── ExerciseCard.swift      # Exercise display card
  │   │   │   │   │       ├── SetTrackingRow.swift    # Individual set row
  │   │   │   │   │       └── RestTimerView.swift     # Rest period timer
  │   │   │   │   ├── ViewModels/             # @MainActor @Observable
  │   │   │   │   │   ├── LiftSessionViewModel.swift  # Session state management
  │   │   │   │   │   ├── ExerciseSelectionViewModel.swift # Exercise selection
  │   │   │   │   │   └── LiftAnalyticsViewModel.swift # Lift progress analytics
  │   │   │   │   └── Coordinators/
  │   │   │   │       └── LiftCoordinator.swift       # Complex lift flows
  │   │   │   ├── Cardio/
  │   │   │   │   ├── Views/
  │   │   │   │   │   ├── CardioDashboardView.swift   # Cardio section
  │   │   │   │   │   ├── CardioSessionView.swift     # Live cardio tracking
  │   │   │   │   │   └── CardioAnalyticsView.swift   # Cardio progress
  │   │   │   │   └── ViewModels/
  │   │   │   │       └── CardioSessionViewModel.swift
  │   │   │   └── METCON/
  │   │   │       ├── Views/
  │   │   │       │   ├── WODDashboardView.swift      # WOD section
  │   │   │       │   ├── WODSessionView.swift        # Live WOD tracking
  │   │   │       │   └── WODLeaderboardView.swift    # Scoring/comparison
  │   │   │       └── ViewModels/
  │   │   │           └── WODSessionViewModel.swift
  │   │   ├── Nutrition/
  │   │   │   ├── Views/
  │   │   │   │   ├── NutritionDashboardView.swift    # Nutrition overview
  │   │   │   │   ├── FoodSelectionView.swift         # Food database search
  │   │   │   │   ├── MealEntryView.swift             # Meal logging
  │   │   │   │   ├── BarcodeScannerView.swift        # Barcode scanning
  │   │   │   │   └── Components/
  │   │   │   │       ├── FoodCard.swift              # Food display
  │   │   │   │       ├── MacroRingView.swift         # Macro progress rings
  │   │   │   │       └── CalorieProgressView.swift   # Calorie tracking
  │   │   │   ├── ViewModels/
  │   │   │   │   ├── NutritionDashboardViewModel.swift
  │   │   │   │   ├── FoodSelectionViewModel.swift
  │   │   │   │   └── MealEntryViewModel.swift
  │   │   │   └── Coordinators/
  │   │   │       └── NutritionCoordinator.swift
  │   │   ├── Dashboard/
  │   │   │   ├── Views/
  │   │   │   │   ├── MainDashboardView.swift         # Home screen
  │   │   │   │   ├── HealthOverviewView.swift        # Health summary
  │   │   │   │   └── Components/
  │   │   │   │       ├── QuickStatsCard.swift        # Summary statistics
  │   │   │   │       ├── RecentActivityView.swift    # Recent workouts
  │   │   │   │       └── ProgressChartView.swift     # Progress visualization
  │   │   │   ├── ViewModels/
  │   │   │   │   └── DashboardViewModel.swift        # Dashboard state
  │   │   │   └── Analytics/
  │   │   │       ├── ProgressAnalyticsView.swift     # Detailed progress
  │   │   │       └── HealthInsightsView.swift        # Health analytics
  │   │   └── Profile/
  │   │       ├── Views/
  │   │       │   ├── ProfileView.swift               # User profile
  │   │       │   ├── SettingsView.swift              # App settings
  │   │       │   └── GoalsView.swift                 # Fitness goals
  │   │       ├── ViewModels/
  │   │       │   ├── ProfileViewModel.swift
  │   │       │   └── SettingsViewModel.swift
  │   │       └── Onboarding/
  │   │           ├── OnboardingCoordinator.swift     # Onboarding flow
  │   │           ├── WelcomeStepView.swift           # Welcome screen
  │   │           ├── PersonalInfoStepView.swift      # Personal data entry
  │   │           └── GoalsStepView.swift             # Goal setting
  │   │
  │   ├── Common/                            # Shared UI components
  │   │   ├── Components/
  │   │   │   ├── Buttons/
  │   │   │   │   ├── PrimaryButton.swift             # Main action button
  │   │   │   │   └── SecondaryButton.swift           # Secondary actions
  │   │   │   ├── Cards/
  │   │   │   │   ├── BaseCard.swift                  # Card container
  │   │   │   │   └── StatCard.swift                  # Statistic display
  │   │   │   ├── Forms/
  │   │   │   │   ├── FormField.swift                 # Input field
  │   │   │   │   └── NumberInput.swift               # Numeric input
  │   │   │   ├── Progress/
  │   │   │   │   ├── ProgressRing.swift              # Circular progress
  │   │   │   │   └── LoadingView.swift               # Loading states
  │   │   │   └── Fitness/                   # Fitness-specific components
  │   │   │       ├── TimerView.swift                 # Workout timers
  │   │   │       ├── WeightPicker.swift              # Weight selection
  │   │   │       ├── RepCounter.swift                # Rep counting
  │   │   │       └── WorkoutIntensityPicker.swift    # RPE/intensity
  │   │   ├── Modifiers/
  │   │   │   ├── CardStyle.swift                     # Card styling
  │   │   │   └── ButtonStyle.swift                   # Button styling
  │   │   └── ViewModels/
  │   │       └── BaseViewModel.swift                 # @MainActor @Observable base
  │   │
  │   ├── Navigation/
  │   │   ├── TabCoordinator.swift                    # Tab navigation
  │   │   ├── WorkoutCoordinator.swift                # Complex workout flows
  │   │   └── OnboardingCoordinator.swift             # Onboarding navigation
  │   │
  │   └── Theme/                             # Design system
  │       ├── DesignSystem/
  │       │   ├── ColorSystem.swift                   # Color definitions
  │       │   ├── TypographySystem.swift              # Font system
  │       │   └── SpacingSystem.swift                 # Layout spacing
  │       ├── Colors.swift                            # Color extensions
  │       ├── Typography.swift                        # Typography extensions
  │       └── ComponentTokens.swift                   # Design tokens
  │
  ├── Infrastructure/                        # 🔧 EXTERNAL CONCERNS
  │   ├── Services/                          # External integrations
  │   │   ├── HealthKit/
  │   │   │   ├── HealthKitService.swift              # @MainActor @Observable
  │   │   │   └── HealthKitPermissionService.swift    # Permission management
  │   │   ├── Bluetooth/
  │   │   │   ├── BluetoothManager.swift              # Device connectivity
  │   │   │   └── HeartRateMonitor.swift              # HR monitoring
  │   │   ├── Location/
  │   │   │   └── LocationManager.swift               # GPS for outdoor cardio
  │   │   ├── Analytics/
  │   │   │   └── AnalyticsService.swift              # Usage analytics
  │   │   └── Notifications/
  │   │       ├── WorkoutReminderService.swift        # Workout reminders
  │   │       └── RestTimerService.swift              # Rest notifications
  │   │
  │   ├── Networking/
  │   │   ├── NetworkService.swift                    # Network operations
  │   │   ├── APIClient.swift                         # HTTP client
  │   │   └── NetworkMonitor.swift                    # Connectivity monitoring
  │   │
  │   ├── Storage/
  │   │   ├── FileManager.swift                       # File operations
  │   │   ├── ImageCache.swift                        # Exercise images
  │   │   └── BackupService.swift                     # Data backup
  │   │
  │   └── Utils/                             # Cross-cutting utilities
  │       ├── Logger.swift                            # Logging system
  │       ├── HapticManager.swift                     # Haptic feedback
  │       ├── TimerManager.swift                      # Timer utilities
  │       ├── UnitConverter.swift                     # Unit conversions
  │       └── MathUtils.swift                         # Fitness calculations
  │
  └── Resources/                             # 📁 STATIC RESOURCES
      ├── Data/                              # Seed data files
      │   ├── exercises.csv                           # Exercise database
      │   ├── foods.csv                               # Food database
      │   └── workout_templates.json                  # Workout templates
      ├── Localization/
      │   ├── en.lproj/Localizable.strings           # English translations
      │   ├── tr.lproj/Localizable.strings           # Turkish translations
      │   └── [other supported languages]
      └── Assets.xcassets
          ├── Exercise Images/                        # Exercise demonstrations
          ├── Food Images/                            # Food photos
          └── App Icons/                              # App iconography

  ---
  🚀 5-SPRINT IMPLEMENTATION PLAN

  SPRINT 1: FOUNDATION SETUP (2-3 gün)

  Focus: Klasör yapısı + Infrastructure layer migration

  Day 1: Folder Structure Creation (2 saat)

  Tasks:
  - Ana klasörleri oluştur: Domain/, Data/, Presentation/, Infrastructure/
  - Tüm alt klasör hiyerarşisini complete et (yukarıdaki yapıya göre)
  - README dosyalarını her ana klasöre ekle (açıklayıcı)
  - Git branch: feature/clean-architecture-foundation

  Commands to run:
  mkdir -p Domain/{Entities/{User,Training/{Workout,Exercise,Programs},Nutrition/{Food,Meal
  ,Goals},Health},UseCases/{Training/{Lift,Cardio,METCON},Nutrition,Health,Analytics},Servi
  ces/{Training,Nutrition,Health},Repositories}

  mkdir -p Data/{Repositories/{SwiftData,Cache},DataSources/{Local,External/{HealthKit,Open
  FoodFacts,Bluetooth},Seeding},Models/{SwiftData,DTOs}}

  mkdir -p
  Presentation/{Features/{Training/{Lift/{Views,ViewModels,Coordinators},Cardio/{Views,View
  Models},METCON/{Views,ViewModels}},Nutrition/{Views,ViewModels,Coordinators},Dashboard/{V
  iews,ViewModels,Analytics},Profile/{Views,ViewModels,Onboarding}},Common/{Components/{But
  tons,Cards,Forms,Progress,Fitness},Modifiers,ViewModels},Navigation,Theme/{DesignSystem}}

  mkdir -p Infrastructure/{Services/{HealthKit,Bluetooth,Location,Analytics,Notifications},
  Networking,Storage,Utils}

  Day 2: Infrastructure Layer Migration (4 saat)

  Migration mapping:
  - Core/Services/HealthKitService.swift →
  Infrastructure/Services/HealthKit/HealthKitService.swift
  - Core/Services/BluetoothManager.swift →
  Infrastructure/Services/Bluetooth/BluetoothManager.swift
  - Core/Services/LocationManager.swift →
  Infrastructure/Services/Location/LocationManager.swift
  - Shared/Utilities/Logger.swift → Infrastructure/Utils/Logger.swift
  - Shared/Utilities/HapticManager.swift → Infrastructure/Utils/HapticManager.swift
  - Import statements güncelleme
  - Build test → commit if successful

  Day 3: Infrastructure Services Standardization (3 saat)

  - Service interfaces standardize et
  - Swift 6 compliance check (all @MainActor where needed)
  - Dependency injection preparation
  - Full app test - infrastructure complete

  SPRINT 2: DOMAIN LAYER CREATION (3-4 gün)

  Focus: Business logic extraction + domain entities

  Day 1: Core Entities (4 saat)

  User Domain:
  - Core/Models/User.swift → extract business logic → Domain/Entities/User/User.swift
  - Create Domain/Entities/User/BodyMetrics.swift
  - Create Domain/Entities/User/FitnessGoals.swift
  - Create Domain/Entities/User/UserPreferences.swift

  Training Domain:
  - Core/Models/Lift/LiftSession.swift →
  Domain/Entities/Training/Workout/WorkoutSession.swift
  - Extract business logic from SwiftData models

  Day 2: Use Cases Implementation - Training (5 saat)

  Lift Use Cases:
  - Create Domain/UseCases/Training/Lift/StartLiftSessionUseCase.swift
  - Create Domain/UseCases/Training/Lift/AddExerciseUseCase.swift
  - Create Domain/UseCases/Training/Lift/CompleteSetUseCase.swift
  - Create Domain/UseCases/Training/Lift/FinishWorkoutUseCase.swift
  - Extract business logic from existing ViewModels

  Day 3: Use Cases Implementation - Nutrition & Health (3 saat)

  Nutrition Use Cases:
  - Create Domain/UseCases/Nutrition/LogMealUseCase.swift
  - Create Domain/UseCases/Nutrition/ScanBarcodeUseCase.swift
  - Create Domain/UseCases/Nutrition/CalculateNutritionUseCase.swift

  Health Use Cases:
  - Create Domain/UseCases/Health/SyncHealthKitDataUseCase.swift
  - Create Domain/UseCases/Health/UpdateBodyMetricsUseCase.swift

  Day 4: Domain Services & Repository Protocols (2 saat)

  Domain Services:
  - Create Domain/Services/Training/WorkoutCalculationService.swift
  - Create Domain/Services/Nutrition/NutritionCalculationService.swift

  Repository Protocols:
  - Create Domain/Repositories/UserRepositoryProtocol.swift
  - Create Domain/Repositories/WorkoutRepositoryProtocol.swift
  - Create Domain/Repositories/ExerciseRepositoryProtocol.swift
  - Create Domain/Repositories/NutritionRepositoryProtocol.swift

  SPRINT 3: DATA LAYER ABSTRACTION (3 gün)

  Focus: Repository pattern + SwiftData fixes (❗ Critical for crash fixes)

  Day 1: Repository Implementations (4 saat)

  SwiftData Repositories:
  - Create Data/Repositories/SwiftData/SwiftDataUserRepository.swift
  - Create Data/Repositories/SwiftData/SwiftDataWorkoutRepository.swift
  - Create Data/Repositories/SwiftData/SwiftDataExerciseRepository.swift
  - Create Data/Repositories/SwiftData/SwiftDataNutritionRepository.swift
  - Implement repository protocols

  Day 2: Data Sources & Context Management (4 saat)

  Critical Tasks:
  - Create Data/DataSources/Local/SwiftDataManager.swift (❗ @MainActor wrapper)
  - Fix SwiftData context lifecycle management
  - Create Data/DataSources/External/HealthKit/HealthKitDataSource.swift
  - CRITICAL: Fix LiftSessionView SwiftData context crashes

  Day 3: Data Integration & Testing (3 saat)

  - Repository pattern integration tests
  - SwiftData context lifecycle verification
  - CRITICAL: Exercise addition workflow fix
  - Data persistence testing
  - Performance testing

  SPRINT 4: PRESENTATION LAYER REFACTOR (4-5 gün)

  Focus: UI cleanup + ViewModels standardization (❗ Major UI fixes)

  Day 1: Training Feature Migration - Focus on Lift (5 saat)

  LiftSessionView Decomposition (❗ Major Problem Area):
  - Features/Training/Views/Lift/LiftSessionView.swift →
  Presentation/Features/Training/Lift/Views/LiftSessionView.swift
  - Decompose LiftSessionView:
    - Create ExerciseCard.swift component
    - Create SetTrackingRow.swift component
    - Create RestTimerView.swift component
  - Create LiftSessionViewModel.swift (@MainActor @Observable)
  - CRITICAL: Fix exercise addition flow
  - CRITICAL: Fix runtime crashes

  Day 2: Shared Components Creation (4 saat)

  Common Components:
  - Create Presentation/Common/Components/Buttons/PrimaryButton.swift
  - Create Presentation/Common/Components/Cards/BaseCard.swift
  - Create Presentation/Common/Components/Fitness/TimerView.swift
  - Create Presentation/Common/Components/Fitness/WeightPicker.swift
  - Create Presentation/Common/Components/Fitness/RepCounter.swift

  Day 3: Cardio & METCON Features (3 saat)

  - Features/Training/Views/Cardio/ → Presentation/Features/Training/Cardio/
  - Features/Training/Views/WOD/ → Presentation/Features/Training/METCON/
  - ViewModels standardization (@MainActor @Observable pattern)

  Day 4: Nutrition Feature Migration (3 saat)

  - Features/Nutrition/ → Presentation/Features/Nutrition/
  - ViewModels standardization
  - Food selection, meal entry UI cleanup
  - Barcode scanning integration

  Day 5: Dashboard & Profile Migration (2 saat)

  - Features/Dashboard/ → Presentation/Features/Dashboard/
  - Features/Profile/ → Presentation/Features/Profile/
  - Analytics views organization
  - Navigation coordination setup

  SPRINT 5: CLEANUP & FINALIZATION (1-2 gün)

  Focus: DI container + final cleanup + testing

  Day 1: Dependency Injection Implementation (3 saat)

  DI Container:
  - Create App/Configuration/DependencyContainer.swift
  - Service dependency management
  - Repository injection setup
  - Use case dependency wiring
  - ViewModels dependency injection

  Day 2: Final Cleanup & Testing (4 saat)

  Cleanup Tasks:
  - Delete Core/ and Features/ folders (old structure)
  - Import statements comprehensive cleanup
  - Missing localizations fix: "training.category.plyometric"
  - Code formatting standardization

  Testing Tasks:
  - Full app testing - all 4 core features
  - Lift Training: Complete session without crashes ✅
  - Cardio Training: Full workout tracking ✅
  - METCON/WOD: WOD completion and scoring ✅
  - Nutrition: Food logging and analytics ✅
  - Performance regression testing

  Day 3: Documentation & Polish (3 saat - Optional)

  - Architecture documentation update
  - Code comments standardization
  - README updates
  - Final build optimization

  ---
  🎯 SUCCESS CRITERIA & METRICS

  Technical Metrics:

  - SOLID Compliance: 6/10 → 9/10
  - Build Success: No compilation errors
  - Code Organization: Max 200 lines per class
  - Swift 6 Native: Full strict concurrency compliance
  - Architecture Layers: Clear separation Domain/Data/Presentation/Infrastructure

  Functional Metrics:

  - Zero Crashes: No runtime errors in core features
  - Lift Training: Session creation, exercise addition, set completion, session finish
  - Cardio Training: Session tracking, metrics recording, completion
  - METCON/WOD: WOD execution, progress tracking, scoring
  - Nutrition: Food search, meal logging, macro tracking
  - Dashboard: Data aggregation, progress visualization

  Quality Metrics:

  - Maintainability: Easy to understand and modify
  - Testability: Business logic easily testable
  - Scalability: Easy to add new features
  - Performance: No regression in app performance

  ---
  🔍 CRITICAL PROBLEM AREAS TO FIX

  1. LiftSessionView Crash (❗ HIGHEST PRIORITY)

  Current Issue: SwiftData context nil access causing fatal errors
  Root Cause: MVVM/DTO pattern conflicting with SwiftData lifecycle
  Sprint 3 Fix: Repository pattern + proper context management
  Sprint 4 Fix: Clean View decomposition + ViewModel standardization

  2. Exercise Addition Broken (❗ HIGH PRIORITY)

  Current Issue: Exercise selection not adding to workout session
  Root Cause: Broken data flow in refactored LiftSessionView
  Sprint 3 Fix: Repository-based exercise addition use case
  Sprint 4 Fix: UI flow restoration

  3. Mixed Architecture Patterns (❗ MEDIUM PRIORITY)

  Current Issue: Some views use direct SwiftData, others use ViewModels
  Root Cause: Inconsistent patterns across the app
  Sprint 4 Fix: Standardize all views to consistent MVVM + Repository pattern

  4. Missing Localizations (❗ LOW PRIORITY)

  Current Issue: "training.category.plyometric" and potentially others
  Sprint 5 Fix: Comprehensive localization audit and completion

  ---
  📅 TIMELINE SUMMARY

  | Sprint   | Duration | Focus Area   | Key Deliverable                   | Critical Fixes
      |
  |----------|----------|--------------|-----------------------------------|---------------
  ----|
  | Sprint 1 | 2-3 gün  | Foundation   | Folder structure + Infrastructure | -
      |
  | Sprint 2 | 3-4 gün  | Domain Layer | Business logic extraction         | -
      |
  | Sprint 3 | 3 gün    | Data Layer   | Repository pattern                | SwiftData 
  crashes |
  | Sprint 4 | 4-5 gün  | Presentation | UI refactor + ViewModels          | Exercise 
  addition |
  | Sprint 5 | 1-2 gün  | Finalization | DI + cleanup + testing            | Localization
      |

  Total Duration: 13-17 working days (2-3 weeks)

  ---
  🏆 EXPECTED OUTCOMES

  Technical Achievements:

  - ✅ Enterprise-grade Clean Architecture implementation
  - ✅ SOLID principles 100% compliance
  - ✅ Swift 6 native with zero concurrency issues
  - ✅ Maintainable, scalable, testable codebase
  - ✅ Industry-standard folder organization

  Business Value:

  - ✅ Stable 4 core features (Lift, Cardio, METCON, Nutrition)
  - ✅ Zero runtime crashes
  - ✅ Professional user experience
  - ✅ Foundation for future feature development
  - ✅ App Store ready quality

  Developer Growth:

  - ✅ Advanced iOS architecture skills
  - ✅ Clean Architecture mastery
  - ✅ Professional development practices
  - ✅ Portfolio-worthy project showcase
  - ✅ Senior-level iOS developer capabilities

  ---
  🔥 MOTIVATION & MILESTONES

  Daily Wins:

  - Day 1: "Foundation structure created - professional organization!"
  - Day 5: "Domain layer complete - clean business logic!"
  - Day 8: "Data layer solid - no more crashes!"
  - Day 12: "UI beautiful and functional - all features working!"
  - Day 15: "Enterprise-grade fitness app achieved!"

  Sprint Celebrations:

  - Sprint 1 Complete: 🎉 Infrastructure organized, foundation solid!
  - Sprint 2 Complete: 🎊 Business logic clean, domain established!
  - Sprint 3 Complete: 🚀 Data access stable, crashes eliminated!
  - Sprint 4 Complete: 🏆 UI polished, all features functional!
  - Sprint 5 Complete: 🥇 Production-ready fitness app achieved!

  Final Achievement:

  "Thrustr artık enterprise-level, portfolio-showcase, senior-developer-quality fitness 
  app!"

  ---
  📝 IMPLEMENTATION NOTES

  Key Reminders:

  1. Build after each major migration - ensure no breaking changes
  2. Test core features after each sprint - maintain functionality
  3. Commit frequently with descriptive messages - track progress
  4. Document architectural decisions - future reference
  5. Focus on SOLID principles - quality over speed

  Risk Mitigation:

  - Each sprint builds incrementally on previous
  - Core functionality maintained throughout
  - Rollback plan available at each milestone
  - Comprehensive testing at sprint boundaries

  ---
  🚀 READY TO BUILD THE PERFECT FITNESS APP! 🚀