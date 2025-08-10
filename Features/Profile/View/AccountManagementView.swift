import SwiftUI
import SwiftData

struct AccountManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let user: User?
    
    @State private var showingDeleteAlert = false
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationView {
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
                        showingDelete: $showingDeleteAlert
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
        .alert("account.reset_data".localized, isPresented: $showingResetAlert) {
            Button("account.reset_data".localized, role: .destructive) {
                resetData()
            }
            Button("common.cancel".localized, role: .cancel) { }
        } message: {
            Text("account.reset_desc".localized)
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
    
    private func resetData() {
        print("Data reset requested")
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
    @Binding var showingDelete: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Button {
                showingReset = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("account.reset_data".localized)
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                        
                        Text("account.reset_desc".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            
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
