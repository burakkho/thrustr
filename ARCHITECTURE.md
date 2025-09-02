# Thrustr Architecture Documentation

## 🏗️ Architecture Overview

Thrustr follows a **feature-based modular architecture** with clear separation of concerns, built on modern iOS technologies including SwiftUI, SwiftData, and reactive programming patterns.

### Core Architectural Principles

1. **Feature-based Organization**: Each major feature has its own module with views, view models, and feature-specific logic
2. **Reactive Data Flow**: Leveraging SwiftUI's reactive patterns with `@Published`, `@ObservableObject`, and `@StateObject`
3. **Dependency Injection**: Environment-based dependency injection for services and managers
4. **Protocol-Oriented Design**: Protocols for theming, data sources, and service abstractions
5. **Single Source of Truth**: SwiftData as the primary data persistence layer

## 📁 Project Structure

```
thrustr/
├── App/                        # Application entry point
│   ├── thrustr.swift          # App entry point with ModelContainer setup
│   ├── ContentView.swift      # Root content view with onboarding logic
│   └── MainTabView.swift      # Main tab navigation
├── Core/                       # Core business logic and data models
│   ├── Models/                # SwiftData model definitions
│   │   ├── User.swift         # Central user profile model
│   │   ├── Exercise.swift     # Exercise database model
│   │   ├── Food.swift         # Nutrition database model
│   │   ├── Cardio/           # Cardio workout models
│   │   ├── Lift/             # Strength training models
│   │   └── WOD/              # CrossFit workout models
│   ├── Services/             # Business logic services
│   │   ├── HealthKitService.swift    # Apple HealthKit integration
│   │   ├── DataSeeder.swift          # Database initialization
│   │   ├── ThemeManager.swift        # App theming system
│   │   ├── LanguageManager.swift     # Localization management
│   │   └── UserService.swift         # User data operations
│   └── Validation/           # Data validation utilities
├── Features/                  # Feature modules
│   ├── Dashboard/            # Main dashboard with health stats
│   ├── Nutrition/            # Food tracking and meal logging
│   ├── Profile/              # User profile and settings
│   └── Training/             # Multi-modal workout tracking
│       ├── Cardio/           # Cardio workout tracking
│       ├── Lift/             # Strength training
│       ├── WOD/              # CrossFit-style workouts
│       └── Shared/           # Shared training components
├── Shared/                   # Shared utilities and components
│   ├── Components/           # Reusable UI components
│   ├── DesignSystem/         # Theming and design tokens
│   ├── Calculators/          # Fitness calculation utilities
│   └── Utilities/            # Helper functions and extensions
└── Resources/                # Static resources and data files
    ├── CSV files             # Exercise and food databases
    ├── JSON templates        # Workout program templates
    └── Localizations         # Multi-language support
```

## 🔄 Data Flow Architecture

### 1. Data Persistence Layer

**SwiftData (Primary)**
- `@Model` classes for all persistent entities
- Automatic relationship management
- Background seeding via `DataSeeder`
- Thread-safe operations with `ModelContext`

```swift
@Model
final class User {
    // Comprehensive user profile with calculated metrics
    var bmr: Double // Calculated from personal data
    var tdee: Double // Derived from BMR + activity level  
    // ... other properties
}
```

### 2. Service Layer

**Core Services**
- `HealthKitService`: Apple HealthKit integration with caching
- `ThemeManager`: App-wide theming with real-time updates
- `LanguageManager`: Runtime language switching
- `UserService`: Centralized user data operations
- `DataSeeder`: Database initialization and CSV/JSON import

**Service Communication Pattern**
```swift
@StateObject private var healthKitService = HealthKitService()
@StateObject private var themeManager = ThemeManager()

// Environment injection for child views
.environmentObject(healthKitService)
.environmentObject(themeManager)
```

### 3. State Management

**Global State** (Environment Objects)
- `ThemeManager`: App theming state
- `LanguageManager`: Localization state  
- `HealthKitService`: Health data state
- `UnitSettings`: Metric/Imperial preferences
- `TabRouter`: Navigation state

**Local State** (View-specific)
- `@StateObject` for view models
- `@State` for UI-only state
- `@Published` properties in ObservableObject classes

### 4. UI Layer Architecture

**Design System**
```swift
protocol Theme {
    var colors: Colors { get }
    var spacing: Spacing { get }
    var radius: Radius { get }
    var shadows: Shadows { get }
    var typography: Typography { get }
}

// Usage in views
@Environment(\.theme) private var theme
```

**Reusable Components**
- `EmptyStateView`: Standardized empty states
- `ToastView`: Non-intrusive notifications
- `LoadingView`: Consistent loading indicators
- `QuickStatCard`: Metric display cards
- `HealthStatStrip`: Dashboard health metrics

## 📊 Domain Models & Relationships

### User-Centric Design
```
User (Central Hub)
├── Personal Data (age, gender, height, weight)
├── Health Metrics (BMR, TDEE, daily goals)
├── Workout Stats (total workouts, volume, PRs)
├── Preferences (units, language, theme)
└── Equipment Setup (available plates, home gym)
```

### Training System Hierarchy
```
Training System
├── Cardio
│   ├── CardioExercise (running, cycling, swimming)
│   ├── CardioSession (duration, distance, calories)
│   └── CardioResult (performance tracking)
├── Lift (Strength Training)
│   ├── LiftExercise (compound movements)
│   ├── LiftProgram (structured programs)
│   ├── LiftSession (workout tracking)
│   └── LiftResult (PR tracking)
└── WOD (CrossFit-style)
    ├── WOD (workout definitions)
    ├── WODMovement (exercise library)
    ├── WODResult (performance tracking)
    └── CrossFitMovement (scaling options)
```

### Nutrition System
```
Nutrition
├── Food (nutritional database)
├── FoodAlias (multi-language search)
├── NutritionEntry (daily food logging)
└── WeightEntry (weight tracking)
```

## 🌐 External Integrations

### Apple HealthKit
```
HealthKitService
├── Authorization Management
├── Background Data Delivery
├── Observer Queries (real-time sync)
├── Data Validation & Sanitization
└── Cached Operations (5-minute validity)
```

### OpenFoodFacts API
```
Nutrition Integration
├── Barcode Scanning
├── Food Database Lookup  
├── Nutritional Data Extraction
├── Image URL Retrieval
└── Multi-language Support
```

### Localization System
```
Multi-language Support
├── Runtime Language Switching
├── LocalizationKeys Enum
├── .localized String Extension
├── Fallback to System Language
└── 5 Supported Languages (TR/EN/DE/ES/IT)
```

## ⚡ Performance Optimizations

### Database Operations
- **Sequential Seeding**: SwiftData compatibility with batch processing
- **Background Seeding**: UI remains responsive during initialization
- **Efficient Queries**: SwiftData descriptors for optimized fetching
- **Relationship Management**: Automatic inverse relationships

### Memory Management
- **Lazy Loading**: Expensive calculations deferred until needed
- **View Lifecycle**: Proper `@StateObject` vs `@ObservedObject` usage
- **Background Processing**: Heavy operations off main thread
- **Caching Strategy**: 5-minute cache for HealthKit data

### UI Performance
- **Design System**: Pre-computed design tokens
- **Component Reuse**: Shared components reduce memory footprint
- **Efficient Updates**: SwiftUI's reactive updates minimize re-renders
- **Asset Optimization**: Efficient image and resource loading

## 🔒 Security & Privacy

### Data Protection
- **Local Storage**: All user data stored locally via SwiftData
- **HealthKit Privacy**: Proper authorization request flow
- **Secure Logging**: No sensitive data in logs
- **User Consent**: Explicit consent tracking with timestamps

### Privacy Controls
- **Optional Data Sharing**: User controls all external integrations
- **Minimal Data Collection**: Only essential data collected
- **Transparent Permissions**: Clear permission request descriptions
- **Data Portability**: Export capabilities for user data

## 🧪 Testing Strategy

### Unit Testing
- **Model Logic**: Business logic in model classes
- **Calculators**: Fitness calculation accuracy
- **Service Layer**: API integration and data processing
- **Validation**: Input validation and error handling

### Integration Testing
- **Database Operations**: SwiftData integration tests
- **HealthKit Integration**: Authorization and data sync
- **UI Navigation**: Navigation flow validation
- **Multi-language**: Localization completeness

## 🚀 Scalability Considerations

### Code Organization
- **Feature Modules**: Easy to add new fitness modalities
- **Protocol Design**: Extensible service architecture
- **Dependency Injection**: Easy service swapping and testing
- **Shared Components**: Reusable UI elements

### Data Scalability
- **Efficient Relationships**: Proper SwiftData relationship design
- **Batch Operations**: Optimized for large datasets
- **Background Processing**: Heavy operations don't block UI
- **Storage Management**: Efficient local data storage

### Future Extensions
- **Watch Connectivity**: Foundation for watchOS companion
- **Cloud Sync**: Architecture supports future cloud integration
- **Social Features**: User model designed for future sharing
- **Additional Training Types**: Modular training system

## 🔧 Development Workflow

### Code Quality
- **Swift Style Guide**: Consistent coding standards
- **Protocol-Oriented**: Extensible and testable design
- **Error Handling**: Comprehensive error management
- **Documentation**: Inline documentation for complex logic

### Build System
- **Xcode Project**: Standard iOS project structure
- **SwiftUI Previews**: Rapid UI development and testing
- **Automatic Seeding**: Database populated on first launch
- **Resource Management**: Efficient CSV/JSON processing

This architecture provides a solid foundation for a comprehensive fitness tracking application while maintaining flexibility for future enhancements and scalability.