# CloudKit Integration Guidelines

## CloudKit Architecture
The app uses a sophisticated dual-configuration approach for local and cloud storage:

**CloudKit Configuration:**
```swift
// Dual Configuration Setup
let localConfig = ModelConfiguration("Local")
let cloudConfig = ModelConfiguration(
    "Cloud",
    cloudKitDatabase: .private("iCloud.burakkho.thrustr")
)
```

**Key CloudKit Services:**
- **CloudSyncManager**: Manages sync operations and conflict resolution
- **CloudKitAvailabilityService**: Checks iCloud availability and manages fallbacks
- **Automatic Sync**: Background sync when app becomes active
- **Conflict Resolution**: Intelligent merge strategies for user data

## CloudKit Best Practices
- **Graceful Fallbacks**: App functions fully without iCloud
- **Data Privacy**: All health data remains in user's private CloudKit container
- **Sync Efficiency**: Only sync changed data, not full datasets
- **Error Handling**: Comprehensive error handling for network issues
- **User Control**: Clear indication of sync status and user control over cloud features

## CloudKit Data Flow
1. **Local First**: All operations work on local SwiftData store
2. **Background Sync**: CloudKit sync happens in background
3. **Conflict Resolution**: Last-write-wins with user notification for conflicts
4. **Availability Check**: Automatic fallback to local-only when iCloud unavailable

## Implementation Details

### Model Configuration
```swift
private static func createModelContainer() throws -> ModelContainer {
    let cloudAvailability = CloudKitAvailabilityService.shared

    if cloudAvailability.isAvailable {
        // CloudKit + Local Dual Configuration
        let localConfig = ModelConfiguration("Local")
        let cloudConfig = ModelConfiguration(
            "Cloud",
            cloudKitDatabase: .private("iCloud.burakkho.thrustr")
        )
        return try ModelContainer(
            for: schema,
            configurations: [localConfig, cloudConfig]
        )
    } else {
        // Local-only fallback
        let localConfig = ModelConfiguration("Local")
        return try ModelContainer(
            for: schema,
            configurations: [localConfig]
        )
    }
}
```

### Sync Management
- **CloudSyncManager**: Handles all sync operations
- **Conflict Resolution**: Automatic resolution with user notification
- **Batch Operations**: Efficient syncing of large datasets
- **Network Monitoring**: Automatic sync when network available

## Error Handling
- **Network Errors**: Graceful handling of connectivity issues
- **Quota Exceeded**: User notification and cleanup strategies
- **Authentication**: Seamless re-authentication flow
- **Data Corruption**: Recovery and repair mechanisms

## Privacy & Security
- **Private Container**: All data in user's private iCloud space
- **Encryption**: Data encrypted in transit and at rest
- **User Consent**: Clear permission requests
- **Data Minimization**: Only sync necessary data

## Testing CloudKit
- **Development Environment**: Use CloudKit Dashboard for testing
- **Simulator Testing**: Test sync scenarios in simulator
- **Account Testing**: Test with different iCloud account states
- **Network Testing**: Test various network conditions
- **Error Simulation**: Simulate CloudKit errors for robustness