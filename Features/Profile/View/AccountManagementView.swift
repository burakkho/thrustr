import SwiftUI
import SwiftData

struct AccountManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(CloudSyncManager.self) private var cloudSyncManager
    @Environment(CloudKitAvailabilityService.self) private var cloudAvailability
    
    let user: User?
    
    @State private var showingDeleteAlert = false
    @State private var showingResetAlert = false
    @State private var showingResetConfirmation = false
    @State private var isResetting = false
    @State private var showingResetSuccess = false
    @State private var showingResetError = false
    @State private var resetErrorMessage = ""
    
    var body: some View {
        NavigationStack {
            List {
                // Account Info Section
                Section {
                    AccountInfoSection(user: user)
                } header: {
                    Text("account.info".localized)
                }
                
                // Data Management Section
                Section {
                    DataManagementSection()
                } header: {
                    Text("account.data_management".localized)
                }
                
                // Dangerous Actions Section
                Section {
                    DangerousActionsSection(
                        showingReset: $showingResetAlert,
                        showingResetConfirmation: $showingResetConfirmation,
                        showingDelete: $showingDeleteAlert,
                        isResetting: isResetting,
                        cloudAvailable: cloudAvailability.isAvailable
                    )
                } header: {
                    Text("account.dangerous_actions".localized)
                } footer: {
                    Text("account.cannot_undo".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("account.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.done".localized) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .alert("⚠️ iCloud Data Warning", isPresented: $showingResetAlert) {
            Button("I Understand", role: .destructive) {
                showingResetConfirmation = true
            }
            Button("common.cancel".localized, role: .cancel) { }
        } message: {
            Text("This will delete data from iCloud and all your other devices. This action cannot be undone and will affect all devices signed in to your iCloud account.")
        }
        .alert("account.reset_data".localized, isPresented: $showingResetConfirmation) {
            Button("account.reset_data".localized, role: .destructive) {
                Task {
                    await resetData()
                }
            }
            Button("common.cancel".localized, role: .cancel) { }
        } message: {
            Text(cloudAvailability.isAvailable 
                ? "Final confirmation: All workout and nutrition data will be permanently deleted from this device and iCloud."
                : "account.reset_desc".localized)
        }
        .alert("Success", isPresented: $showingResetSuccess) {
            Button("common.ok".localized) { }
        } message: {
            Text(cloudAvailability.isAvailable 
                ? "All workout and nutrition data has been reset successfully on this device and iCloud. Changes will sync to your other devices."
                : "All workout and nutrition data has been reset successfully.")
        }
        .alert("Reset Status", isPresented: $showingResetError) {
            Button("common.ok".localized) { }
        } message: {
            Text(resetErrorMessage.isEmpty 
                ? "An error occurred while resetting data. Please try again."
                : resetErrorMessage)
        }
        .alert("account.delete_account".localized, isPresented: $showingDeleteAlert) {
            Button("common.delete".localized, role: .destructive) {
                deleteAccount()
            }
            Button("common.cancel".localized, role: .cancel) { }
        } message: {
            Text("account.delete_desc".localized)
        }
    }
    
    @MainActor
    private func resetData() async {
        isResetting = true
        
        do {
            // Delete all workout and nutrition data while preserving user profile
            // Since ModelContext is MainActor-isolated, we need to perform deletions sequentially
            
            // Delete Lift Results
            let liftResults = try modelContext.fetch(FetchDescriptor<LiftExerciseResult>())
            for result in liftResults {
                modelContext.delete(result)
            }
            
            // Delete Cardio Results
            let cardioResults = try modelContext.fetch(FetchDescriptor<CardioResult>())
            for result in cardioResults {
                modelContext.delete(result)
            }
            
            // Delete Nutrition Entries
            let nutritionEntries = try modelContext.fetch(FetchDescriptor<NutritionEntry>())
            for entry in nutritionEntries {
                modelContext.delete(entry)
            }
            
            // Delete Lift Sessions
            let liftSessions = try modelContext.fetch(FetchDescriptor<LiftSession>())
            for session in liftSessions {
                modelContext.delete(session)
            }
            
            // Delete Cardio Sessions
            let cardioSessions = try modelContext.fetch(FetchDescriptor<CardioSession>())
            for session in cardioSessions {
                modelContext.delete(session)
            }
            
            // Delete WOD Results
            let wodResults = try modelContext.fetch(FetchDescriptor<WODResult>())
            for result in wodResults {
                modelContext.delete(result)
            }
            
            // Delete Strength Test Results
            let testResults = try modelContext.fetch(FetchDescriptor<StrengthTestResult>())
            for result in testResults {
                modelContext.delete(result)
            }
            
            // Save changes
            try modelContext.save()
            
            // Trigger CloudKit sync if available
            if cloudAvailability.isAvailable {
                print("🔄 Triggering CloudKit sync after data reset")
                await cloudSyncManager.sync()
                
                // Check for sync errors
                if cloudSyncManager.syncStatus == .failed,
                   let syncError = cloudSyncManager.error {
                    isResetting = false
                    resetErrorMessage = "Data reset completed locally, but iCloud sync failed: \(syncError.localizedDescription). Data will sync when connection improves."
                    showingResetError = true
                    return
                }
            }
            
            // Show success
            isResetting = false
            showingResetSuccess = true
            
        } catch {
            // Handle error
            isResetting = false
            resetErrorMessage = "Failed to reset data: \(error.localizedDescription)"
            showingResetError = true
        }
    }
    
    private func deleteAccount() {
        print("Account deletion requested")
    }
}

// MARK: - Account Info Section
struct AccountInfoSection: View {
    let user: User?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(user?.name ?? "common.user".localized)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("account.local_account".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            VStack(spacing: 8) {
                AccountInfoRow(
                    title: "account.registration_date".localized,
                    value: formatDate(user?.createdAt ?? Date())
                )
                
                AccountInfoRow(
                    title: "account.current_weight".localized,
                    value: String(format: "%.1f kg", user?.currentWeight ?? 0)
                )
                
                AccountInfoRow(
                    title: "account.goal".localized,
                    value: user?.fitnessGoalEnum.displayName ?? "analytics.no_data".localized
                )
                
                AccountInfoRow(
                    title: "account.activity".localized,
                    value: user?.activityLevelEnum.displayName ?? "analytics.no_data".localized
                )
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        // Use current language setting
        let savedLanguage = UserDefaults.standard.string(forKey: "app_language") ?? "system"
        if savedLanguage == "tr" {
            formatter.locale = Locale(identifier: "tr_TR")
        } else if savedLanguage == "en" {
            formatter.locale = Locale(identifier: "en_US")
        }
        
        return formatter.string(from: date)
    }
}

struct AccountInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Data Management Section
struct DataManagementSection: View {
    var body: some View {
        VStack(spacing: 0) {
            Button {
                // Export data
                print("Export data requested")
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("account.backup_data".localized)
                            .foregroundColor(.primary)
                            .fontWeight(.medium)
                        
                        Text("account.export_desc".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
                .padding(.vertical, 8)
            
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("account.app_info".localized)
                        .foregroundColor(.primary)
                        .fontWeight(.medium)
                    
                    Text("account.version".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Dangerous Actions Section
struct DangerousActionsSection: View {
    @Binding var showingReset: Bool
    @Binding var showingResetConfirmation: Bool
    @Binding var showingDelete: Bool
    let isResetting: Bool
    let cloudAvailable: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Button {
                if cloudAvailable {
                    showingReset = true  // İlk uyarı (iCloud ile ilgili)
                } else {
                    showingResetConfirmation = true  // Direkt onay (sadece local)
                }
            } label: {
                HStack {
                    if isResetting {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 24)
                    } else {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.orange)
                            .frame(width: 24)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isResetting ? "Processing..." : "account.reset_data".localized)
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                        
                        Text("account.reset_desc".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            .disabled(isResetting)
            
            Divider()
                .padding(.vertical, 8)
            
            Button {
                showingDelete = true
            } label: {
                HStack {
                    Image(systemName: "person.fill.xmark")
                        .foregroundColor(.red)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("account.delete_account".localized)
                            .foregroundColor(.red)
                            .fontWeight(.medium)
                        
                        Text("account.delete_desc".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    AccountManagementView(user: nil)
}
