import SwiftUI
import SwiftData

struct CardioWorkoutDetail: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var unitSettings: UnitSettings
    @Query private var user: [User]
    
    let workout: CardioWorkout
    @State private var showingDeleteConfirmation = false
    
    private var currentUser: User? {
        user.first
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: theme.spacing.l) {
                    headerSection
                    workoutInfoSection
                    personalRecordSection
                    statisticsSection  
                    recentSessionsSection
                    actionButtonsSection
                }
                .padding(theme.spacing.m)
            }
            .navigationTitle(TrainingKeys.Cardio.workoutDetails.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .confirmationDialog("Delete Workout", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteWorkout()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone. All session data will be preserved.")
        }
    }
    
    private func toggleFavorite() {
        workout.toggleFavorite()
        try? modelContext.save()
    }
    
    private func duplicateWorkout() {
        let duplicate = workout.duplicate()
        modelContext.insert(duplicate)
        try? modelContext.save()
    }
    
    private func deleteWorkout() {
        modelContext.delete(workout)
        try? modelContext.save()
        dismiss()
    }
    
    private func difficultyIcon(_ difficulty: String) -> String {
        switch difficulty {
        case "beginner": return "1.circle.fill"
        case "intermediate": return "2.circle.fill"
        case "advanced": return "3.circle.fill"
        default: return "circle.fill"
        }
    }
    
    // MARK: - View Sections
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            HStack {
                VStack(alignment: .leading, spacing: theme.spacing.s) {
                    Text(workout.localizedName)
                        .font(theme.typography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    if !workout.localizedDescription.isEmpty {
                        Text(workout.localizedDescription)
                            .font(theme.typography.body)
                            .foregroundColor(theme.colors.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                Button(action: toggleFavorite) {
                    Image(systemName: workout.isFavorite ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundColor(workout.isFavorite ? theme.colors.warning : theme.colors.textSecondary)
                }
            }
        }
    }
    
    private var workoutInfoSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            // Workout Info Row
            HStack(spacing: theme.spacing.xl) {
                InfoColumn(
                    title: TrainingKeys.Cardio.type.localized,
                    value: TrainingKeys.Cardio.title.localized,
                    icon: "heart.fill"
                )
                
                if let exercise = workout.exercises.first {
                    InfoColumn(
                        title: TrainingKeys.Cardio.activity.localized,
                        value: exercise.exerciseType.capitalized,
                        icon: exercise.exerciseIcon
                    )
                }
                
                InfoColumn(
                    title: TrainingKeys.Cardio.flexibility.localized,
                    value: TrainingKeys.Cardio.anyDistanceTime.localized,
                    icon: "arrow.triangle.2.circlepath"
                )
                
                Spacer()
            }
            
            // Equipment
            if !workout.equipment.isEmpty {
                VStack(alignment: .leading, spacing: theme.spacing.s) {
                    Text(TrainingKeys.Cardio.equipment.localized)
                        .font(theme.typography.headline)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    HStack {
                        ForEach(workout.equipment, id: \.self) { equipment in
                            EquipmentBadge(equipment: equipment)
                        }
                        Spacer()
                    }
                }
            }
        }
        .padding(theme.spacing.m)
        .cardStyle()
    }
    
    @ViewBuilder
    private var personalRecordSection: some View {
        if let pr = workout.personalRecord {
            PersonalRecordCard(result: pr, workoutType: workout.type)
        }
    }
    
    @ViewBuilder
    private var statisticsSection: some View {
        if workout.totalSessions > 0 {
            StatisticsCard(workout: workout)
        }
    }
    
    @ViewBuilder
    private var recentSessionsSection: some View {
        if !workout.sessions.isEmpty {
            RecentSessionsSection(sessions: Array(workout.sessions.filter { $0.isCompleted }.sorted { $0.completedAt ?? $0.startDate > $1.completedAt ?? $1.startDate }.prefix(5)))
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: theme.spacing.m) {
            // Note: Start workout functionality removed
            // Use CardioQuickStartView from main cardio screen instead
            
            // Secondary Actions
            HStack(spacing: theme.spacing.m) {
                Button(action: duplicateWorkout) {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text(TrainingKeys.Cardio.duplicate.localized)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(theme.colors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(theme.spacing.m)
                    .background(theme.colors.accent.opacity(0.1))
                    .cornerRadius(theme.radius.m)
                }
                
                if workout.isCustom {
                    Button(action: { showingDeleteConfirmation = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text(TrainingKeys.Cardio.delete.localized)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(theme.colors.error)
                        .frame(maxWidth: .infinity)
                        .padding(theme.spacing.m)
                        .background(theme.colors.error.opacity(0.1))
                        .cornerRadius(theme.radius.m)
                    }
                }
            }
        }
        .padding(theme.spacing.m)
    }

    private func equipmentDisplayName(_ equipment: String) -> String {
        switch equipment {
        case "outdoor": return "Outdoor"
        case "treadmill": return "Treadmill"
        case "row_erg": return "Row Erg"
        case "bike_erg": return "Bike Erg"
        case "ski_erg": return "Ski Erg"
        default: return equipment.capitalized
        }
    }
}

// MARK: - Supporting Views
struct InfoColumn: View {
    @Environment(\.theme) private var theme
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            Text(value)
                .font(theme.typography.body)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
        }
    }
}

struct EquipmentBadge: View {
    @Environment(\.theme) private var theme
    let equipment: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: equipmentIcon(equipment))
                .font(.caption)
            Text(equipmentDisplayName(equipment))
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.colors.backgroundSecondary)
        )
        .foregroundColor(theme.colors.textSecondary)
    }
    
    private func equipmentIcon(_ equipment: String) -> String {
        switch equipment {
        case "outdoor": return "sun.max"
        case "treadmill": return "figure.run"
        case "row_erg": return "oar.2.crossed"
        case "bike_erg": return "bicycle"
        case "ski_erg": return "figure.skiing.crosscountry"
        default: return "questionmark.circle"
        }
    }
    
    private func equipmentDisplayName(_ equipment: String) -> String {
        switch equipment {
        case "outdoor": return "Outdoor"
        case "treadmill": return "Treadmill"
        case "row_erg": return "Row Erg"
        case "bike_erg": return "Bike Erg"
        case "ski_erg": return "Ski Erg"
        default: return equipment.capitalized
        }
    }
}

struct PersonalRecordCard: View {
    @Environment(\.theme) private var theme
    let result: CardioResult
    let workoutType: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(theme.colors.warning)
                Text(TrainingKeys.Cardio.personalRecord.localized)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
            }
            
            HStack(spacing: theme.spacing.xl) {
                if let time = result.formattedTime {
                    StatItem(title: TrainingKeys.Cardio.time.localized, value: time)
                }
                
                if let distance = result.formattedDistance {
                    StatItem(title: TrainingKeys.Cardio.distance.localized, value: distance)
                }
                
                if let pace = result.formattedPace {
                    StatItem(title: TrainingKeys.Cardio.pace.localized, value: pace)
                }
                
                Spacer()
            }
            
            Text("Set on \(result.completedAt, style: .date)")
                .font(.caption2)
                .foregroundColor(theme.colors.textSecondary)
        }
        .padding(theme.spacing.m)
        .background(
            RoundedRectangle(cornerRadius: theme.radius.m)
                .fill(theme.colors.warning.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.radius.m)
                .stroke(theme.colors.warning.opacity(0.3), lineWidth: 1)
        )
    }
}

struct StatisticsCard: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var unitSettings: UnitSettings
    let workout: CardioWorkout
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text(TrainingKeys.Cardio.statistics.localized)
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
            
            HStack(spacing: theme.spacing.xl) {
                StatItem(title: "Total Sessions", value: "\(workout.totalSessions)")
                
                if let lastDate = workout.lastPerformed {
                    StatItem(title: "Last Performed", value: lastDate.formatted(.relative(presentation: .named)))
                }
                
                StatItem(title: "Sessions", value: "\(workout.totalSessions)")
                
                Spacer()
            }
        }
        .padding(theme.spacing.m)
        .cardStyle()
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return "\(minutes):\(String(format: "%02d", secs))"
    }
    
    private func formatDistance(_ meters: Double) -> String {
        return UnitsFormatter.formatDistance(meters: meters, system: unitSettings.unitSystem)
    }
}

struct StatItem: View {
    @Environment(\.theme) private var theme
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(theme.colors.textSecondary)
            Text(value)
                .font(theme.typography.body)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
        }
    }
}

struct RecentSessionsSection: View {
    @Environment(\.theme) private var theme
    let sessions: [CardioSession]
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text(TrainingKeys.Cardio.recentSessions.localized)
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
            
            VStack(spacing: theme.spacing.s) {
                ForEach(sessions, id: \.id) { session in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.completedAt ?? session.startDate, style: .date)
                                .font(.caption2)
                                .foregroundColor(theme.colors.textSecondary)
                            
                            HStack(spacing: theme.spacing.m) {
                                Text(session.formattedDuration)
                                    .font(theme.typography.caption)
                                    .foregroundColor(theme.colors.textPrimary)
                                
                                Text(session.formattedDistance)
                                    .font(theme.typography.caption)
                                    .foregroundColor(theme.colors.textPrimary)
                                
                                if let pace = session.formattedAveragePace {
                                    Text(pace)
                                        .font(theme.typography.caption)
                                        .foregroundColor(theme.colors.textSecondary)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        if !session.personalRecordsHit.isEmpty {
                            Text("🏆")
                                .font(.caption)
                        }
                    }
                    .padding(.vertical, theme.spacing.s)
                    
                    if session != sessions.last {
                        Divider()
                    }
                }
            }
        }
        .padding(theme.spacing.m)
        .cardStyle()
    }
}

#Preview {
    let workout = CardioWorkout(
        name: "5K Run",
        nameEN: "5K Run",
        nameTR: "5K Koşu",
        type: "distance",
        category: "benchmark",
        description: "Classic 5 kilometer run",
        targetDistance: 5000,
        difficulty: "intermediate",
        equipment: ["outdoor"],
        isTemplate: true,
        isCustom: false
    )
    
    return CardioWorkoutDetail(workout: workout)
        .environmentObject(UnitSettings.shared)
        .modelContainer(for: [CardioWorkout.self, CardioSession.self, User.self], inMemory: true)
}