# Thrustr - Comprehensive Fitness Tracking App

<div align="center">
  <img src="https://img.shields.io/badge/iOS-17.0+-blue" alt="iOS Version">
  <img src="https://img.shields.io/badge/Swift-5.9-orange" alt="Swift Version">
  <img src="https://img.shields.io/badge/SwiftUI-5.0-green" alt="SwiftUI Version">
  <img src="https://img.shields.io/badge/SwiftData-1.0-purple" alt="SwiftData Version">
</div>

## 📱 Overview

Thrustr is a comprehensive iOS fitness tracking application built with SwiftUI and SwiftData. It provides multi-modal workout tracking, nutrition monitoring, and comprehensive analytics for fitness enthusiasts of all levels.

### 🌟 Key Features

- **Multi-Modal Training**: Strength training, cardio workouts, and CrossFit-style WODs
- **Advanced Analytics**: Comprehensive performance tracking, trend analysis, and AI-powered insights
- **Nutrition Tracking**: Barcode scanning, meal logging, and macro tracking with OpenFoodFacts integration
- **HealthKit Integration**: Seamless sync with Apple Health for steps, calories, and weight
- **Multi-Language Support**: Complete localization in 9 languages (Turkish, English, German, Spanish, Italian, French, Portuguese, Indonesian, Polish) with 3 more planned
- **Smart Analytics**: Progress tracking, PR monitoring, performance insights, and health intelligence
- **Comprehensive Tools**: Body fat calculators, 1RM calculators, fitness assessments, and legal compliance
- **Privacy-First Design**: Local data storage with optional cloud sync and comprehensive legal documentation

## 🏗️ Architecture

### Tech Stack
- **iOS 17.0+** minimum deployment target
- **SwiftUI** for modern declarative UI
- **SwiftData** for local data persistence
- **HealthKit** for health data integration
- **CoreBluetooth** for fitness device connectivity
- **CoreLocation** for GPS tracking during outdoor activities

### Project Structure
```
thrustr/
├── App/                    # App entry point and main views
├── Core/                   # Core models and services
│   ├── Models/            # SwiftData models
│   │   ├── Cardio/        # Cardio tracking models
│   │   ├── Lift/          # Strength training models
│   │   ├── WOD/           # Workout of the Day models
│   │   ├── Extensions/    # Model extensions and utilities
│   │   └── Tests/         # Model test files
│   ├── Services/          # Business logic services
│   └── Validation/        # Data validation utilities
├── Features/              # Feature modules
│   ├── Analytics/         # Performance tracking and insights
│   ├── Dashboard/         # Main dashboard with health stats
│   ├── Nutrition/         # Food tracking and meal logging
│   ├── Profile/           # User profile and settings
│   └── Training/          # Multi-modal workout tracking
├── Shared/                # Shared utilities and components
│   ├── Components/        # Reusable UI components
│   ├── DesignSystem/      # Theme and design tokens
│   ├── Calculators/       # Fitness calculation utilities
│   ├── Enums/             # Shared enumeration types
│   ├── Localization/      # Multi-language support system
│   └── Utilities/         # Helper classes and extensions
└── Resources/             # CSV data, localizations, assets
    ├── Legal/             # Privacy policy and legal documents
    ├── Training/          # Exercise and program data
    └── *.lproj/           # 9 language localization files
```

## 🚀 Getting Started

### Prerequisites
- **Xcode 15.0+**
- **iOS 17.0+** device or simulator
- **macOS 13.0+** (for development)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/thrustr.git
cd thrustr
```

2. **Open in Xcode**
```bash
open thrustr.xcodeproj
```

3. **Build and Run**
   - Select your target device/simulator
   - Press `Cmd + R` or click the Play button
   - The app will automatically seed the database on first launch

### Build Commands

```bash
# Build the project
xcodebuild -project thrustr.xcodeproj -scheme thrustr build

# Run tests
xcodebuild test -project thrustr.xcodeproj -scheme thrustr -destination 'platform=iOS Simulator,name=iPhone 16'

# Clean build folder
# Use Product → Clean Build Folder in Xcode
```

## 💾 Data Management

### Database Seeding
The app automatically seeds the database on first launch with:
- **Exercises**: 500+ exercises from CSV files
- **Foods**: Comprehensive nutrition database with multi-language aliases
- **Programs**: Pre-built workout programs (StrongLifts 5x5, etc.)
- **Movements**: CrossFit movement library
- **Benchmark WODs**: Standard CrossFit benchmark workouts

### HealthKit Permissions
The app requests the following HealthKit permissions:
- Steps (read)
- Active Energy Burned (read)
- Body Weight (read/write)

## 🌍 Localization

### Currently Supported Languages (9):
- **Turkish** (tr) - Primary language 🇹🇷
- **English** (en) - Base localization 🇺🇸
- **German** (de) - Completed 🇩🇪
- **Spanish** (es) - Completed 🇪🇸  
- **Italian** (it) - Completed 🇮🇹
- **French** (fr) - Completed 🇫🇷
- **Portuguese** (pt) - Completed 🇵🇹
- **Indonesian** (id) - Completed 🇮🇩
- **Polish** (pl) - Completed 🇵🇱

### Planned Languages (Roadmap):
- **Dutch** (nl) - Sprint 5 🇳🇱
- **Swedish** (sv) - Sprint 6 🇸🇪
- **Norwegian** (no) - Sprint 7 🇳🇴

### Translation Coverage:
- **2,946 localization keys** per language
- **Fitness-specific terminology** with authentic translations
- **Complete app coverage** including onboarding, training, nutrition, and analytics
- **Quality assurance** with systematic chunk-based translation methodology

### Language Features:
- **Runtime language switching** without app restart
- **Automatic language detection** based on device settings
- **Fallback system** to English for missing translations
- **Cultural adaptation** of fitness terms and measurements

## 📈 Development Progress

### Localization Sprint Status:
- **Sprint 1 (Italian)**: ✅ Completed - 2,946 keys translated
- **Sprint 2 (French)**: ✅ Completed - 2,946 keys translated  
- **Sprint 3 (Portuguese)**: ✅ Completed - 2,946 keys translated
- **Sprint 4 (Indonesian)**: ✅ Completed - 2,946 keys translated
- **Sprint 5 (Polish)**: ✅ Completed - 2,946 keys translated
- **Sprint 6 (Dutch)**: 🎯 Next - Planning phase
- **Sprint 7 (Swedish)**: ⏳ Planned - Future sprint
- **Sprint 8 (Norwegian)**: ⏳ Planned - Future sprint

### Target: 12 Total Languages
**Current**: 9 languages | **Goal**: 12 languages | **Progress**: 75% complete

The app is designed to serve a global fitness community with authentic, culturally-adapted fitness terminology in each supported language.

## 🎨 Design System

### Theme Support
- Light and dark theme support
- Protocol-based theming for easy customization
- Consistent design tokens for spacing, colors, and typography
- Reusable components with `.cardStyle()` modifiers

### Key Components
- `EmptyStateView` - Standardized empty states
- `ToastView` - Non-intrusive notifications
- `QuickStatCard` - Metric display cards
- `HealthStatStrip` - Health metrics display
- `LoadingView` - Consistent loading states

## 📊 Models & Data

### Core Models
- **User**: Central user profile with health metrics and goals
- **Exercise**: Comprehensive exercise database with categories
- **Food**: Nutrition database with macros and aliases
- **Workout Systems**: Separate model hierarchies for Cardio, Lift, and WOD

### Key Features
- **Unit System**: Metric/Imperial support with automatic conversion
- **Data Relationships**: Complex relationships between workouts, exercises, and results
- **Performance Tracking**: PR tracking, streak monitoring, and analytics

## 🔧 Development

### Code Style
- Follow existing conventions and patterns
- Use enum computed properties instead of raw strings
- Apply consistent error handling with `DatabaseError` and `Logger`
- Leverage the design system for UI consistency

### Testing
Test files are located in `ThrustrTests/`. Run tests using:
- Xcode Test Navigator
- Command line: `xcodebuild test`

### Contributing
1. Fork the repository
2. Create a feature branch
3. Follow existing code patterns and architecture
4. Add tests for new functionality
5. Submit a pull request

## 📱 Screenshots

*Coming soon - Add screenshots of key app features*

## 📄 License

*Add your license information here*

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests for any improvements.

## 📞 Support

For questions or issues, please open an issue on GitHub or contact the development team.

---

Built with ❤️ using SwiftUI and SwiftData