import SwiftUI
import SwiftData
import Foundation

struct CardioSessionTrackingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    
    let exerciseType: CardioWorkout
    let user: User
    let sessionType: CardioSessionType
    let targetDistance: Double? // meters
    let targetTime: Int? // seconds
    let notes: String?
    
    @State private var actualDistance: Double = 0 // meters
    @State private var actualTime: Int = 0 // seconds
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0
    @State private var distanceKm: Double = 0.0
    @State private var distanceMeters: Double = 0.0
    @State private var heartRate: Int = 0
    @State private var feeling: SessionFeeling = .good
    @State private var sessionNotes: String = ""
    @State private var showingCompleteConfirmation = false
    @State private var isCalculating = false
    
    // Calculated values
    private var totalSeconds: Int {
        hours * 3600 + minutes * 60 + seconds
    }
    
    private var totalMeters: Double {
        distanceKm * 1000 + distanceMeters
    }
    
    private var averagePace: Double? {
        guard totalMeters > 0 && totalSeconds > 0 else { return nil }
        return Double(totalSeconds) / (totalMeters / 1000) // seconds per km
    }
    
    private var speed: Double? {
        guard totalMeters > 0 && totalSeconds > 0 else { return nil }
        return (totalMeters / 1000) / (Double(totalSeconds) / 3600) // km/h
    }
    
    private var estimatedCalories: Int {
        guard totalSeconds > 0 else { return 0 }
        
        // Basic calorie calculation based on exercise type and user weight
        let durationHours = Double(totalSeconds) / 3600
        let weight = user.currentWeight
        
        let metValue: Double
        if let exercise = exerciseType.exercises.first {
            switch exercise.exerciseType {
            case "run":
                metValue = speed ?? 0 < 8 ? 8.0 : (speed ?? 0 < 12 ? 10.0 : 12.0)
            case "bike":
                metValue = 6.8
            case "row":
                metValue = 7.0
            case "ski":
                metValue = 9.0
            case "walk":
                metValue = 3.5
            default:
                metValue = 6.0
            }
        } else {
            metValue = 6.0
        }
        
        return Int(metValue * weight * durationHours)
    }
    
    private var targetProgress: Double {
        if let targetDist = targetDistance, sessionType == .distance {
            return min(totalMeters / targetDist, 1.0)
        } else if let targetT = targetTime, sessionType == .time {
            return min(Double(totalSeconds) / Double(targetT), 1.0)
        }
        return 0.0
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: theme.spacing.l) {
                    // Header
                    VStack(spacing: theme.spacing.s) {
                        Text(exerciseType.localizedName)
                            .font(theme.typography.title2)
                            .fontWeight(.bold)
                            .foregroundColor(theme.colors.textPrimary)
                        
                        Text(TrainingKeys.Cardio.logResults.localized)
                            .font(theme.typography.body)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    
                    // Target Progress
                    if targetDistance != nil || targetTime != nil {
                        TargetProgressCard(
                            sessionType: sessionType,
                            targetDistance: targetDistance,
                            targetTime: targetTime,
                            actualDistance: totalMeters,
                            actualTime: totalSeconds,
                            progress: targetProgress
                        )
                    }
                    
                    // Time Input
                    TimeInputCard(
                        hours: $hours,
                        minutes: $minutes,
                        seconds: $seconds
                    )
                    
                    // Distance Input
                    DistanceInputCard(
                        kilometers: $distanceKm,
                        meters: $distanceMeters
                    )
                    
                    // Real-time Calculations
                    if totalSeconds > 0 && totalMeters > 0 {
                        CalculationsCard(
                            pace: averagePace,
                            speed: speed,
                            calories: estimatedCalories,
                            exerciseType: exerciseType.exercises.first?.exerciseType ?? "run"
                        )
                        .transition(.opacity.combined(with: .scale))
                    }
                    
                    // Optional Fields
                    OptionalFieldsCard(
                        heartRate: $heartRate,
                        feeling: $feeling,
                        notes: $sessionNotes
                    )
                    
                    // Complete Button
                    Button(action: { showingCompleteConfirmation = true }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                            Text(TrainingKeys.Cardio.completeSession.localized)
                                .font(theme.typography.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(theme.spacing.m)
                        .background(
                            (totalSeconds > 0 && totalMeters > 0) ? 
                            theme.colors.accent : 
                            theme.colors.textSecondary.opacity(0.5)
                        )
                        .cornerRadius(theme.radius.m)
                    }
                    .disabled(totalSeconds == 0 || totalMeters == 0)
                }
                .padding(theme.spacing.m)
            }
            .navigationTitle(TrainingKeys.Cardio.sessionTracking.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationKeys.Common.cancel.localized) { dismiss() }
                }
            }
        }
        .confirmationDialog(TrainingKeys.Cardio.completeSession.localized, isPresented: $showingCompleteConfirmation) {
            Button("Complete") {
                completeSession()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(TrainingKeys.Cardio.saveSession.localized)
        }
    }
    
    private func completeSession() {
        withAnimation {
            isCalculating = true
        }
        
        // Create session
        let session = CardioSession(workout: exerciseType, user: user)
        session.startSession()
        
        // Create result
        let result = CardioResult(
            exercise: exerciseType.exercises.first,
            session: session,
            completionTime: totalSeconds,
            distanceCovered: totalMeters
        )
        
        // Complete the exercise with additional data
        result.completeExercise(
            time: totalSeconds,
            distance: totalMeters,
            heartRate: heartRate > 0 ? (avg: heartRate, max: heartRate) : nil,
            effort: nil,
            notes: sessionNotes.isEmpty ? nil : sessionNotes
        )
        
        // Set calorie data
        result.caloriesBurned = estimatedCalories
        
        session.completeSession(with: [result], feeling: feeling.rawValue, notes: notes)
        
        // Update user stats
        user.updateCardioStats(
            sessions: 1,
            totalTime: TimeInterval(totalSeconds),
            totalDistance: totalMeters,
            calories: estimatedCalories
        )
        
        // Save to context
        modelContext.insert(session)
        modelContext.insert(result)
        
        try? modelContext.save()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
}

// MARK: - Target Progress Card
struct TargetProgressCard: View {
    @Environment(\.theme) private var theme
    let sessionType: CardioSessionType
    let targetDistance: Double?
    let targetTime: Int?
    let actualDistance: Double
    let actualTime: Int
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            HStack {
                Text(TrainingKeys.Cardio.targetProgress.localized)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(theme.typography.body)
                    .fontWeight(.bold)
                    .foregroundColor(progress >= 1.0 ? theme.colors.success : theme.colors.accent)
            }
            
            ProgressView(value: progress)
                .tint(progress >= 1.0 ? theme.colors.success : theme.colors.accent)
                .scaleEffect(y: 2)
            
            HStack {
                if sessionType == .distance, let target = targetDistance {
                    Text("Target: \(formatDistance(target))")
                        .font(.caption2)
                        .foregroundColor(theme.colors.textSecondary)
                    Spacer()
                    Text("Current: \(formatDistance(actualDistance))")
                        .font(.caption2)
                        .foregroundColor(theme.colors.textSecondary)
                } else if sessionType == .time, let target = targetTime {
                    Text("Target: \(formatDuration(target))")
                        .font(.caption2)
                        .foregroundColor(theme.colors.textSecondary)
                    Spacer()
                    Text("Current: \(formatDuration(actualTime))")
                        .font(.caption2)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
        .padding(theme.spacing.m)
        .cardStyle()
    }
    
    private func formatDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1fkm", meters / 1000)
        }
        return String(format: "%.0fm", meters)
    }
    
    private func formatDuration(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - Time Input Card
struct TimeInputCard: View {
    @Environment(\.theme) private var theme
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var seconds: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text(TrainingKeys.Cardio.duration.localized)
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
            
            HStack(spacing: theme.spacing.m) {
                TimePickerColumn(value: $hours, range: 0...23, label: "h")
                Text(":")
                    .font(theme.typography.title2)
                    .foregroundColor(theme.colors.textSecondary)
                TimePickerColumn(value: $minutes, range: 0...59, label: "m")
                Text(":")
                    .font(theme.typography.title2)
                    .foregroundColor(theme.colors.textSecondary)
                TimePickerColumn(value: $seconds, range: 0...59, label: "s")
            }
            .frame(maxWidth: .infinity)
        }
        .padding(theme.spacing.m)
        .cardStyle()
    }
}

struct TimePickerColumn: View {
    @Environment(\.theme) private var theme
    @Binding var value: Int
    let range: ClosedRange<Int>
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            TextField("0", value: $value, format: .number)
                .keyboardType(.numberPad)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
                .font(theme.typography.title2)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
                .frame(width: 60)
                .padding(.vertical, theme.spacing.s)
                .background(theme.colors.backgroundSecondary)
                .cornerRadius(theme.radius.s)
                .onChange(of: value) { _, newValue in
                    value = max(range.lowerBound, min(range.upperBound, newValue))
                }
            
            Text(label)
                .font(.caption2)
                .foregroundColor(theme.colors.textSecondary)
        }
    }
}

// MARK: - Distance Input Card
struct DistanceInputCard: View {
    @Environment(\.theme) private var theme
    @Binding var kilometers: Double
    @Binding var meters: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text(TrainingKeys.Cardio.distance.localized)
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
            
            HStack(spacing: theme.spacing.m) {
                VStack(spacing: 4) {
                    TextField("0", value: $kilometers, format: .number.precision(.fractionLength(1)))
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                        .multilineTextAlignment(.center)
                        .font(theme.typography.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                        .padding(.vertical, theme.spacing.s)
                        .background(theme.colors.backgroundSecondary)
                        .cornerRadius(theme.radius.s)
                        .onChange(of: kilometers) { _, newValue in
                            kilometers = max(0, newValue)
                        }
                    
                    Text("km")
                        .font(.caption2)
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                Text("+")
                    .font(theme.typography.title2)
                    .foregroundColor(theme.colors.textSecondary)
                
                VStack(spacing: 4) {
                    TextField("0", value: $meters, format: .number.precision(.fractionLength(0)))
                        .keyboardType(.numberPad)
                        .textFieldStyle(.plain)
                        .multilineTextAlignment(.center)
                        .font(theme.typography.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                        .padding(.vertical, theme.spacing.s)
                        .background(theme.colors.backgroundSecondary)
                        .cornerRadius(theme.radius.s)
                        .onChange(of: meters) { _, newValue in
                            meters = max(0, min(999, newValue))
                        }
                    
                    Text("m")
                        .font(.caption2)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(theme.spacing.m)
        .cardStyle()
    }
}

// MARK: - Calculations Card
struct CalculationsCard: View {
    @Environment(\.theme) private var theme
    let pace: Double?
    let speed: Double?
    let calories: Int
    let exerciseType: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(theme.colors.accent)
                Text(TrainingKeys.Cardio.performance.localized)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
            }
            
            HStack(spacing: theme.spacing.xl) {
                if let pace = pace {
                    StatItem(
                        title: "Pace",
                        value: formatPace(pace) + " min/km"
                    )
                }
                
                if let speed = speed {
                    StatItem(
                        title: "Speed",
                        value: String(format: "%.1f km/h", speed)
                    )
                }
                
                StatItem(
                    title: "Calories",
                    value: "\(calories) kcal"
                )
                
                Spacer()
            }
        }
        .padding(theme.spacing.m)
        .background(
            RoundedRectangle(cornerRadius: theme.radius.m)
                .fill(theme.colors.accent.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.radius.m)
                .stroke(theme.colors.accent.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func formatPace(_ paceSecondsPerKm: Double) -> String {
        let minutes = Int(paceSecondsPerKm / 60)
        let seconds = Int(paceSecondsPerKm.truncatingRemainder(dividingBy: 60))
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}


// MARK: - Optional Fields Card
struct OptionalFieldsCard: View {
    @Environment(\.theme) private var theme
    @Binding var heartRate: Int
    @Binding var feeling: SessionFeeling
    @Binding var notes: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text(TrainingKeys.Cardio.additionalInfo.localized)
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
            
            // Heart Rate
            VStack(alignment: .leading, spacing: theme.spacing.s) {
                Text(TrainingKeys.Cardio.heartRate.localized)
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textPrimary)
                
                HStack {
                    TextField("Average BPM", value: $heartRate, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.plain)
                        .padding(theme.spacing.s)
                        .background(theme.colors.backgroundSecondary)
                        .cornerRadius(theme.radius.s)
                        .onChange(of: heartRate) { _, newValue in
                            heartRate = max(0, min(220, newValue))
                        }
                    
                    Text("BPM")
                        .font(theme.typography.body)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            
            // Feeling
            VStack(alignment: .leading, spacing: theme.spacing.s) {
                Text(TrainingKeys.Cardio.feeling.localized)
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textPrimary)
                
                HStack(spacing: theme.spacing.s) {
                    ForEach(SessionFeeling.allCases, id: \.self) { feelingOption in
                        Button(action: { feeling = feelingOption }) {
                            HStack(spacing: 4) {
                                Text(feelingOption.emoji)
                                Text(feelingOption.displayName)
                                    .font(.caption)
                            }
                            .padding(.horizontal, theme.spacing.s)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: theme.radius.s)
                                    .fill(feeling == feelingOption ? theme.colors.accent : theme.colors.backgroundSecondary)
                            )
                            .foregroundColor(feeling == feelingOption ? .white : theme.colors.textPrimary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // Notes
            VStack(alignment: .leading, spacing: theme.spacing.s) {
                Text(TrainingKeys.Cardio.sessionNotes.localized)
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textPrimary)
                
                TextField(TrainingKeys.Cardio.sessionNotesPlaceholder.localized, text: $notes, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(theme.spacing.s)
                    .background(theme.colors.backgroundSecondary)
                    .cornerRadius(theme.radius.s)
                    .lineLimit(3...6)
            }
        }
        .padding(theme.spacing.m)
        .cardStyle()
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
    
    CardioSessionTrackingView(
        exerciseType: workout,
        user: user,
        sessionType: CardioSessionType.distance,
        targetDistance: 5000,
        targetTime: nil as Int?,
        notes: nil as String?
    )
    .modelContainer(for: [CardioWorkout.self], inMemory: true)
}