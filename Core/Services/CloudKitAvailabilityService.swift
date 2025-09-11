import CloudKit
import SwiftUI

/**
 * CloudKit availability detection and status management
 * 
 * This service detects if CloudKit is available for the current user
 * and manages the optional sync functionality.
 */
@MainActor
@Observable
class CloudKitAvailabilityService {
    
    static let shared = CloudKitAvailabilityService()
    
    var isAvailable: Bool = false
    var accountStatus: CKAccountStatus = .couldNotDetermine
    var error: Error?
    
    private let container = CKContainer(identifier: "iCloud.burakkho.thrustr")
    
    private init() {
        Task {
            await checkAvailability()
        }
    }
    
    // MARK: - Public Methods
    
    /**
     * Checks CloudKit availability and updates observable properties
     */
    func checkAvailability() async {
        do {
            let status = try await container.accountStatus()
            
            await MainActor.run {
                self.accountStatus = status
                self.isAvailable = (status == .available)
                self.error = nil
            }
            
            logStatus(status)
            
        } catch {
            await MainActor.run {
                self.accountStatus = .couldNotDetermine
                self.isAvailable = false
                self.error = error
            }
            
            print("❌ CloudKit availability check failed: \(error)")
        }
    }
    
    /**
     * Manual refresh of CloudKit availability
     */
    func refreshAvailability() async {
        await checkAvailability()
    }
    
    // MARK: - Private Methods
    
    private func logStatus(_ status: CKAccountStatus) {
        switch status {
        case .available:
            print("☁️ CloudKit available - sync enabled")
        case .noAccount:
            print("📱 No iCloud account - local storage only")
        case .restricted:
            print("🔒 CloudKit restricted - local storage only")
        case .couldNotDetermine:
            print("❓ CloudKit status unknown - local storage only")
        case .temporarilyUnavailable:
            print("⏸️ CloudKit temporarily unavailable - local storage only")
        @unknown default:
            print("❓ Unknown CloudKit status - local storage only")
        }
    }
    
    // MARK: - User Friendly Status
    
    var statusMessage: String {
        switch accountStatus {
        case .available:
            return "iCloud sync available"
        case .noAccount:
            return "No iCloud account"
        case .restricted:
            return "iCloud access restricted"
        case .couldNotDetermine:
            return "iCloud status unknown"
        case .temporarilyUnavailable:
            return "iCloud temporarily unavailable"
        @unknown default:
            return "iCloud unavailable"
        }
    }
    
    var statusIcon: String {
        switch accountStatus {
        case .available:
            return "checkmark.icloud"
        case .noAccount:
            return "person.crop.circle.badge.xmark"
        case .restricted:
            return "lock.icloud"
        case .couldNotDetermine:
            return "questionmark.icloud"
        case .temporarilyUnavailable:
            return "exclamationmark.icloud"
        @unknown default:
            return "xmark.icloud"
        }
    }
}