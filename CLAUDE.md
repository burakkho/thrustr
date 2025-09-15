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
│       └── Calculators/   # Fitness calculation utilities and business logic
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
- **@State + @Observable**: Modern iOS 17+ view state management (preferred)
- **@StateObject/@ObservedObject**: Legacy pattern, avoid in new code
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

#### Calculator Services (`Core/Services/Calculators/`)
- **OneRMCalculator**: 1RM calculations with multiple formulas (Brzycki, Epley, Lander)
- **HealthCalculator**: BMR, TDEE, macro calculations with scientific validation
- **FitnessLevelCalculator**: FFMI, body fat analysis, and fitness scoring system

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
- Supports multiple languages: Turkish (tr), English (en), German (de), Spanish (es), Italian (it), French (fr), Portuguese (pt), Indonesian (id), Polish (pl)
- LanguageManager handles runtime language switching
- Localized strings stored in respective .lproj directories

#### iOS .strings File Format Requirements
When working with localization files (`*.lproj/Localizable.strings`), follow these strict format rules:

**Proper Comment Format:**
```
/*
   Localizable.strings (Language)
   Thrustr - Language Localization
*/

// MARK: - Section Name
"key1" = "value1";
"key2" = "value2";
```

**Critical Format Rules:**
- Every line must end with semicolon (`;`)
- Comments use `/* */` for headers, `//` for sections
- MARK sections must be organized by feature/category
- Alphabetical sorting within each MARK section
- No trailing spaces or invalid characters
- Use double quotes for both keys and values

**Common Format Errors to Avoid:**
- Missing semicolons cause "invalid format" build errors
- Improper comment syntax breaks property list parsing
- Bash `echo >>` appends can introduce format issues
- Mixing comment styles (`//` vs `/* */`) inconsistently

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

### Modern NVVM Pattern (iOS 17+ Recommended)

#### ViewModels
- Use `@MainActor @Observable` for all new ViewModels
- Implement dependency injection via constructor
- No `@Published` properties needed with `@Observable`
- Example:
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
- Use `@State private var viewModel: ViewModelType?` for ViewModels
- Initialize ViewModels in `onAppear` for dependency injection
- Example:
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
- Keep services as static methods with no UI state
- Use `Sendable` protocols for thread safety
- Return `Result` types instead of mutating UI state
- Example:
```swift
struct UserService: Sendable {
    static func updateUser(...) async throws -> UserUpdateResult {
        // Pure business logic
    }
}
```

### Model Usage
- Always use enum computed properties (e.g., `user.genderEnum`) rather than raw string values
- Call `calculateMetrics()` on User model after updating health data
- Use SwiftData descriptors for efficient querying
- Prefer `@Model` classes for persistent data, `@Observable` for transient state (iOS 17+)

### Theming
- Access theme via `@Environment(\.theme)` in views
- Use design tokens rather than hardcoded values
- Apply `.cardStyle()` modifier for consistent card appearance
- Theme switching is handled by `ThemeManager` with real-time updates

### Navigation
- Use TabRouter for main navigation state
- Implement view-specific navigation state as needed
- Follow iOS navigation patterns with NavigationStack
- Use `@State` with `@Observable` ViewModels for modern iOS 17+ patterns
- Use `@StateObject` only for legacy compatibility when needed

### Data Seeding
- CSV files in Resources/ are automatically imported on first launch
- DataSeeder handles normalization and categorization with batch processing
- Exercise categories are mapped to 4 main workout part types
- Seeding is sequential for SwiftData compatibility and stability
- Background seeding with loading state for better UX

### Error Handling
- Use Result types for service operations
- **ErrorHandlingService**: Centralized error processing and user feedback
- Display user-friendly error messages via ToastView
- **DatabaseError**: SwiftData-specific error handling with recovery options
- **Logger**: Structured logging for debugging and monitoring
- Graceful fallbacks for database initialization failures

### Reusable Component Guidelines
- Use **EmptyStateView** for all empty states with consistent messaging
- Apply **ToastView** for non-intrusive notifications and feedback
- Implement **LoadingView** for async operations and data fetching
- Use **QuickStatCard** for metric displays with consistent styling
- Apply **HealthStatStrip** for dashboard health metric rows
- **GuideSection** for help text and user guidance

### Training System Architecture
- **TrainingCoordinator**: Centralized workout state management with dashboard section tracking
- **DashboardSection**: Pills-based navigation within dashboard (Overview, Analytics, Tests, Goals)
- **TimerViewModel**: Shared timer logic across all workout types
- **CardioTimerViewModel** / **WODTimerViewModel**: Specialized timer implementations
- Each training type (Cardio, Lift, WOD) has independent model hierarchies
- Unified workout cards with **UnifiedWorkoutCard** component
- Background timer support for long-running workout sessions

#### Navigation Architecture
- **Main Navigation**: 4 tabs (Dashboard, Lift, Cardio, WOD) - simplified from 6 tabs
- **Dashboard Pills**: Overview, Analytics, Tests, Goals with deep navigation to detail screens
- **Sub-navigation**: Each training module maintains its own tab system (Train, Programs, History, etc.)
- **Deep Navigation**: Dashboard sections provide summary + navigation to full detail views

### Performance Guidelines
- Use `@MainActor` for UI-related operations
- Leverage async/await for database operations
- Implement proper memory management for large datasets
- Use lazy loading for expensive computations
- Background processing for data-intensive operations

### Unit System
- All internal storage in metric units (kg, cm, meters)
- **UnitSettings** manages user preference (metric/imperial)
- **UnitsFormatter** handles display conversion
- Automatic conversion in UI layer only

### HealthKit Integration
- Authorization status checking before data access
- Background delivery and observer queries for real-time sync
- Proper error handling for denied permissions
- Data validation and sanitization before storage

### Security & Privacy
- No sensitive data in logs
- User consent tracking with timestamps
- Optional data sharing with clear user control
- Secure handling of health information

## Context Engineering Best Practices

### Large File Management
When working with large files (>25K tokens), use these strategies:

**Token Limit Handling:**
- Use `offset` and `limit` parameters with Read tool for specific portions
- Use Grep tool for targeted content search instead of full file reads
- Delegate complex multi-file operations to Task agent with `general-purpose` subagent

**Safe File Modification Approaches:**
```swift
// ✅ GOOD: Targeted edits with proper context
Edit(old_string: "specific_context_with_unique_match", new_string: "replacement")

// ✅ GOOD: Multiple related edits in one operation
MultiEdit([
  {old_string: "key1", new_string: "value1"},
  {old_string: "key2", new_string: "value2"}
])

// ❌ BAD: Bash append to structured files
echo "content" >> file.strings  // Breaks format and structure
```

### Incremental Development Strategy
**For large-scale changes (like localization):**

1. **Plan & Track**: Use TodoWrite tool for progress tracking
2. **Small Increments**: Work in 10-20 item chunks, not 100+ at once  
3. **Test Frequently**: Build/run tests after each increment
4. **Checkpoint Progress**: Use git commits for rollback safety
5. **Format Preservation**: Always maintain file structure and conventions

**Tool Selection Guidelines:**
- **Edit Tool**: Single targeted changes, small modifications
- **MultiEdit Tool**: 2-10 related changes in same file
- **Task Agent**: Complex multi-file operations, research tasks
- **Bash Commands**: Only for file system operations, never for structured file content

### Localization Workflow Best Practices

**Phase 1: Analysis**
```bash
# Count keys and identify missing translations
wc -l */Localizable.strings
comm -23 reference_keys.txt target_keys.txt | wc -l
```

**Phase 2: Categorized Translation**
```swift
// Organize by feature modules
// 1. Common/Navigation (highest priority)
// 2. Core Features (Dashboard, Training, Nutrition)  
// 3. Secondary Features (Profile, Analytics)
// 4. Supporting Features (Settings, Help)
```

**Phase 3: Quality Control**
- Validate iOS property list format before proceeding
- Check for consistency in terminology within language
- Test build success after each major addition
- Verify no English terms remain in target language

### Recovery Strategies
When file corruption occurs:
1. **Git Reset**: `git checkout HEAD -- corrupted_file` (fastest)
2. **Copy Reference**: Use working language file as template
3. **Incremental Rebuild**: Start fresh with proper methodology
4. **Never**: Try to manually fix corrupted structured files

**Prevention > Recovery**: Always follow incremental, tested approach rather than bulk operations.

## Personal Developer Context

### Communication Preferences
- **Primary Language**: Turkish for explanations, discussions, and teaching
- **Communication Style**: Educational and mentoring approach
- **Explanation Depth**: Always explain the "why" behind technical decisions
- **Tone**: Patient, supportive, and encouraging for learning journey
- **Code Comments**: Use Turkish comments when explaining complex logic

### Developer Profile
- **Background**: No-code developer with 12+ years active fitness experience
- **Fitness Expertise**: 
  - Competed in multiple sports disciplines
  - Deep understanding of training methodologies and workout structures
  - Authentic user perspective on fitness tracking needs
  - Professional knowledge of exercise terminology and progression patterns
- **Technical Experience Level**: 
  - Strong: Product thinking, UX design, business logic, fitness domain knowledge
  - Learning: Swift language, iOS patterns, Xcode workflows, SwiftData, HealthKit
  - Tools: Cursor, ChatGPT, Claude for AI-assisted development
- **Learning Style**: 
  - **Primary**: Visual diagrams + analogies for complex concepts
  - **Secondary**: Step-by-step explanations with clear reasoning
  - **Teaching Format**: Use fitness/sports analogies to explain technical concepts
- **Goals**: Building production-ready iOS fitness app leveraging insider fitness knowledge

### Product Vision & Target Audience
- **Primary Users**: Active athletes and serious fitness enthusiasts
- **Unique Value Proposition**: Built by an athlete, for athletes - authentic workout tracking
- **Competitive Advantage**: Developer's 12+ years competition experience provides insider understanding
- **User Insights**: Real practitioner knowledge of training pain points and workflow needs
- **Feature Priorities**: Focus on functionality that actual athletes need, not superficial gamification

### Teaching Mode Guidelines

**When to Explain Concepts:**
- Introducing new Swift/iOS patterns not yet used in the project
- Making architectural decisions that affect app structure
- Working with complex Apple frameworks (HealthKit, SwiftData)
- Implementing advanced SwiftUI techniques
- Setting up integrations or external services

**Teaching Approach:**
- **Visual Learning**: Always provide ASCII diagrams or structured layouts for complex relationships
- **Fitness Analogies**: Use sports/fitness metaphors to explain technical concepts
  - "SwiftData = Gym database, Models = Member cards, Queries = Equipment search"
  - "HealthKit = Personal trainer data exchange, Authorization = Gym membership"
  - "Navigation = Training program flow, State = Current exercise position"
- **Reference Patterns**: Show existing code patterns in project before suggesting new approaches
- **Trade-offs Explanation**: Explain architectural decisions with pros/cons analysis
- **Turkish Explanations**: Use Turkish for conceptual teaching, English for code
- **Progressive Complexity**: Start with analogies, move to diagrams, then to code

**Project-Specific Mentoring:**
- Always explain SwiftData relationships and query patterns
- Teach HealthKit permission and data flow concepts
- Demonstrate proper localization implementation
- Show how design system components work together
- Explain fitness domain logic and calculations

### AI-Assisted Development Workflow
- **Primary Tools**: Cursor, ChatGPT, Claude for different development phases
- **Claude's Role**: Code review, architecture decisions, complex problem solving
- **Approach**: Iterative development with AI guidance and human fitness expertise validation
- **Code Quality**: Emphasize readable, maintainable code that other developers can understand

### Collaboration Style & Error Handling
- **Communication**: Türkçe for explanations, reasoning, and teaching moments
- **Error Feedback**: Direct and immediate - point out mistakes clearly and explain why they're problematic
  - Use fitness analogies: "Bu kod spor salonunda form bozukluğu gibi - çalışır ama sakatlık riski var"
  - Provide specific correction steps with reasoning
  - Explain potential consequences of the error
- **Implementation Approach**: 
  - Ask clarifying questions about requirements before implementing
  - Offer to explain implementation approaches and their benefits
  - Always provide reasoning behind architectural decisions
  - Suggest improvements when working in related code areas
- **Teaching Moments**:
  - Explain complex iOS concepts when encountered
  - Reference Apple documentation and best practices
  - Provide learning resources for advanced topics
  - Connect fitness domain knowledge with technical implementation

## Analytics Module Development Guidelines

### Working with Health Intelligence
When developing analytics features, always consider the athlete's perspective:

**Analytics Implementation Principles:**
- **Meaningful Metrics**: Focus on metrics that actually help athletes improve
- **Context-Aware Insights**: Provide insights that consider training history and goals
- **Visual Clarity**: Use charts and graphs that athletes can quickly understand
- **Actionable Recommendations**: Every insight should suggest concrete next steps

**Analytics Module Structure:**
```swift
Features/Analytics/
├── Views/                    # SwiftUI analytics dashboard components
├── ViewModels/              # Analytics data processing and state management
└── Services/                # Health intelligence algorithms and calculations
```

**Key Analytics Components:**
- **TrendAnalysisService**: Statistical analysis of performance over time
- **HealthIntelligenceService**: AI-powered insights from workout and health data
- **PerformanceMetricsService**: Advanced calculations for strength, cardio, and body composition

### Analytics Best Practices
- Always validate health data before analysis
- Use background processing for heavy statistical calculations
- Implement caching for frequently accessed analytics data
- Provide fallback displays when analytics data is insufficient

## Localization Development Guidelines

### Multi-Language Support System
The app supports **9 languages** with runtime switching capability. Always consider localization impact when adding new features.

**Localization Architecture:**
```swift
Shared/Localization/
├── LanguageManager.swift           # Runtime language switching
├── LocalizationKeys.swift          # Type-safe localization keys
├── Extensions/                     # String and View localization helpers
└── Utilities/                      # Localization validation tools
```

**Supported Languages Priority:**
1. **Turkish (tr)** - Primary market, developer's native language
2. **English (en)** - International market, secondary priority
3. **German (de)** - European expansion, tertiary priority
4. **Spanish (es)**, **Italian (it)**, **French (fr)** - European markets
5. **Portuguese (pt)** - Brazilian market
6. **Indonesian (id)**, **Polish (pl)** - Emerging markets

### Localization Best Practices
- **Always use LocalizationKeys enum** - never hardcode strings
- **Test with longest language** - German tends to be longest, ensure UI doesn't break
- **Cultural sensitivity** - fitness terminology varies significantly across cultures
- **Context-aware translations** - same English word may need different translations in different contexts
- **Use Turkish for developer communications** - maintain native language for explanations

**Example Implementation:**
```swift
// ✅ GOOD: Type-safe localization
Text(LocalizationKeys.workout_completed.localized)

// ❌ BAD: Hardcoded string
Text("Workout Completed")
```

## Testing Infrastructure Guidelines

### Model Testing Strategy
Comprehensive testing ensures data integrity across all fitness tracking features:

**Test Structure:**
```swift
Core/Models/Tests/
├── MockData.swift              # Realistic test data for all models
├── ModelTests.swift            # SwiftData model validation tests
├── TestFixtures.swift          # Standardized test scenarios
├── UserModelTests.swift        # User-specific functionality tests
└── ValidationTests.swift       # Data validation and edge case tests
```

### Testing Best Practices
- **Use realistic fitness data** - leverage developer's 12+ years athletic experience
- **Test edge cases** - what happens with incomplete workouts, missing data, etc.
- **Validate relationships** - ensure SwiftData relationships work correctly
- **Test across languages** - verify localization doesn't break functionality
- **Mock HealthKit data** - test HealthKit integration without requiring real health data

**Example Test Data:**
```swift
// Real-world inspired test data
let mockUser = User(
    age: 28,
    weight: 75.0,
    activityLevel: .highlyActive,
    fitnessGoal: .strength
)

let mockWorkout = LiftSession(
    exercises: [mockSquat, mockBench, mockDeadlift],
    duration: 4200, // 70 minutes - realistic strength training duration
    totalVolume: 8500.0 // Realistic total volume for intermediate lifter
)
```

## Legal & Compliance Guidelines

### Privacy-First Development
All health and fitness data must be handled with utmost care and transparency:

**Privacy Implementation Principles:**
- **Local-First Storage**: Default to local storage, cloud sync is optional
- **Granular Permissions**: Request only necessary permissions with clear explanations
- **Data Transparency**: Users should always know what data is collected and why
- **Export Capability**: Users must be able to export their complete data set
- **Deletion Rights**: Complete data removal must be possible at any time

**Legal Documentation Structure:**
```
Resources/Legal/
├── PrivacyPolicy.md            # GDPR/CCPA compliant privacy policy
├── TermsOfService.md          # Clear terms of service
├── DataUsagePolicy.md         # Specific health data usage policies
└── ComplianceChecklist.md     # Verification checklist for legal compliance
```

### Legal Best Practices
- **Clear, Simple Language**: Legal documents should be readable by average users
- **Specific Purpose Declaration**: Clearly state why each type of data is collected
- **Retention Policies**: Define how long data is stored and when it's deleted
- **Third-Party Disclosures**: Clearly list any third-party integrations (HealthKit, OpenFoodFacts, etc.)
- **Update Notifications**: Users must be notified of policy changes

### HealthKit Compliance
- Always request minimal necessary permissions
- Provide clear explanations for each HealthKit permission request
- Implement proper error handling for denied permissions
- Never store HealthKit data in backup systems without explicit consent
- Follow Apple's HealthKit Review Guidelines exactly

## Performance Optimization Guidelines

### Athletics-Informed Performance
Understanding athletic training patterns helps optimize app performance:

**Training Session Patterns:**
- **Strength Training**: 45-90 minutes, high data write frequency during sets
- **Cardio Sessions**: 20-120 minutes, continuous data streaming
- **WOD Tracking**: 10-30 minutes, intense burst data recording

**Performance Optimization Strategies:**
- **Background Processing**: Heavy analytics calculations during off-peak usage
- **Intelligent Caching**: Cache frequently accessed workout templates and programs
- **Batch Operations**: Group database writes during active workout sessions
- **Progressive Loading**: Load workout history progressively as user scrolls

### SwiftData Performance Best Practices
- Use descriptors for efficient querying large workout datasets
- Implement proper relationships to minimize data duplication
- Use background contexts for heavy data processing
- Optimize for typical athlete usage patterns (viewing recent workouts most frequently)

This comprehensive guidance ensures that development maintains both technical excellence and authentic fitness expertise throughout the codebase.

