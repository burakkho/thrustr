import SwiftUI
import SwiftData

struct CardioQuickStartView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Query private var user: [User]
    
    @State private var selectedActivity: CardioTimerViewModel.CardioActivityType = .running
    @State private var isOutdoor = true
    @State private var showingPreparation = false
    
    private var currentUser: User? {
        user.first
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.xl) {
                    // Header
                    VStack(spacing: theme.spacing.s) {
                        Image(systemName: "figure.run.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(theme.colors.accent)
                            .symbolRenderingMode(.hierarchical)
                        
                        Text("Hızlı Başlat")
                            .font(theme.typography.title2)
                            .fontWeight(.bold)
                            .foregroundColor(theme.colors.textPrimary)
                        
                        Text("Aktivite türünü seç ve başla")
                            .font(theme.typography.body)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    .padding(.top, theme.spacing.l)
                    
                    // Activity Selection
                    VStack(alignment: .leading, spacing: theme.spacing.m) {
                        Text("Aktivite Türü")
                            .font(theme.typography.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.colors.textPrimary)
                            .padding(.horizontal)
                        
                        VStack(spacing: theme.spacing.m) {
                            ForEach(CardioTimerViewModel.CardioActivityType.allCases, id: \.self) { activity in
                                ActivityCard(
                                    activity: activity,
                                    isSelected: selectedActivity == activity,
                                    action: { selectedActivity = activity }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Indoor/Outdoor Toggle
                    VStack(alignment: .leading, spacing: theme.spacing.m) {
                        Text("Konum")
                            .font(theme.typography.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.colors.textPrimary)
                            .padding(.horizontal)
                        
                        HStack(spacing: theme.spacing.m) {
                            LocationCard(
                                title: "Dış Mekan",
                                icon: "sun.max.fill",
                                description: "GPS ile rota takibi",
                                isSelected: isOutdoor,
                                action: { isOutdoor = true }
                            )
                            
                            LocationCard(
                                title: "İç Mekan",
                                icon: "house.fill",
                                description: "Manuel mesafe girişi",
                                isSelected: !isOutdoor,
                                action: { isOutdoor = false }
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Features Info
                    FeaturesInfoCard(isOutdoor: isOutdoor)
                        .padding(.horizontal)
                    
                    // Start Button
                    Button(action: startActivity) {
                        HStack {
                            Image(systemName: "play.fill")
                                .font(.title3)
                            Text("Başla")
                                .font(theme.typography.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(theme.spacing.l)
                        .background(theme.colors.accent)
                        .cornerRadius(theme.radius.m)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, theme.spacing.xl)
                }
            }
            .navigationTitle("Cardio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showingPreparation) {
                if let user = currentUser {
                    CardioPreparationView(
                        activityType: selectedActivity,
                        isOutdoor: isOutdoor,
                        user: user
                    )
                }
            }
        }
    }
    
    private func startActivity() {
        showingPreparation = true
    }
}

// MARK: - Activity Card
struct ActivityCard: View {
    @Environment(\.theme) private var theme
    let activity: CardioTimerViewModel.CardioActivityType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: theme.spacing.m) {
                Image(systemName: activity.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : theme.colors.accent)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.displayName)
                        .font(theme.typography.headline)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : theme.colors.textPrimary)
                    
                    Text("MET: \(String(format: "%.1f", activity.metValue))")
                        .font(theme.typography.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : theme.colors.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            }
            .padding(theme.spacing.m)
            .background(
                RoundedRectangle(cornerRadius: theme.radius.m)
                    .fill(isSelected ? theme.colors.accent : theme.colors.backgroundSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.m)
                    .stroke(isSelected ? Color.clear : theme.colors.backgroundSecondary, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Location Card
struct LocationCard: View {
    @Environment(\.theme) private var theme
    let title: String
    let icon: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: theme.spacing.s) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(isSelected ? .white : theme.colors.accent)
                
                Text(title)
                    .font(theme.typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : theme.colors.textPrimary)
                
                Text(description)
                    .font(theme.typography.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(theme.spacing.m)
            .background(
                RoundedRectangle(cornerRadius: theme.radius.m)
                    .fill(isSelected ? theme.colors.accent : theme.colors.backgroundSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.m)
                    .stroke(isSelected ? Color.clear : theme.colors.backgroundSecondary, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Features Info Card
struct FeaturesInfoCard: View {
    @Environment(\.theme) private var theme
    let isOutdoor: Bool
    
    private var features: [(icon: String, text: String)] {
        if isOutdoor {
            return [
                ("location.fill", "GPS ile gerçek zamanlı mesafe takibi"),
                ("map.fill", "Antrenman sonunda rota haritası"),
                ("speedometer", "Anlık hız ve tempo gösterimi"),
                ("arrow.up.arrow.down", "Yükseklik değişimi kaydı")
            ]
        } else {
            return [
                ("timer", "Süre takibi"),
                ("flame.fill", "Tahmini kalori hesaplama"),
                ("heart.fill", "Nabız bandı desteği"),
                ("pencil", "Antrenman sonrası manuel mesafe girişi")
            ]
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(theme.colors.accent)
                Text("Özellikler")
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: theme.spacing.s) {
                ForEach(features, id: \.text) { feature in
                    HStack(spacing: theme.spacing.s) {
                        Image(systemName: feature.icon)
                            .font(.caption)
                            .foregroundColor(theme.colors.accent)
                            .frame(width: 20)
                        
                        Text(feature.text)
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(theme.spacing.m)
        .background(
            RoundedRectangle(cornerRadius: theme.radius.m)
                .fill(theme.colors.backgroundSecondary.opacity(0.5))
        )
    }
}

#Preview {
    CardioQuickStartView()
        .modelContainer(for: User.self, inMemory: true)
}