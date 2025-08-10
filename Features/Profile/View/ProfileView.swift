import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    
    @State private var showingPersonalInfoSheet = false
    @State private var showingPreferencesSheet = false
    @State private var showingAccountSheet = false
    @State private var showingWeightEntry = false
    @State private var showingMeasurementsEntry = false
    @State private var showingProgressPhotos = false
    
    private var currentUser: User? {
        users.first
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // User Header Card
                    UserHeaderCard(user: currentUser)
                    
                    // Quick Stats Section
                    QuickStatsSection(user: currentUser)
                    
                    // Settings Sections
                    VStack(spacing: 16) {
                        PersonalSettingsSection(
                            showingPersonalInfo: $showingPersonalInfoSheet,
                            showingAccount: $showingAccountSheet
                        )
                        
                        BodyTrackingSection(
                            showingWeightEntry: $showingWeightEntry,
                            showingMeasurements: $showingMeasurementsEntry,
                            showingPhotos: $showingProgressPhotos
                        )
                        
                        FitnessCalculatorsSection()
                        
                        AppPreferencesSection(
                            showingPreferences: $showingPreferencesSheet
                        )
                        
                        ProgressAnalyticsSection()
                    }
                }
                .padding()
            }
            .navigationTitle("Profil")
            .background(Color(.systemGroupedBackground))
        }
        .sheet(isPresented: $showingPersonalInfoSheet) {
            if let user = currentUser {
                PersonalInfoEditView(user: user)
            }
        }
        .sheet(isPresented: $showingPreferencesSheet) {
            AppPreferencesView()
        }
        .sheet(isPresented: $showingAccountSheet) {
            if let user = currentUser {
                AccountManagementView(user: user)
            }
        }
        .sheet(isPresented: $showingWeightEntry) {
            if let user = currentUser {
                WeightEntryView(user: user)
            }
        }
        .sheet(isPresented: $showingMeasurementsEntry) {
            if let user = currentUser {
                BodyMeasurementsView(user: user)
            }
        }
        .sheet(isPresented: $showingProgressPhotos) {
            ProgressPhotosView()
        }
    }
}

// MARK: - User Header Card
struct UserHeaderCard: View {
    let user: User?
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile Photo Placeholder
            Circle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [.blue, .purple]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 80, height: 80)
                .overlay(
                    Text(user?.name.prefix(1).uppercased() ?? "U")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user?.name ?? "Kullanıcı")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let user = user {
                    Text("\(user.age) yaş • \(Int(user.height)) cm • \(Int(user.currentWeight)) kg")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(user.fitnessGoalEnum.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Quick Stats Section (FIXED)
struct QuickStatsSection: View {
    let user: User?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Günlük Hedefler")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickStatCard(
                    icon: "flame.fill",
                    title: "Kalori",
                    value: "\(Int(user?.dailyCalorieGoal ?? 0))",
                    subtitle: "kcal",
                    color: .orange
                )
                
                QuickStatCard(
                    icon: "fish.fill",
                    title: "Protein",
                    value: "\(Int(user?.dailyProteinGoal ?? 0))",
                    subtitle: "g",
                    color: .red
                )
                
                QuickStatCard(
                    icon: "heart.fill",
                    title: "BMR",
                    value: "\(Int(user?.bmr ?? 0))",
                    subtitle: "kcal",
                    color: .green
                )
                
                QuickStatCard(
                    icon: "bolt.fill",
                    title: "TDEE",
                    value: "\(Int(user?.tdee ?? 0))",
                    subtitle: "kcal",
                    color: .blue
                )
            }
        }
    }
}

// MARK: - Settings Sections
struct PersonalSettingsSection: View {
    @Binding var showingPersonalInfo: Bool
    @Binding var showingAccount: Bool
    
    var body: some View {
        SettingsSection(title: "Kişisel Bilgiler") {
            SettingsRow(
                icon: "person.fill",
                title: "Kişisel Bilgiler",
                subtitle: "Boy, kilo, yaş, hedef",
                action: { showingPersonalInfo = true }
            )
            
            SettingsRow(
                icon: "person.badge.key.fill",
                title: "Hesap Yönetimi",
                subtitle: "Veri yedekleme, gizlilik",
                action: { showingAccount = true }
            )
        }
    }
}

struct BodyTrackingSection: View {
    @Binding var showingWeightEntry: Bool
    @Binding var showingMeasurements: Bool
    @Binding var showingPhotos: Bool
    
    var body: some View {
        SettingsSection(title: "Vücut Takibi") {
            SettingsRow(
                icon: "scalemass.fill",
                title: "Kilo Takibi",
                subtitle: "Kilo geçmişi ve grafikler",
                action: { showingWeightEntry = true }
            )
            
            SettingsRow(
                icon: "ruler.fill",
                title: "Vücut Ölçüleri",
                subtitle: "Göğüs, bel, kol ölçüleri",
                action: { showingMeasurements = true }
            )
            
            SettingsRow(
                icon: "camera.fill",
                title: "İlerleme Fotoğrafları",
                subtitle: "Görsel ilerleme takibi",
                action: { showingPhotos = true }
            )
        }
    }
}

struct FitnessCalculatorsSection: View {
    var body: some View {
        SettingsSection(title: "Fitness Hesaplayıcıları") {
            NavigationLink(destination: FitnessCalculatorsView()) {
                SettingsRowContent(
                    icon: "function",
                    title: "Hesaplayıcılar",
                    subtitle: "1RM, FFMI, Navy Method"
                )
            }
        }
    }
}

struct AppPreferencesSection: View {
    @Binding var showingPreferences: Bool
    
    var body: some View {
        SettingsSection(title: "Uygulama Ayarları") {
            SettingsRow(
                icon: "gear",
                title: "Tercihler",
                subtitle: "Dil, birimler, bildirimler",
                action: { showingPreferences = true }
            )
        }
    }
}

struct ProgressAnalyticsSection: View {
    var body: some View {
        SettingsSection(title: "İlerleme ve Analitik") {
            NavigationLink(destination: ProgressChartsView()) {
                SettingsRowContent(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "İlerleme Grafikleri",
                    subtitle: "Kilo, ölçüler, performans"
                )
            }
            
            NavigationLink(destination: AchievementsView()) {
                SettingsRowContent(
                    icon: "trophy.fill",
                    title: "Başarımlar",
                    subtitle: "Rozetler ve hedefler"
                )
            }
            
            NavigationLink(destination: GoalTrackingView()) {
                SettingsRowContent(
                    icon: "target",
                    title: "Hedef Takibi",
                    subtitle: "Kişisel hedefler"
                )
            }
        }
    }
}

// MARK: - Reusable Components
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)
            
            VStack(spacing: 1) {
                content
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            SettingsRowContent(icon: icon, title: title, subtitle: subtitle)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsRowContent: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    ProfileView()
}
