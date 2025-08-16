import SwiftUI
import SwiftData

// MARK: - Workout Templates View
struct WorkoutTemplatesView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Query private var allWorkouts: [Workout]
    
    private var programTemplates: [Workout] {
        allWorkouts.filter { $0.isTemplate }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Programs section (templates)
                Section(header: Text(LocalizationKeys.Training.Templates.programsHeader.localized)) {
                    ForEach(programTemplates, id: \.id) { pgm in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(pgm.name ?? LocalizationKeys.Training.History.defaultName.localized)
                                    .font(.headline)
                                Text("\(pgm.parts.count) \(LocalizationKeys.Training.Stats.parts.localized)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    if programTemplates.isEmpty {
                        Text(LocalizationKeys.Training.Templates.emptyPrograms.localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(LocalizationKeys.Training.Templates.title.localized)
        }
    }
}

// MARK: - Preview
#Preview {
    WorkoutTemplatesView()
        .modelContainer(for: [Workout.self], inMemory: true)
}