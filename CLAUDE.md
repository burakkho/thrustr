# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Quick Reference Links
- [📊 Analytics Development](docs/ANALYTICS.md) - Health & fitness analytics guidelines
- [⌚ Watch Development](docs/WATCH.md) - Apple Watch app development
- [☁️ CloudKit Integration](docs/CLOUDKIT.md) - iCloud sync implementation
- [👨‍💻 Developer Context](docs/DEVELOPER-CONTEXT.md) - Personal context & communication preferences

## Development Commands

### Build and Run
- **Build**: `xcodebuild -project thrustr.xcodeproj -scheme thrustr build`
- **Run**: Use Xcode simulator or device deployment
- **Clean**: Product → Clean Build Folder in Xcode

### Testing
- **Run Tests**: `xcodebuild test -project thrustr.xcodeproj -scheme thrustr -destination 'platform=iOS Simulator,name=iPhone 16'`
- Test files are located in `ThrustrTests/`

## Architecture Overview

### Project Structure
SwiftUI + SwiftData iOS fitness tracking app with feature-based modular architecture:

```
thrustr/
├── App/                    # App entry point and main views
├── Core/                   # Core models and services
│   ├── Models/            # SwiftData models (User, Exercise, Food, etc.)
│   └── Services/          # Business logic services
├── Features/              # Feature modules
│   ├── Analytics/         # Health & fitness analytics [→ docs/ANALYTICS.md]
│   ├── Dashboard/         # Main dashboard with health stats
│   ├── Nutrition/         # Food tracking, barcode scanning, meal logging
│   ├── Profile/           # User profile, onboarding, calculators
│   └── Training/          # Multi-modal workout tracking
├── Shared/                # Shared utilities and reusable components
├── WatchShared/           # Apple Watch shared components [→ docs/WATCH.md]
├── "thrustr Watch App"/   # Native Apple Watch application
└── Resources/             # CSV data files, localizations, assets
```

## Key Architectural Patterns

### Data Layer
- **SwiftData**: Primary persistence layer using `@Model` classes
- **ModelContainer**: Configured with CloudKit support [→ docs/CLOUDKIT.md]
- **DataSeeder**: Automatically seeds database with exercises and foods from CSV files

### State Management
- **@State + @Observable**: Modern iOS 17+ view state management (preferred)
- **TabRouter**: Centralized navigation state management
- **EnvironmentObjects**: Global state (ThemeManager, LanguageManager, UnitSettings)

### Modern MVVM Pattern (iOS 17+ Recommended)

#### ViewModels
```swift
@MainActor
@Observable
class ProfileViewModel {
    var achievements: [Achievement] = []
    var isLoading = false

    private let achievementService: AchievementServiceProtocol

    init(achievementService: AchievementServiceProtocol = AchievementService.self) {
        self.achievementService = achievementService
    }
}
```

#### Views
```swift
struct ProfileView: View {
    @State private var viewModel: ProfileViewModel?

    var body: some View {
        // UI code
        .onAppear {
            if viewModel == nil {
                viewModel = ProfileViewModel()
            }
        }
    }
}
```

#### Services
```swift
struct UserService: Sendable {
    static func updateUser(...) async throws -> UserUpdateResult {
        // Pure business logic
    }
}
```

## Development Guidelines

### Model Usage
- Always use enum computed properties (e.g., `user.genderEnum`) rather than raw string values
- Call `calculateMetrics()` on User model after updating health data
- Use SwiftData descriptors for efficient querying
- Prefer `@Model` classes for persistent data, `@Observable` for transient state

### Theming
- Access theme via `@Environment(\.theme)` in views
- Use design tokens rather than hardcoded values
- Apply `.cardStyle()` modifier for consistent card appearance

### Navigation
- Use TabRouter for main navigation state
- Follow iOS navigation patterns with NavigationStack
- Use `@State` with `@Observable` ViewModels for modern patterns

### Localization
- **Always use LocalizationKeys enum** - never hardcode strings
- Supports 9 languages: Turkish (tr), English (en), German (de), Spanish (es), Italian (it), French (fr), Portuguese (pt), Indonesian (id), Polish (pl)
- Example: `Text(LocalizationKeys.workout_completed.localized)`

### Error Handling
- Use Result types for service operations
- **ErrorUIService**: Centralized error UI display and user feedback
- Display user-friendly error messages via ToastView

### Performance Guidelines
- Use `@MainActor` for UI-related operations
- Leverage async/await for database operations
- Implement proper memory management for large datasets
- Use lazy loading for expensive computations

## Core Services (Quick Reference)

### Essential Services
- **HealthKitService**: Enhanced Apple HealthKit integration
- **AnalyticsService**: Health and fitness analytics processing [→ docs/ANALYTICS.md]
- **UserService**: User data management with CloudKit sync [→ docs/CLOUDKIT.md]
- **ThemeManager**: Light/dark theme switching
- **LanguageManager**: 9-language localization with runtime switching

### Calculator Services
- **OneRMCalculator**: 1RM calculations with multiple formulas
- **HealthCalculator**: BMR, TDEE, macro calculations
- **NavyMethodCalculatorService**: Body fat percentage calculations
- **FitnessLevelCalculator**: FFMI, body fat analysis

### Watch Services [→ docs/WATCH.md]
- **WatchWorkoutViewModel**: Watch-optimized workout tracking
- **EnhancedWatchConnectivityManager**: iPhone-Watch communication

## Key Models

### Training System
- **Exercise**: Main exercise model with category and tracking
- **CardioSession/LiftSession**: Workout sessions with performance tracking
- **WOD**: CrossFit-style workouts with time domains

### Nutrition System
- **Food**: Nutrition database with macros and categories
- **NutritionEntry**: Daily food logging with meals and portions
- **OpenFoodFactsService**: Barcode scanning integration

### User & Health
- **User**: Central profile with health data and calculated metrics
- **BodyTrackingModels**: Comprehensive body measurement tracking
- **HealthIntelligence**: AI-powered health insights

## Context Engineering Notes
- Use TodoWrite tool for progress tracking on complex tasks
- Prefer Edit/MultiEdit tools over Bash for structured file changes
- Use Task agent for complex multi-file operations
- Always explain "why" behind technical decisions in Turkish

---
**Note**: For detailed information on specific modules, refer to the linked documentation files in the `docs/` directory.