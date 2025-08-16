# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Build and Run
- **Build**: Use Xcode or `xcodebuild -project sporhocam.xcodeproj -scheme sporhocam build`
- **Run**: Use Xcode simulator or device deployment
- **Clean**: Product → Clean Build Folder in Xcode

### Testing
- **Run Tests**: Use Xcode test navigator or `xcodebuild test -project sporhocam.xcodeproj -scheme sporhocam -destination 'platform=iOS Simulator,name=iPhone 15'`
- Test files are located in `sporhocamTests/`

## Architecture Overview

### Project Structure
This is a SwiftUI + SwiftData iOS fitness tracking app with a feature-based modular architecture:

```
sporhocam/
├── App/                    # App entry point and main views
├── Core/                   # Core models and services
│   ├── Models/            # SwiftData models (User, Exercise, Food, etc.)
│   └── Services/          # Business logic services
├── Features/              # Feature modules
│   ├── Dashboard/         # Main dashboard
│   ├── Nutrition/         # Food tracking and nutrition
│   ├── Profile/           # User profile and onboarding
│   └── Training/          # Workout tracking
├── Shared/                # Shared utilities and components
└── Resources/             # CSV data files and assets
```

### Key Architectural Patterns

#### Data Layer
- **SwiftData**: Primary persistence layer using `@Model` classes
- **ModelContainer**: Configured in `sporhocamApp.swift` with all model types
- **DataSeeder**: Automatically seeds database with exercises and foods from CSV files on first launch

#### State Management
- **EnvironmentObjects**: Used for global state (ThemeManager, LanguageManager, UnitSettings)
- **@StateObject/@ObservedObject**: For local view state management
- **TabRouter**: Centralized navigation state management

#### Core Services
- **HealthKitService**: Integrates with Apple HealthKit for steps, calories, and weight
- **OpenFoodFactsService**: API integration for barcode scanning and food data
- **ThemeManager**: Handles light/dark theme switching
- **LanguageManager**: Supports Turkish and English localization
- **UnitSettings**: Manages metric/imperial unit preferences

#### Design System
- **Theme Protocol**: Centralized theming with tokens (colors, spacing, typography)
- **CardStyle**: Reusable view modifier for consistent card styling
- **Custom Components**: EmptyStateView, ToastView, HealthStatStrip, etc.

### Key Models

#### User Model (`Core/Models/User.swift`)
Central user profile with:
- Personal info (age, gender, height, weight)
- Fitness goals and activity levels
- HealthKit integration data
- Calculated metrics (BMR, TDEE, daily goals)
- Body measurements and workout stats

#### Exercise System
- **Exercise**: Main exercise model with category, equipment, and tracking capabilities
- **ExerciseSet**: Individual set tracking with weight, reps, time, distance
- **Workout/WorkoutPart**: Hierarchical workout structure

#### Nutrition System
- **Food**: Nutrition database with macros and categories
- **FoodAlias**: Multi-language food search aliases
- **NutritionEntry**: Daily food logging with meals and portions

### Localization
- Uses custom `LocalizationKeys` enum with `.localized` extension
- Supports Turkish (tr) and English (en)
- LanguageManager handles runtime language switching

### HealthKit Integration
- Background delivery and observer queries for real-time sync
- Authorization status management
- Automatic data fetching for steps, calories, and weight

### Unit System
- **UnitSettings**: Global unit preference (metric/imperial)
- **UnitsFormatter**: Consistent formatting across the app
- Automatic conversion and display based on user preference

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
- Display user-friendly error messages via ToastView
- Log errors for debugging while maintaining user experience