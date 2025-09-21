# Apple Watch Development Guidelines

## Watch App Architecture
The app includes a native Apple Watch application with shared components:

**Watch App Structure:**
```swift
WatchShared/
└── ViewModels/               # Watch-specific view models

"thrustr Watch App"/          # Native watchOS application
├── Views/                    # Watch UI components
├── Assets.xcassets/         # Watch-specific assets
└── thrustr-Watch-App-Info.plist
```

**Key Watch Components:**
- **WatchWorkoutViewModel**: Workout tracking optimized for Apple Watch
- **EnhancedWatchConnectivityManager**: iPhone-Watch communication and data sync
- **WatchConnectivityManager**: Legacy Watch connectivity (being phased out)

## Watch Development Best Practices
- **Battery Optimization**: Minimize background processing on Watch
- **Simplified UI**: Design for small screen and quick interactions
- **Health Data Sync**: Leverage HealthKit for seamless data sharing
- **Offline Capability**: Ensure core workout tracking works without iPhone
- **Quick Actions**: Optimize for workout start/stop functionality

## Watch-iPhone Communication
- Use **WatchConnectivity framework** for real-time data sync
- **Background transfers** for large data sets
- **UserInfo transfers** for immediate updates
- **File transfers** for workout data and media

## Watch UI Guidelines
- **Digital Crown**: Use for scrolling through workout sets/reps
- **Side Button**: Quick access to workout controls
- **Force Touch**: Context menus for workout options
- **Complications**: Display current workout status
- **Notifications**: Workout reminders and achievements

## Workout Tracking on Watch
- **Independent Operation**: Watch can track workouts without iPhone
- **Automatic Sync**: Data syncs when devices reconnect
- **HealthKit Integration**: Seamless health data sharing
- **Timer Management**: Background timer support for long workouts
- **Heart Rate Monitoring**: Continuous HR tracking during workouts

## Performance Optimization
- **Lazy Loading**: Load only visible workout data
- **Background App Refresh**: Smart background updates
- **Memory Management**: Efficient handling of workout history
- **Network Optimization**: Minimize data transfer between devices
- **Battery Monitoring**: Adjust features based on battery level

## Testing Strategy
- **Device Testing**: Test on actual Apple Watch hardware
- **Simulator Testing**: Use Watch Simulator for UI testing
- **Battery Testing**: Monitor battery drain during workouts
- **Connectivity Testing**: Test various connection scenarios
- **HealthKit Testing**: Verify health data permissions and sync