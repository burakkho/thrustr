import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @Query private var workouts: [Workout]
    @Query private var weightEntries: [WeightEntry]
    @Query private var nutritionEntries: [NutritionEntry]
    
    @State private var selectedCategory: AchievementCategory = .all
    
    private var currentUser: User? {
        users.first
    }
    
    private var achievements: [Achievement] {
        Achievement.allAchievements.map { achievement in
            var updatedAchievement = achievement
            updatedAchievement.updateProgress(
                workouts: workouts,
                weightEntries: weightEntries,
                nutritionEntries: nutritionEntries,
                user: currentUser
            )
            return updatedAchievement
        }
    }
    
    private var filteredAchievements: [Achievement] {
        if selectedCategory == .all {
            return achievements
        }
        return achievements.filter { $0.category == selectedCategory }
    }
    
    private var completedAchievements: [Achievement] {
        achievements.filter { $0.isCompleted }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Section
                AchievementsHeaderSection(
                    completedCount: completedAchievements.count,
                    totalCount: achievements.count
                )
                
                // Category Selector
                CategorySelectorSection(selectedCategory: $selectedCategory)
                
                // Achievements Grid
                AchievementsGridSection(achievements: filteredAchievements)
                
                // Statistics Section
                AchievementStatisticsSection(achievements: achievements)
            }
            .padding()
        }
        .navigationTitle("Başarımlar")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Header Section
struct AchievementsHeaderSection: View {
    let completedCount: Int
    let totalCount: Int
    
    private var completionPercentage: Double {
        totalCount > 0 ? Double(completedCount) / Double(totalCount) * 100 : 0
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            VStack(spacing: 8) {
                Text("Başarımlar")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Hedeflerini tamamla ve rozet kazan!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Progress Ring
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 8)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: completionPercentage / 100)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: completionPercentage)
                
                VStack(spacing: 2) {
                    Text("\(completedCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("/ \(totalCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("\(Int(completionPercentage))% Tamamlandı")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Category Selector Section
struct CategorySelectorSection: View {
    @Binding var selectedCategory: AchievementCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kategori")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AchievementCategory.allCases, id: \.self) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: category.icon)
                                    .font(.caption)
                                
                                Text(category.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedCategory == category ? category.color : Color(.secondarySystemBackground))
                            .foregroundColor(selectedCategory == category ? .white : .primary)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Achievements Grid Section
struct AchievementsGridSection: View {
    let achievements: [Achievement]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Başarımlar")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(achievements, id: \.id) { achievement in
                    AchievementCard(achievement: achievement)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - Achievement Card
struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 12) {
            // Achievement Icon
            ZStack {
                Circle()
                    .fill(achievement.isCompleted ?
                          LinearGradient(gradient: Gradient(colors: [.yellow, .orange]), startPoint: .top, endPoint: .bottom) :
                          LinearGradient(gradient: Gradient(colors: [Color(.systemGray5), Color(.systemGray4)]), startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundColor(achievement.isCompleted ? .white : .secondary)
            }
            
            // Achievement Info
            VStack(spacing: 4) {
                Text(achievement.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(achievement.isCompleted ? .primary : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text(achievement.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            
            // Progress Bar
            if !achievement.isCompleted {
                VStack(spacing: 4) {
                    ProgressView(value: achievement.progressPercentage, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: achievement.category.color))
                        .scaleEffect(x: 1, y: 0.5)
                    
                    Text("\(Int(achievement.currentProgress))/\(Int(achievement.targetValue))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Tamamlandı! ✅")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .scaleEffect(achievement.isCompleted ? 1.05 : 1.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: achievement.isCompleted)
    }
}

// MARK: - Achievement Statistics Section
struct AchievementStatisticsSection: View {
    let achievements: [Achievement]
    
    private var categoryStats: [(AchievementCategory, Int, Int)] {
        AchievementCategory.allCases.compactMap { category in
            guard category != .all else { return nil }
            let categoryAchievements = achievements.filter { $0.category == category }
            let completed = categoryAchievements.filter { $0.isCompleted }.count
            let total = categoryAchievements.count
            return (category, completed, total)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Kategori İstatistikleri")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(categoryStats, id: \.0) { category, completed, total in
                    CategoryStatRow(
                        category: category,
                        completed: completed,
                        total: total
                    )
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

struct CategoryStatRow: View {
    let category: AchievementCategory
    let completed: Int
    let total: Int
    
    private var percentage: Double {
        total > 0 ? Double(completed) / Double(total) : 0
    }
    
    var body: some View {
        HStack {
            Image(systemName: category.icon)
                .font(.title3)
                .foregroundColor(category.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ProgressView(value: percentage, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: category.color))
                    .scaleEffect(x: 1, y: 0.5)
            }
            
            Spacer()
            
            Text("\(completed)/\(total)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(category.color)
        }
    }
}

// MARK: - Achievement Model
struct Achievement: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let targetValue: Double
    var currentProgress: Double = 0
    
    var isCompleted: Bool {
        currentProgress >= targetValue
    }
    
    var progressPercentage: Double {
        min(currentProgress / targetValue, 1.0)
    }
    
    mutating func updateProgress(workouts: [Workout], weightEntries: [WeightEntry], nutritionEntries: [NutritionEntry], user: User?) {
        switch title {
        case "İlk Antrenman":
            currentProgress = Double(workouts.count >= 1 ? 1 : 0)
        case "10 Antrenman":
            currentProgress = Double(min(workouts.count, 10))
        case "50 Antrenman":
            currentProgress = Double(min(workouts.count, 50))
        case "100 Antrenman":
            currentProgress = Double(min(workouts.count, 100))
        case "Hafta Sonu Savaşçısı":
            let weekendWorkouts = workouts.filter { Calendar.current.isDateInWeekend($0.date) }.count
            currentProgress = Double(min(weekendWorkouts, 10))
        case "Ağırlık Avcısı":
            let totalVolume = workouts.reduce(0) { $0 + $1.totalVolume }
            currentProgress = min(totalVolume, 10000)
        case "İlk Kilo Kaydı":
            currentProgress = Double(weightEntries.count >= 1 ? 1 : 0)
        case "Takipçi":
            currentProgress = Double(min(weightEntries.count, 30))
        case "İlk Beslenme Kaydı":
            currentProgress = Double(nutritionEntries.count >= 1 ? 1 : 0)
        case "Beslenme Uzmanı":
            currentProgress = Double(min(nutritionEntries.count, 100))
        default:
            currentProgress = 0
        }
    }
    
    static let allAchievements: [Achievement] = [
        // Workout Achievements
        Achievement(title: "İlk Antrenman", description: "İlk antrenmanını tamamla", icon: "dumbbell.fill", category: .workout, targetValue: 1),
        Achievement(title: "10 Antrenman", description: "10 antrenman tamamla", icon: "10.circle.fill", category: .workout, targetValue: 10),
        Achievement(title: "50 Antrenman", description: "50 antrenman tamamla", icon: "50.circle.fill", category: .workout, targetValue: 50),
        Achievement(title: "100 Antrenman", description: "100 antrenman tamamla", icon: "100.circle.fill", category: .workout, targetValue: 100),
        Achievement(title: "Hafta Sonu Savaşçısı", description: "10 hafta sonu antrenmanı", icon: "calendar.badge.clock", category: .workout, targetValue: 10),
        Achievement(title: "Ağırlık Avcısı", description: "10,000 kg toplam hacim", icon: "scalemass.fill", category: .workout, targetValue: 10000),
        
        // Weight Tracking Achievements
        Achievement(title: "İlk Kilo Kaydı", description: "İlk kilo kaydını gir", icon: "scalemass.fill", category: .weight, targetValue: 1),
        Achievement(title: "Takipçi", description: "30 gün kilo takibi", icon: "chart.line.uptrend.xyaxis", category: .weight, targetValue: 30),
        
        // Nutrition Achievements
        Achievement(title: "İlk Beslenme Kaydı", description: "İlk öğünü kaydet", icon: "fork.knife", category: .nutrition, targetValue: 1),
        Achievement(title: "Beslenme Uzmanı", description: "100 öğün kaydı", icon: "leaf.fill", category: .nutrition, targetValue: 100),
        
        // Streak Achievements
        Achievement(title: "3 Günlük Seri", description: "3 gün üst üste antrenman", icon: "flame.fill", category: .streak, targetValue: 3),
        Achievement(title: "Haftalık Seri", description: "7 gün üst üste antrenman", icon: "flame.fill", category: .streak, targetValue: 7),
        
        // Social Achievements
        Achievement(title: "Paylaşımcı", description: "İlk ilerleme fotoğrafı", icon: "camera.fill", category: .social, targetValue: 1),
        Achievement(title: "Motivatör", description: "5 ilerleme fotoğrafı paylaş", icon: "photo.stack.fill", category: .social, targetValue: 5)
    ]
}

// MARK: - Achievement Category Enum
enum AchievementCategory: CaseIterable {
    case all, workout, weight, nutrition, streak, social
    
    var displayName: String {
        switch self {
        case .all: return "Tümü"
        case .workout: return "Antrenman"
        case .weight: return "Kilo"
        case .nutrition: return "Beslenme"
        case .streak: return "Seri"
        case .social: return "Sosyal"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "star.fill"
        case .workout: return "dumbbell.fill"
        case .weight: return "scalemass.fill"
        case .nutrition: return "fork.knife"
        case .streak: return "flame.fill"
        case .social: return "person.2.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .blue
        case .workout: return .red
        case .weight: return .orange
        case .nutrition: return .green
        case .streak: return .purple
        case .social: return .pink
        }
    }
}

#Preview {
    NavigationView {
        AchievementsView()
    }
}
