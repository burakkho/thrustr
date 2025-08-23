# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Build and Run
- **Build**: Use Xcode or `xcodebuild -project thrustr.xcodeproj -scheme thrustr build`
- **Run**: Use Xcode simulator or device deployment
- **Clean**: Product → Clean Build Folder in Xcode

### Testing
- **Run Tests**: Use Xcode test navigator or `xcodebuild test -project thrustr.xcodeproj -scheme thrustr -destination 'platform=iOS Simulator,name=iPhone 16'`
- Test files are located in `ThrustrTests/`

## Architecture Overview

### Project Structure
This is a SwiftUI + SwiftData iOS fitness tracking app with a feature-based modular architecture:

```
thrustr/
├── App/                    # App entry point and main views
├── Core/                   # Core models and services
│   ├── Models/            # SwiftData models (User, Exercise, Food, etc.)
│   │   ├── Cardio/        # Cardio tracking models
│   │   ├── Lift/          # Strength training models
│   │   └── WOD/           # Workout of the Day models
│   └── Services/          # Business logic services
├── Features/              # Feature modules
│   ├── Dashboard/         # Main dashboard with health stats
│   ├── Nutrition/         # Food tracking, barcode scanning, meal logging
│   ├── Profile/           # User profile, onboarding, calculators
│   └── Training/          # Multi-modal workout tracking
│       ├── Cardio/        # Cardio workout tracking
│       ├── Lift/          # Strength training and programs
│       └── WOD/           # CrossFit-style workouts
├── Shared/                # Shared utilities and reusable components
│   ├── Components/        # Reusable UI components
│   ├── DesignSystem/      # Theme, tokens, and modifiers
│   ├── Calculators/       # Fitness calculation utilities
│   └── Utilities/         # Helper classes and extensions
└── Resources/             # CSV data files, localizations, assets
```

### Key Architectural Patterns

#### Data Layer
- **SwiftData**: Primary persistence layer using `@Model` classes
- **ModelContainer**: Configured in `thrustr.swift` with all model types
- **DataSeeder**: Automatically seeds database with exercises and foods from CSV files on first launch

#### State Management
- **EnvironmentObjects**: Used for global state (ThemeManager, LanguageManager, UnitSettings)
- **@StateObject/@ObservedObject**: For local view state management
- **TabRouter**: Centralized navigation state management

#### Core Services
- **HealthKitService**: Integrates with Apple HealthKit for steps, calories, and weight
- **OpenFoodFactsService**: API integration for barcode scanning and food data
- **ThemeManager**: Handles light/dark theme switching
- **LanguageManager**: Supports multi-language localization (TR, EN, DE, ES)
- **UnitSettings**: Manages metric/imperial unit preferences
- **BluetoothManager**: Bluetooth device connectivity for fitness equipment
- **LocationManager**: GPS tracking for outdoor activities
- **UserService**: Centralized user data management and operations
- **ErrorHandlingService**: Unified error handling and user feedback

#### Design System
- **Theme Protocol**: Centralized theming with tokens (colors, spacing, typography)
- **Tokens**: Design system tokens for consistent spacing, colors, and typography
- **CardStyle**: Reusable view modifier for consistent card styling
- **PressableStyle**: Interactive button and card press animations
- **Reusable Components**: Comprehensive component library for consistent UI

#### Reusable Components (`Shared/Components/`)
- **EmptyStateView**: Standardized empty state with icon, title, and description
- **ToastView**: Non-intrusive notification system with success/error states  
- **HealthStatStrip**: Quick health metrics display with icons and values
- **QuickStatCard**: Dashboard-style metric cards with trend indicators
- **LoadingView**: Consistent loading states across the app
- **GuideSection**: Help text sections with consistent styling
- **LegalDocumentView**: Privacy policy and terms display

### Key Models

#### User Model (`Core/Models/User.swift`)
Central user profile with:
- Personal info (age, gender, height, weight)
- Fitness goals and activity levels
- HealthKit integration data
- Calculated metrics (BMR, TDEE, daily goals)
- Body measurements and workout stats

#### Training System
- **Exercise**: Main exercise model with category, equipment, and tracking capabilities
- **ExerciseSet**: Individual set tracking with weight, reps, time, distance
- **Workout/WorkoutPart**: Hierarchical workout structure

##### Cardio System (`Core/Models/Cardio/`)
- **CardioCategory**: Activity categories (running, cycling, swimming, etc.)
- **CardioExercise**: Specific cardio activities with tracking parameters
- **CardioSession**: Individual workout sessions with duration and intensity
- **CardioResult**: Performance metrics and achievements
- **CardioWorkout**: Planned cardio routines and templates

##### Strength Training System (`Core/Models/Lift/`)
- **Lift**: Core strength exercise model with progression tracking
- **LiftExercise**: Specific exercises with form cues and targeting
- **LiftProgram**: Structured training programs (e.g., StrongLifts 5x5)
- **LiftSession**: Individual workout sessions with set tracking
- **LiftWorkout**: Planned strength routines
- **ProgramExecution**: Progress tracking through structured programs

##### WOD System (`Core/Models/WOD/`)
- **WOD**: Workout of the Day model with time domains and movements
- **WODCategory**: WOD types (AMRAP, For Time, EMOM, Tabata, etc.)
- **WODMovement**: CrossFit movement library with scaling options
- **WODQRData**: QR code sharing for workout distribution
- **WODResult**: Performance tracking and leaderboards
- **WODType**: Workout classification and structure


#### Nutrition System
- **Food**: Nutrition database with macros and categories  
- **FoodAlias**: Multi-language food search aliases
- **NutritionEntry**: Daily food logging with meals and portions
- **NutritionEnums**: Meal types, portion units, and dietary categories
- **FoodCategory+UI**: UI extensions for food categorization

#### Additional Models
- **BodyTrackingModels**: Comprehensive body measurement tracking
- **CrossFitMovement**: CrossFit-specific movement library with scaling
- **Gender**: User gender classification with computed properties
- **ExerciseEnums**: Exercise categories, equipment types, and difficulty levels

### Localization
- Uses custom `LocalizationKeys` enum with `.localized` extension
- Supports multiple languages: Turkish (tr), English (en), German (de), Spanish (es)
- LanguageManager handles runtime language switching
- Localized strings stored in respective .lproj directories

### HealthKit Integration
- Background delivery and observer queries for real-time sync
- Authorization status management
- Automatic data fetching for steps, calories, and weight

### Unit System
- **UnitSettings**: Global unit preference (metric/imperial)
- **UnitsFormatter**: Consistent formatting across the app
- **Units**: Comprehensive unit conversion utilities
- Automatic conversion and display based on user preference

### Utilities (`Shared/Utilities/`)
- **Logger**: Centralized logging system with different log levels
- **DatabaseError**: SwiftData error handling and user-friendly messages
- **QRCodeGenerator**: QR code creation for workout sharing
- **AsyncTimeout**: Timeout utilities for async operations
- **BarcodeValidator**: Barcode format validation and verification
- **HapticManager**: Haptic feedback management and patterns

#### Extensions
- **Color+Extensions**: Theme-aware color utilities and hex support
- **Date+Extension**: Date formatting and calendar operations
- **Double+Extensions**: Numeric formatting and fitness calculations

## Development Guidelines

### Model Usage
- Always use enum computed properties (e.g., `user.genderEnum`) rather than raw string values
- Call `calculateMetrics()` on User model after updating health data
- Use SwiftData descriptors for efficient querying

### Theming
- Access theme via `@Environment(\.theme)` in views
- Use design tokens rather than hardcoded values
- Apply `.cardStyle()` modifier for consistent card appearance

### Navigation
- Use TabRouter for main navigation state
- Implement view-specific navigation state as needed
- Follow iOS navigation patterns with NavigationStack

### Data Seeding
- CSV files in Resources/ are automatically imported on first launch
- DataSeeder handles normalization and categorization
- Exercise categories are mapped to 4 main workout part types

### Error Handling
- Use Result types for service operations
- **ErrorHandlingService**: Centralized error processing and user feedback
- Display user-friendly error messages via ToastView
- **DatabaseError**: SwiftData-specific error handling
- **Logger**: Structured logging for debugging and monitoring

### Reusable Component Guidelines
- Use **EmptyStateView** for all empty states with consistent messaging
- Apply **ToastView** for non-intrusive notifications and feedback
- Implement **LoadingView** for async operations and data fetching
- Use **QuickStatCard** for metric displays with consistent styling
- Apply **HealthStatStrip** for dashboard health metric rows

### Training System Architecture
- **TrainingCoordinator**: Centralized workout state management
- **TimerViewModel**: Shared timer logic across all workout types
- **CardioTimerViewModel** / **WODTimerViewModel**: Specialized timer implementations
- Each training type (Cardio, Lift, WOD) has independent model hierarchies
- Unified workout cards with **UnifiedWorkoutCard** component

