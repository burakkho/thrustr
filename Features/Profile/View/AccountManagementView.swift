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
                    Text("Hesap Bilgileri")
                }
                
                // Data Management Section
                Section {
                    DataManagementSection()
                } header: {
                    Text("Veri Yönetimi")
                }
                
                // Dangerous Actions Section
                Section {
                    DangerousActionsSection(
                        showingReset: $showingResetAlert,
                        showingDelete: $showingDeleteAlert
                    )
                } header: {
                    Text("Tehlikeli İşlemler")
                } footer: {
                    Text("Bu işlemler geri alınamaz.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Hesap Yönetimi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Tamam") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .alert("Verileri Sıfırla", isPresented: $showingResetAlert) {
            Button("Sıfırla", role: .destructive) {
                resetData()
            }
            Button("İptal", role: .cancel) { }
        } message: {
            Text("Bu işlem tüm verilerinizi silecektir.")
        }
        .alert("Hesabı Sil", isPresented: $showingDeleteAlert) {
            Button("Sil", role: .destructive) {
                deleteAccount()
            }
            Button("İptal", role: .cancel) { }
        } message: {
            Text("Bu işlem hesabınızı kalıcı olarak silecektir.")
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
                    Text(user?.name ?? "Kullanıcı")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Yerel Hesap")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            VStack(spacing: 8) {
                AccountInfoRow(
                    title: "Kayıt Tarihi",
                    value: formatDate(user?.createdAt ?? Date())
                )
                
                AccountInfoRow(
                    title: "Güncel Kilo",
                    value: String(format: "%.1f kg", user?.currentWeight ?? 0)
                )
                
                AccountInfoRow(
                    title: "Hedef",
                    value: user?.fitnessGoal ?? "Bilinmiyor"
                )
                
                AccountInfoRow(
                    title: "Aktivite",
                    value: user?.activityLevel ?? "Bilinmiyor"
                )
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "tr")
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
                        Text("Verileri Yedekle")
                            .foregroundColor(.primary)
                            .fontWeight(.medium)
                        
                        Text("Tüm verilerinizi dışa aktarın")
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
                    Text("Uygulama Bilgileri")
                        .foregroundColor(.primary)
                        .fontWeight(.medium)
                    
                    Text("Versiyon 1.0 - Beta")
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
                        Text("Tüm Verileri Sıfırla")
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                        
                        Text("Antrenman ve beslenme verilerini sil")
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
                        Text("Hesabı Sil")
                            .foregroundColor(.red)
                            .fontWeight(.medium)
                        
                        Text("Hesabı ve tüm verileri kalıcı olarak sil")
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
