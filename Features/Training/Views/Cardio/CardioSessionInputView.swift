import SwiftUI
import SwiftData

struct CardioSessionInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    
    let exerciseType: CardioWorkout
    let user: User
    
    @State private var sessionType: SessionType = .distance
    @State private var targetDistance: Double = 5.0 // km
    @State private var targetTime: Int = 30 // minutes
    @State private var notes: String = ""
    @State private var showingSession = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: theme.spacing.l) {
                    // Header
                    VStack(alignment: .leading, spacing: theme.spacing.s) {
                        HStack {
                            if let exercise = exerciseType.exercises.first {
                                Image(systemName: exercise.exerciseIcon)
                                    .font(.title2)
                                    .foregroundColor(theme.colors.accent)
                            }
                            
                            Text(exerciseType.localizedName)
                                .font(theme.typography.title2)
                                .fontWeight(.bold)
                                .foregroundColor(theme.colors.textPrimary)
                        }
                        
                        Text(LocalizationKeys.Training.Cardio.setGoal.localized)
                            .font(theme.typography.body)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Session Type Selection
                    VStack(alignment: .leading, spacing: theme.spacing.m) {
                        Text(LocalizationKeys.Training.Cardio.sessionType.localized)
                            .font(theme.typography.headline)
                            .foregroundColor(theme.colors.textPrimary)
                        
                        HStack(spacing: theme.spacing.m) {
                            SessionTypeButton(
                                type: .distance,
                                isSelected: sessionType == .distance,
                                onTap: { sessionType = .distance }
                            )
                            
                            SessionTypeButton(
                                type: .time,
                                isSelected: sessionType == .time,
                                onTap: { sessionType = .time }
                            )
                            
                            Spacer()
                        }
                    }
                    
                    // Target Input
                    VStack(alignment: .leading, spacing: theme.spacing.m) {
                        Text(LocalizationKeys.Training.Cardio.target.localized)
                            .font(theme.typography.headline)
                            .foregroundColor(theme.colors.textPrimary)
                        
                        switch sessionType {
                        case .distance:
                            DistanceInputView(targetDistance: $targetDistance)
                        case .time:
                            TimeInputView(targetTime: $targetTime)
                        }
                    }
                    
                    // Notes (Optional)
                    VStack(alignment: .leading, spacing: theme.spacing.s) {
                        Text(LocalizationKeys.Training.Cardio.notes.localized)
                            .font(theme.typography.headline)
                            .foregroundColor(theme.colors.textPrimary)
                        
                        TextField(LocalizationKeys.Training.Cardio.notesPlaceholder.localized, text: $notes)
                            .textFieldStyle(.plain)
                            .padding(theme.spacing.m)
                            .background(theme.colors.backgroundSecondary)
                            .cornerRadius(theme.radius.m)
                    }
                    
                    // Equipment Info
                    if !exerciseType.equipment.isEmpty {
                        VStack(alignment: .leading, spacing: theme.spacing.s) {
                            Text(LocalizationKeys.Training.Cardio.equipmentOptions.localized)
                                .font(theme.typography.headline)
                                .foregroundColor(theme.colors.textPrimary)
                            
                            HStack {
                                ForEach(exerciseType.equipment, id: \.self) { equipment in
                                    EquipmentBadge(equipment: equipment)
                                }
                                Spacer()
                            }
                        }
                    }
                    
                    // Start Button
                    Button(action: startSession) {
                        HStack {
                            Image(systemName: "play.fill")
                                .font(.title3)
                            Text(LocalizationKeys.Training.Cardio.startSession.localized)
                                .font(theme.typography.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(theme.spacing.m)
                        .background(theme.colors.accent)
                        .cornerRadius(theme.radius.m)
                    }
                }
                .padding(theme.spacing.m)
            }
            .navigationTitle(LocalizationKeys.Training.Cardio.newSession.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationKeys.Common.cancel.localized) { dismiss() }
                }
            }
        }
        .fullScreenCover(isPresented: $showingSession) {
            CardioSessionTrackingView(
                exerciseType: exerciseType,
                user: user,
                sessionType: sessionType,
                targetDistance: sessionType == .distance ? targetDistance * 1000 : nil, // Convert to meters
                targetTime: sessionType == .time ? targetTime * 60 : nil, // Convert to seconds
                notes: notes.isEmpty ? nil : notes
            )
        }
    }
    
    private func startSession() {
        showingSession = true
    }
}

// MARK: - Session Type
enum SessionType: String, CaseIterable {
    case distance = "distance"
    case time = "time"
    
    var displayName: String {
        switch self {
        case .distance: return LocalizationKeys.Training.Cardio.distanceGoal.localized
        case .time: return LocalizationKeys.Training.Cardio.timeGoal.localized
        }
    }
    
    var icon: String {
        switch self {
        case .distance: return "location.fill"
        case .time: return "timer"
        }
    }
    
    var description: String {
        switch self {
        case .distance: return LocalizationKeys.Training.Cardio.distanceGoal.localized
        case .time: return LocalizationKeys.Training.Cardio.timeGoal.localized
        }
    }
}

// MARK: - Supporting Views
struct SessionTypeButton: View {
    @Environment(\.theme) private var theme
    let type: SessionType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: theme.spacing.s) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? theme.colors.accent : theme.colors.textSecondary)
                
                VStack(spacing: 4) {
                    Text(type.displayName)
                        .font(theme.typography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text(type.description)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(theme.spacing.m)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: theme.radius.m)
                    .fill(isSelected ? theme.colors.accent.opacity(0.1) : theme.colors.backgroundSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.m)
                    .stroke(isSelected ? theme.colors.accent : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DistanceInputView: View {
    @Environment(\.theme) private var theme
    @Binding var targetDistance: Double
    
    private let commonDistances: [Double] = [1.0, 2.0, 3.0, 5.0, 10.0, 21.1]
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            // Quick Select
            Text(LocalizationKeys.Training.Cardio.quickSelect.localized)
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: theme.spacing.s) {
                ForEach(commonDistances, id: \.self) { distance in
                    Button(action: { targetDistance = distance }) {
                        Text("\(formatDistance(distance))")
                            .font(theme.typography.body)
                            .fontWeight(.medium)
                            .foregroundColor(targetDistance == distance ? .white : theme.colors.textPrimary)
                            .padding(.vertical, theme.spacing.s)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: theme.radius.s)
                                    .fill(targetDistance == distance ? theme.colors.accent : theme.colors.backgroundSecondary)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Custom Input
            Text(LocalizationKeys.Training.Cardio.customDistance.localized)
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
                .padding(.top, theme.spacing.s)
            
            HStack {
                TextField("Distance", value: $targetDistance, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.plain)
                    .padding(theme.spacing.s)
                    .background(theme.colors.backgroundSecondary)
                    .cornerRadius(theme.radius.s)
                
                Text("km")
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance == 21.1 {
            return "Half Marathon"
        } else if distance.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(distance))K"
        } else {
            return "\(distance)K"
        }
    }
}

struct TimeInputView: View {
    @Environment(\.theme) private var theme
    @Binding var targetTime: Int
    
    private let commonTimes: [Int] = [10, 15, 20, 30, 45, 60] // minutes
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            // Quick Select
            Text(LocalizationKeys.Training.Cardio.quickSelect.localized)
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: theme.spacing.s) {
                ForEach(commonTimes, id: \.self) { time in
                    Button(action: { targetTime = time }) {
                        Text("\(time)m")
                            .font(theme.typography.body)
                            .fontWeight(.medium)
                            .foregroundColor(targetTime == time ? .white : theme.colors.textPrimary)
                            .padding(.vertical, theme.spacing.s)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: theme.radius.s)
                                    .fill(targetTime == time ? theme.colors.accent : theme.colors.backgroundSecondary)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Custom Input
            Text(LocalizationKeys.Training.Cardio.customDuration.localized)
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
                .padding(.top, theme.spacing.s)
            
            HStack {
                TextField("Minutes", value: $targetTime, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.plain)
                    .padding(theme.spacing.s)
                    .background(theme.colors.backgroundSecondary)
                    .cornerRadius(theme.radius.s)
                
                Text("minutes")
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
    }
}



#Preview {
    let workout = CardioWorkout(
        name: "Running",
        nameEN: "Running",
        nameTR: "Koşu",
        type: "exercise",
        category: "exercise",
        description: "Outdoor or treadmill running",
        equipment: ["outdoor", "treadmill"],
        isTemplate: true,
        isCustom: false
    )
    
    let user = User(
        name: "Test User",
        age: 25,
        gender: Gender.male,
        height: 175,
        currentWeight: 70,
        fitnessGoal: FitnessGoal.maintain,
        activityLevel: ActivityLevel.moderate,
        selectedLanguage: "en"
    )
    
    CardioSessionInputView(exerciseType: workout, user: user)
        .modelContainer(for: [CardioWorkout.self], inMemory: true)
}