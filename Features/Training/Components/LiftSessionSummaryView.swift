import SwiftUI
import SwiftData

struct LiftSessionSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(UnitSettings.self) private var unitSettings
    @Environment(HealthKitService.self) private var healthKitService

    let session: LiftSession
    let user: User
    let onDismiss: (() -> Void)?

    @State private var feeling: SessionFeeling = .good
    @State private var notes: String = ""
    @State private var showingShareSheet = false

    // Edit modals
    @State private var showingDurationEdit = false

    // Edit values
    @State private var editHours: Int = 0
    @State private var editMinutes: Int = 0
    @State private var editSeconds: Int = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.l) {
                    // Success Header
                    successHeader

                    // Main Stats
                    mainStatsSection

                    // Exercise Results Summary
                    exerciseResultsSection

                    // Personal Records (if any)
                    if !session.prsHit.isEmpty {
                        personalRecordsSection
                    }

                    // Feeling Selection
                    feelingSection

                    // Notes
                    notesSection

                    // Action Buttons
                    actionButtons
                }
                .padding(theme.spacing.m)
            }
            .navigationTitle("Workout Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let shareText = createShareText() {
                LiftShareSheet(items: [shareText])
            }
        }
        .sheet(isPresented: $showingDurationEdit) {
            LiftDurationEditSheet(
                hours: $editHours,
                minutes: $editMinutes,
                seconds: $editSeconds,
                onSave: saveDurationEdit,
                onCancel: { showingDurationEdit = false }
            )
        }
    }

    // MARK: - Success Header
    private var successHeader: some View {
        VStack(spacing: theme.spacing.m) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(theme.colors.success)
                .symbolRenderingMode(.hierarchical)

            Text("Congratulations!")
                .font(theme.typography.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)

            Text("Workout Completed!")
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
        }
        .padding(.vertical, theme.spacing.l)
    }

    // MARK: - Main Stats
    private var mainStatsSection: some View {
        VStack(spacing: theme.spacing.m) {
            HStack(spacing: theme.spacing.m) {
                LiftMainStatCard(
                    icon: "timer",
                    value: session.formattedDuration,
                    label: "Duration",
                    color: theme.colors.accent,
                    onEdit: {
                        initializeDurationEdit()
                        showingDurationEdit = true
                    }
                )

                LiftMainStatCard(
                    icon: "scalemass.fill",
                    value: UnitsFormatter.formatWeight(kg: session.totalVolume, system: unitSettings.unitSystem),
                    label: "Volume",
                    color: theme.colors.success,
                    onEdit: nil // Volume hesaplanır, edit edilmez
                )
            }

            HStack(spacing: theme.spacing.m) {
                LiftMainStatCard(
                    icon: "list.number",
                    value: "\(session.totalSets)",
                    label: "Sets",
                    color: theme.colors.warning,
                    onEdit: nil // Sets hesaplanır
                )

                LiftMainStatCard(
                    icon: "repeat",
                    value: "\(session.totalReps)",
                    label: "Reps",
                    color: theme.colors.error,
                    onEdit: nil // Reps hesaplanır
                )
            }
        }
    }

    // MARK: - Exercise Results
    private var exerciseResultsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Image(systemName: "list.clipboard.fill")
                    .foregroundColor(theme.colors.accent)
                Text("training.strength.exercise_summary".localized)
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
            }

            VStack(spacing: theme.spacing.s) {
                ForEach(session.exerciseResults ?? []) { result in
                    ExerciseResultRow(result: result, unitSettings: unitSettings)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Personal Records
    private var personalRecordsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(theme.colors.warning)
                Text("Personal Records!")
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.warning)
                Spacer()
            }

            VStack(spacing: theme.spacing.s) {
                ForEach(session.prsHit, id: \.self) { pr in
                    HStack {
                        Image(systemName: "trophy.fill")
                            .font(.caption)
                            .foregroundColor(theme.colors.warning)
                        Text(pr)
                            .font(theme.typography.body)
                            .foregroundColor(theme.colors.textPrimary)
                        Spacer()
                    }
                }
            }
        }
        .padding(theme.spacing.m)
        .background(theme.colors.warning.opacity(0.1))
        .cornerRadius(theme.radius.m)
    }

    // MARK: - Feeling Section
    private var feelingSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text("How do you feel?")
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)

            HStack(spacing: theme.spacing.s) {
                ForEach(SessionFeeling.allCases, id: \.self) { feelingOption in
                    Button(action: { feeling = feelingOption }) {
                        VStack(spacing: 4) {
                            Text(feelingOption.emoji)
                                .font(.title2)
                            Text(feelingOption.displayName)
                                .font(.caption2)
                                .fontWeight(feeling == feelingOption ? .semibold : .regular)
                        }
                        .foregroundColor(feeling == feelingOption ? .white : theme.colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, theme.spacing.s)
                        .background(
                            RoundedRectangle(cornerRadius: theme.radius.s)
                                .fill(feeling == feelingOption ? theme.colors.accent : theme.colors.backgroundSecondary)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            Text("Notes (Optional)")
                .font(theme.typography.body)
                .fontWeight(.medium)
                .foregroundColor(theme.colors.textPrimary)

            TextField("Add notes about your workout...", text: $notes, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(theme.spacing.m)
                .background(theme.colors.backgroundSecondary)
                .cornerRadius(theme.radius.m)
                .lineLimit(3...5)
        }
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: theme.spacing.m) {
            Button(action: saveSession) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                    Text("training.strength.save_workout".localized)
                        .font(theme.typography.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(theme.spacing.l)
                .background(theme.colors.accent)
                .cornerRadius(theme.radius.m)
            }

            Button(action: discardSession) {
                Text("Exit without saving")
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
        .padding(.vertical, theme.spacing.l)
    }

    // MARK: - Helper Methods
    private func saveSession() {
        // Update session with feeling and notes - convert to Int for LiftSession
        switch feeling {
        case .exhausted: session.feeling = 1
        case .tired: session.feeling = 2
        case .okay: session.feeling = 3
        case .good: session.feeling = 4
        case .great: session.feeling = 5
        }
        session.notes = notes.isEmpty ? nil : notes

        // Mark as completed if not already
        if !session.isCompleted {
            session.endDate = Date()
            session.isCompleted = true
        }

        // Update user stats with final values
        user.addLiftSession(
            duration: session.duration,
            volume: session.totalVolume,
            sets: session.totalSets,
            reps: session.totalReps
        )

        do {
            try modelContext.save()

            // Save to HealthKit
            Task {
                let success = await healthKitService.saveLiftWorkout(
                    duration: session.duration,
                    startDate: session.startDate,
                    endDate: session.endDate ?? Date(),
                    totalVolume: session.totalVolume
                )

                if success {
                    Logger.info("Lift workout successfully synced to HealthKit")
                }
            }

            // Dismiss with callback
            if let onDismiss = onDismiss {
                onDismiss()
            } else {
                dismiss()
            }
        } catch {
            Logger.error("Failed to save lift session: \(error)")
        }
    }

    private func discardSession() {
        if let onDismiss = onDismiss {
            onDismiss()
        } else {
            dismiss()
        }
    }

    private func createShareText() -> String? {
        var text = "💪 Workout Completed!\n\n"
        text += "⏱️ Duration: \(session.formattedDuration)\n"
        text += "📊 Volume: \(UnitsFormatter.formatWeight(kg: session.totalVolume, system: unitSettings.unitSystem))\n"
        text += "🔢 Sets: \(session.totalSets)\n"
        text += "🔄 Reps: \(session.totalReps)\n"

        if !session.prsHit.isEmpty {
            text += "\n🏆 Personal Records:\n"
            for pr in session.prsHit {
                text += "• \(pr)\n"
            }
        }

        text += "\n#Thrustr #Lifting #Strength"

        return text
    }

    // MARK: - Edit Methods
    private func initializeDurationEdit() {
        let totalSeconds = Int(session.duration)
        editHours = totalSeconds / 3600
        editMinutes = (totalSeconds % 3600) / 60
        editSeconds = totalSeconds % 60
    }

    private func saveDurationEdit() {
        let newDuration = TimeInterval(editHours * 3600 + editMinutes * 60 + editSeconds)

        if newDuration != session.duration {
            // Duration is computed from startDate and endDate, so we adjust endDate
            let newEndDate = session.startDate.addingTimeInterval(newDuration)
            session.endDate = newEndDate
        }

        showingDurationEdit = false
    }
}

// MARK: - Supporting Components
// Note: Components are defined in LiftSessionView.swift to avoid duplication

#Preview {
    // This would need mock data for preview
    Text("LiftSessionSummaryView Preview")
        .environment(\.theme, DefaultLightTheme())
}