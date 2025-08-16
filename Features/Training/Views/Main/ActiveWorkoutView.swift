import SwiftUI
import SwiftData

// MARK: - Active Workout View
struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme
    @Query(filter: #Predicate<Workout> { !$0.isCompleted }) private var activeWorkouts: [Workout]
    
    let onWorkoutTap: (Workout) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if activeWorkouts.isEmpty {
                    // No active workout
                    VStack(spacing: theme.spacing.m) {
                        Image(systemName: "play.circle")
                            .font(.system(size: 50))
                            .foregroundColor(theme.colors.accent)
                        
                        Text(LocalizationKeys.Training.Active.emptyTitle.localized)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(LocalizationKeys.Training.Active.emptySubtitle.localized)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button(LocalizationKeys.Training.Active.startButton.localized) {
                            startNewWorkout()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(theme.spacing.m)
                        .background(theme.colors.accent)
                        .cornerRadius(12)
                        .buttonStyle(PressableStyle())
                        .accessibilityLabel(LocalizationKeys.Training.Active.startButton.localized)
                    }
                    .padding(.top, 80)
                } else if activeWorkouts.count == 1, let activeWorkout = activeWorkouts.first {
                    // Single active workout → existing card
                    ActiveWorkoutCard(workout: activeWorkout) { onWorkoutTap(activeWorkout) }
                } else {
                    // Multiple active workouts → list with actions
                    VStack(alignment: .leading, spacing: theme.spacing.s) {
                        Text(LocalizationKeys.Training.Active.multipleTitle.localized)
                            .font(.headline)
                            .padding(.horizontal, theme.spacing.s)
                        ForEach(activeWorkouts.sorted(by: { $0.startTime > $1.startTime }), id: \.id) { workout in
                            ActiveWorkoutRow(workout: workout, onContinue: {
                                onWorkoutTap(workout)
                            })
                        }
                    }
                }
            }
            .padding(theme.spacing.m)
        }
    }
    
    private func startNewWorkout() {
        let newWorkout = Workout(name: LocalizationKeys.Training.History.defaultName.localized)
        modelContext.insert(newWorkout)
        onWorkoutTap(newWorkout)
    }
}

// MARK: - Active Workout Row (for multiple active sessions)
struct ActiveWorkoutRow: View {
    let workout: Workout
    let onContinue: () -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme
    @State private var showDeleteConfirm = false
    @State private var showFinishConfirm = false
    @State private var toastMessage: String? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name ?? LocalizationKeys.Training.History.defaultName.localized)
                    .font(.headline)
                Text(workout.startTime, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(LocalizationKeys.Training.Active.continueButton.localized) { onContinue() }
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, theme.spacing.m)
                .padding(.vertical, 8)
                .background(theme.colors.success)
                .cornerRadius(8)
                .buttonStyle(PressableStyle())
            
            Button(LocalizationKeys.Training.Active.finish.localized) { showFinishConfirm = true }
            .font(.caption)
            .foregroundColor(theme.colors.success)
            .padding(.horizontal, theme.spacing.s)
            .padding(.vertical, 8)
            .background(theme.colors.success.opacity(0.1))
            .cornerRadius(8)
            
            Button(role: .destructive) { showDeleteConfirm = true } label: { Image(systemName: "trash") }
                .confirmationDialog(LocalizationKeys.Common.confirmDelete.localized, isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                    Button(LocalizationKeys.Common.delete.localized, role: .destructive) {
                        modelContext.delete(workout)
                        do { try modelContext.save() } catch { /* ignore */ }
                    }
                    Button(LocalizationKeys.Common.cancel.localized, role: .cancel) { }
                }
        }
        .padding()
        .background(theme.colors.cardBackground)
        .cornerRadius(12)
        .modifier(ToastModifier(message: $toastMessage))
        .confirmationDialog(LocalizationKeys.Training.Detail.finishWorkout.localized, isPresented: $showFinishConfirm, titleVisibility: .visible) {
            Button(LocalizationKeys.Common.yes.localized, role: .destructive) {
                workout.finishWorkout()
                do { try modelContext.save() } catch { toastMessage = error.localizedDescription; HapticManager.shared.notification(.error) }
            }
            Button(LocalizationKeys.Common.cancel.localized, role: .cancel) {}
        } message: {
            Text(LocalizationKeys.Training.Detail.finish.localized)
        }
    }
}

// MARK: - Active Workout Card
struct ActiveWorkoutCard: View {
    let workout: Workout
    let onTap: () -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme
    @EnvironmentObject var unitSettings: UnitSettings
    @State private var currentTime = Date()
    @State private var showFinishConfirm = false
    @State private var toastMessage: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with time info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizationKeys.Training.Active.title.localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(workout.name ?? LocalizationKeys.Training.History.defaultName.localized)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(timeRangeText)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            
            // Quick stats
            HStack(spacing: 20) {
                StatItem(title: LocalizationKeys.Training.Stats.parts.localized, value: "\(workout.parts.count)")
                StatItem(title: LocalizationKeys.Training.Stats.sets.localized, value: "\(workout.totalSets)")
                StatItem(title: LocalizationKeys.Training.Stats.volume.localized, value: UnitsFormatter.formatVolume(kg: workout.totalVolume, system: unitSettings.unitSystem))
            }
            
            // Actions
            HStack(spacing: theme.spacing.m) {
                Button(LocalizationKeys.Training.Active.continueButton.localized) {
                    onTap()
                    HapticManager.shared.impact(.light)
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(theme.spacing.m)
                .background(theme.colors.success)
                .cornerRadius(12)
                .buttonStyle(PressableStyle())
                .accessibilityLabel(LocalizationKeys.Training.Active.continueButton.localized)
                
                Button(LocalizationKeys.Training.Active.finish.localized) { showFinishConfirm = true }
                .font(.headline)
                .foregroundColor(theme.colors.success)
                .frame(maxWidth: .infinity)
                .padding(theme.spacing.m)
                .background(theme.colors.success.opacity(0.1))
                .cornerRadius(12)
                .buttonStyle(PressableStyle())
                .accessibilityLabel(LocalizationKeys.Training.Active.finish.localized)
            }
        }
        .padding(theme.spacing.m)
        .background(theme.colors.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.colors.accent, lineWidth: 2)
        )
        .cornerRadius(12)
        .onAppear { currentTime = Date() }
        .modifier(ToastModifier(message: $toastMessage))
        .confirmationDialog(LocalizationKeys.Training.Detail.finishWorkout.localized, isPresented: $showFinishConfirm, titleVisibility: .visible) {
            Button(LocalizationKeys.Common.yes.localized, role: .destructive) {
                workout.finishWorkout()
                do { try modelContext.save() } catch { toastMessage = error.localizedDescription; HapticManager.shared.notification(.error) }
                HapticManager.shared.impact(.light)
            }
            Button(LocalizationKeys.Common.cancel.localized, role: .cancel) {}
        } message: {
            Text(LocalizationKeys.Training.Detail.finish.localized)
        }
    }
    
    private var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let start = formatter.string(from: workout.startTime)
        if let end = workout.endTime { return "\(start) - \(formatter.string(from: end))" }
        return start
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
