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
│   │   ├── HealthIntelligence.swift # AI-powered health analytics
│   │   ├── HealthTrends.swift       # Trend analysis and predictions
│   │   ├── Cardio/           # Cardio workout models
│   │   │   └── EquipmentItem.swift # Equipment tracking
│   │   ├── Lift/             # Strength training models
│   │   ├── WOD/              # CrossFit workout models
│   │   ├── Extensions/       # Model extensions and utilities
│   │   │   ├── User+Analytics.swift # User analytics extensions
│   │   │   ├── Workout+Stats.swift  # Workout statistics extensions
│   │   │   └── Model+Validation.swift # Validation extensions
│   │   ├── Tests/            # Model test files and data fixtures
│   │   │   ├── MockData.swift       # Test data generation
│   │   │   ├── ModelTests.swift     # Unit tests for models
│   │   │   └── TestFixtures.swift   # Test data fixtures
│   │   └── WorkoutSession.swift  # Unified workout sessions
│   ├── Services/             # Business logic services
│   │   ├── HealthKitService.swift    # Apple HealthKit integration
│   │   ├── DataSeeder.swift          # Database initialization
│   │   ├── ThemeManager.swift        # App theming system
│   │   ├── LanguageManager.swift     # Localization management
│   │   ├── ErrorHandlingService.swift # Unified error handling
│   │   └── UserService.swift         # User data operations
│   └── Validation/           # Data validation utilities
├── Features/                  # Feature modules
│   ├── Analytics/            # Performance tracking and insights
│   │   ├── Views/           # Analytics dashboard and charts
│   │   ├── ViewModels/      # Analytics data processing
│   │   └── Services/        # Health intelligence algorithms
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
│   ├── Enums/               # Shared enumeration definitions
│   ├── Localization/        # Multi-language support system
│   │   ├── LanguageManager.swift  # Runtime language switching
│   │   ├── LocalizationKeys.swift # Type-safe localization keys
│   │   └── Extensions/      # String localization extensions
│   └── Utilities/            # Helper functions and extensions
└── Resources/                # Static resources and data files
    ├── Legal/               # Privacy policy and legal documents
    ├── Training/            # Exercise and program data
    ├── *.lproj/             # 9 language localization files
    │   ├── tr.lproj/        # Turkish localization
    │   ├── en.lproj/        # English localization
    │   ├── de.lproj/        # German localization
    │   ├── es.lproj/        # Spanish localization
    │   ├── it.lproj/        # Italian localization
    │   ├── fr.lproj/        # French localization
    │   ├── pt.lproj/        # Portuguese localization
    │   ├── id.lproj/        # Indonesian localization
    │   └── pl.lproj/        # Polish localization
    └── CSV files             # Exercise and food databases
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
- `EditableRow`: Editable form components
- `GuideSection`: Help and guidance sections

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
└── 9 Supported Languages (TR/EN/DE/ES/IT/FR/PT/ID/PL)
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
- **Multi-language**: Localization completeness (9 languages)
- **Equipment Integration**: Bluetooth device compatibility
- **Watch Connectivity**: iPhone ↔ Watch data sync

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

## 📊 Analytics Module Architecture

### Health Intelligence Engine
The **Analytics** module provides advanced health and fitness insights through AI-powered analysis:

```
Features/Analytics/
├── Views/
│   ├── AnalyticsView.swift          # Main analytics dashboard
│   ├── TrendChartView.swift         # Interactive trend visualizations
│   ├── PerformanceInsightsView.swift # AI-generated insights
│   └── HealthIntelligenceView.swift  # Health intelligence dashboard
├── ViewModels/
│   ├── AnalyticsViewModel.swift     # Analytics data coordination
│   ├── TrendAnalysisViewModel.swift # Trend calculation and display
│   └── HealthInsightsViewModel.swift # AI insights processing
└── Services/
    ├── TrendAnalysisService.swift  # Statistical trend analysis
    ├── HealthIntelligenceService.swift # AI-powered health insights
    └── PerformanceMetricsService.swift # Performance calculations
```

### Key Analytics Features
- **Trend Analysis**: Statistical analysis of workout performance over time
- **Health Intelligence**: AI-powered insights from HealthIntelligence.swift model
- **Performance Metrics**: Advanced calculations for strength, cardio, and body composition
- **Predictive Analytics**: Future performance predictions based on current trends

## 🌍 Localization Architecture

### Multi-Language Support System
Complete localization infrastructure supporting **9 languages** with runtime switching:

```
Shared/Localization/
├── LanguageManager.swift           # Runtime language switching
├── LocalizationKeys.swift          # Type-safe localization keys
├── Extensions/
│   ├── String+Localization.swift   # String localization extensions
│   └── View+Localization.swift     # SwiftUI localization helpers
└── Utilities/
    └── LocalizationValidator.swift # Localization completeness validation
```

### Supported Languages
- **Turkish (tr)** - Primary market and native language
- **English (en)** - International market
- **German (de)** - European market expansion
- **Spanish (es)** - Hispanic market
- **Italian (it)** - European market
- **French (fr)** - European market
- **Portuguese (pt)** - Brazilian market
- **Indonesian (id)** - Southeast Asian market
- **Polish (pl)** - Eastern European market

### Localization Features
- **Runtime Switching**: Users can change language without app restart
- **Type-Safe Keys**: LocalizationKeys enum prevents missing translations
- **Validation System**: Automated checks for translation completeness
- **Context-Aware**: Different translations for different contexts (UI vs. voice)

## 🧪 Testing Infrastructure

### Model Testing Framework
Comprehensive testing infrastructure with mock data and test fixtures:

```
Core/Models/Tests/
├── MockData.swift              # Test data generation for all models
├── ModelTests.swift            # Unit tests for SwiftData models
├── TestFixtures.swift          # Standardized test data fixtures
├── UserModelTests.swift        # User model specific tests
├── WorkoutModelTests.swift     # Workout model specific tests
└── ValidationTests.swift       # Data validation tests
```

### Test Coverage Areas
- **Model Validation**: SwiftData model integrity and relationships
- **Analytics Calculations**: Health intelligence and trend analysis accuracy
- **Localization**: Translation completeness across all 9 languages
- **Data Seeding**: CSV import and database initialization
- **HealthKit Integration**: Authorization and data sync reliability

## 🏛️ Legal & Compliance Architecture

### Privacy-First Design
Comprehensive legal compliance infrastructure:

```
Resources/Legal/
├── PrivacyPolicy.md            # Comprehensive privacy policy
├── TermsOfService.md          # Terms of service agreement
├── DataUsagePolicy.md         # Health data usage policies
├── CookiePolicy.md            # Cookie and tracking policy
└── ComplianceChecklist.md     # GDPR/CCPA compliance verification
```

### Compliance Features
- **Local-First Storage**: All data stored locally with optional cloud sync
- **Granular Permissions**: Fine-grained control over data sharing
- **Data Portability**: Export functionality for user data ownership
- **Right to Deletion**: Complete data removal capabilities
- **Transparent Policies**: Clear, readable legal documentation

This architecture provides a solid foundation for a comprehensive fitness tracking application while maintaining flexibility for future enhancements and scalability.