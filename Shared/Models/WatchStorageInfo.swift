import Foundation

// MARK: - Watch Storage Info
struct WatchStorageInfo: Sendable {
    let workoutCount: Int
    let storageSize: Int64 // bytes
    let lastSync: Date?

    init(workoutCount: Int, storageSize: Int64, lastSync: Date? = nil) {
        self.workoutCount = workoutCount
        self.storageSize = storageSize
        self.lastSync = lastSync
    }

    // MARK: - Formatted Properties
    var formattedStorageSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: storageSize)
    }

    var formattedLastSync: String {
        guard let lastSync = lastSync else { return "Never" }

        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: lastSync, relativeTo: Date())
    }
}