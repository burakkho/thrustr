import SwiftUI
import SwiftData

// MARK: - Main Training View
struct TrainingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var workouts: [Workout]
    @Query private var exercises: [Exercise]
    
    @State private var showingNewWorkout = false
    @State private var selectedTab = 0
    @State private var workoutToShow: Workout?
    @State private var showWorkoutDetail = false
    
    private var hasActiveWorkout: Bool {
        workouts.contains { $0.isActive }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segment Control
                Picker(LocalizationKeys.Training.title.localized, selection: $selectedTab) {
                    Text(LocalizationKeys.Training.history.localized).tag(0)
                    Text(LocalizationKeys.Training.active.localized).tag(1)
                    Text(LocalizationKeys.Training.templates.localized).tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected tab
                switch selectedTab {
                case 0:
                    WorkoutHistoryView(workouts: workouts)
                case 1:
                    ActiveWorkoutView(onWorkoutTap: { workout in
                        workoutToShow = workout
                        showWorkoutDetail = true
                    })
                case 2:
                    WorkoutTemplatesView(onSelectWOD: { template in
                        // Create workout with Metcon part prefilled with selected WOD
                        let workout = Workout(name: template.name)
                        let part = workout.addPart(name: LocalizationKeys.Training.Part.metcon.localized, type: .metcon)
                        part.wodTemplateId = template.id
                        modelContext.insert(workout)
                        do { try modelContext.save() } catch { /* ignore for now */ }
                        workoutToShow = workout
                        selectedTab = 1
                    }, onSelectWODManual: { template in
                        // Create workout and open detail for manual builder
                        let workout = Workout(name: template.name)
                        _ = workout.addPart(name: LocalizationKeys.Training.Part.metcon.localized, type: .metcon)
                        modelContext.insert(workout)
                        do { try modelContext.save() } catch { /* ignore for now */ }
                        workoutToShow = workout
                        selectedTab = 1
                    }, onSelectProgram: { template in
                        // Duplicate template workout structure to a new active workout
                        let newWorkout = Workout(name: template.name ?? LocalizationKeys.Training.History.defaultName.localized)
                        for (idx, part) in template.parts.sorted(by: { $0.orderIndex < $1.orderIndex }).enumerated() {
                            let newPart = WorkoutPart(name: part.name, type: WorkoutPartType.from(rawOrLegacy: part.type), orderIndex: idx)
                            newPart.workout = newWorkout
                            // Copy structure: for each exercise, create one placeholder set mirroring last completed values (if any)
                            let grouped: [UUID?: [ExerciseSet]] = Dictionary(grouping: part.exerciseSets, by: { $0.exercise?.id })
                            for (_, sets) in grouped {
                                guard let exercise = sets.first?.exercise else { continue }
                                let completed = sets.compactMap { $0.isCompleted ? $0 : nil }
                                if let last = completed.last {
                                    let copy = ExerciseSet(setNumber: 1, weight: last.weight, reps: last.reps, isCompleted: false)
                                    copy.exercise = exercise
                                    copy.workoutPart = newPart
                                }
                            }
                            newWorkout.parts.append(newPart)
                        }
                        modelContext.insert(newWorkout)
                        do { try modelContext.save() } catch { /* ignore */ }
                        workoutToShow = newWorkout
                        selectedTab = 1
                    })
                default:
                    EmptyView()
                }
            }
            .navigationTitle(LocalizationKeys.Training.title.localized)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if let existing = workouts.first(where: { $0.isActive }) {
                            workoutToShow = existing
                        } else {
                            let newWorkout = Workout(name: LocalizationKeys.Training.History.defaultName.localized)
                            modelContext.insert(newWorkout)
                            workoutToShow = newWorkout
                        }
                        // Switch to Active tab when a workout starts
                        selectedTab = 1
                    }) {
                        Image(systemName: "plus")
                            .font(.headline)
                            .accessibilityLabel(LocalizationKeys.Common.add.localized)
                    }
                }
            }
            .fullScreenCover(item: $workoutToShow) { workout in
                WorkoutDetailView(workout: workout)
            }
            .onAppear {
                if hasActiveWorkout { selectedTab = 1 }
            }
        }
    }
}

// MARK: - Workout History View
struct WorkoutHistoryView: View {
    let workouts: [Workout]
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @State private var showAll: Bool = false
    
    private var displayedWorkouts: [Workout] {
        showAll ? completedWorkouts : Array(completedWorkouts.prefix(7))
    }
    
    var completedWorkouts: [Workout] {
        workouts.filter { $0.isCompleted }.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: theme.spacing.m) {
                if completedWorkouts.isEmpty {
                    // Empty state
                    VStack(spacing: theme.spacing.m) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 50))
                            .foregroundColor(theme.colors.textSecondary)
                        
                        Text(LocalizationKeys.Training.History.emptyTitle.localized)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(LocalizationKeys.Training.History.emptySubtitle.localized)
                            .foregroundColor(theme.colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 100)
                } else {
                    ForEach(displayedWorkouts) { workout in
                        WorkoutHistoryCard(workout: workout)
                            .contextMenu {
                                Button(LocalizationKeys.Training.History.repeat.localized) {
                                    repeatWorkout(workout)
                                }
                            }
                    }
                    if !showAll && completedWorkouts.count > 7 {
                        Button(LocalizationKeys.Training.History.seeMore.localized) { showAll = true }
                            .font(.subheadline)
                            .foregroundColor(theme.colors.accent)
                    }
                }
            }
            .padding(theme.spacing.m)
        }
    }

    private func repeatWorkout(_ template: Workout) {
        let newWorkout = Workout(name: template.name)
        // Copy parts and exercises
        for (idx, part) in template.parts.sorted(by: { $0.orderIndex < $1.orderIndex }).enumerated() {
            let newPart = WorkoutPart(name: part.name, type: WorkoutPartType.from(rawOrLegacy: part.type), orderIndex: idx)
            newPart.workout = newWorkout
            // copy only completed sets structure (exercise and last values), not results
            let grouped: [UUID?: [ExerciseSet]] = Dictionary(grouping: part.exerciseSets, by: { $0.exercise?.id })
            for (_, sets) in grouped {
                guard let exercise = sets.first?.exercise else { continue }
                let completed = sets.compactMap { $0.isCompleted ? $0 : nil }
                if let last = completed.last {
                    let copy = ExerciseSet(setNumber: 1, weight: last.weight, reps: last.reps, isCompleted: false)
                    copy.exercise = exercise
                    copy.workoutPart = newPart
                }
            }
            newWorkout.parts.append(newPart)
        }
        modelContext.insert(newWorkout)
        do { try modelContext.save() } catch { /* ignore */ }
    }
}

// MARK: - Workout History Card
struct WorkoutHistoryCard: View {
    let workout: Workout
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.name ?? LocalizationKeys.Training.History.defaultName.localized)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(workout.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(workout.totalSets) \(LocalizationKeys.Training.Stats.sets.localized.lowercased())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Parts summary
            HStack(spacing: 8) {
                ForEach(workout.parts.sorted(by: { $0.orderIndex < $1.orderIndex }), id: \.id) { part in
                    PartTypeChip(partType: WorkoutPartType.from(rawOrLegacy: part.type))
                }
                
                if workout.parts.isEmpty {
                    Text(LocalizationKeys.Training.History.noParts.localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Prominent stats: Volume + Duration
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "scalemass").foregroundColor(.blue)
                    Text("\(Int(workout.totalVolume)) kg").font(.subheadline).fontWeight(.semibold)
                }
                HStack(spacing: 6) {
                    Image(systemName: "clock").foregroundColor(.orange)
                    Text(durationText).font(.subheadline).fontWeight(.semibold)
                }
                Spacer()
            }
        }
        .padding(theme.spacing.m)
        .background(theme.colors.cardBackground)
        .cornerRadius(12)
    }

    private func formattedTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }

    private var durationText: String {
        guard let end = workout.endTime else { return "-" }
        let interval = end.timeIntervalSince(workout.startTime)
        let minutes = max(0, Int(interval) / 60)
        let hours = minutes / 60
        let mins = minutes % 60
        return hours > 0 ? "\(hours)sa \(mins)dk" : "\(mins)dk"
    }
}

// MARK: - Part Type Chip
struct PartTypeChip: View {
    let partType: WorkoutPartType
    @Environment(\.theme) private var theme
    
    var localizedDisplayName: String {
        switch partType {
        case .powerStrength:
            return LocalizationKeys.Training.Part.powerStrength.localized
        case .metcon:
            return LocalizationKeys.Training.Part.metcon.localized
        case .accessory:
            return LocalizationKeys.Training.Part.accessory.localized
        case .cardio:
            return LocalizationKeys.Training.Part.cardio.localized
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: partType.icon)
                .font(.caption)
            Text(localizedDisplayName)
                .font(.caption)
        }
        .padding(.horizontal, theme.spacing.s)
        .padding(.vertical, theme.spacing.xs)
        .background(partColor.opacity(0.2))
        .foregroundColor(partColor)
        .cornerRadius(8)
    }
    
    private var partColor: Color {
        switch partType {
        case .powerStrength: return .blue
        case .metcon: return .red
        case .accessory: return .green
        case .cardio: return .orange
        }
    }
}

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
                        ForEach(activeWorkouts.sorted(by: { $0.startTime > $1.startTime })) { workout in
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
            
            Button(LocalizationKeys.Training.Active.finish.localized) {
                workout.finishWorkout()
                do { try modelContext.save() } catch { /* optionally surface via parent */ }
            }
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
    }
}

// MARK: - Active Workout Card
struct ActiveWorkoutCard: View {
    let workout: Workout
    let onTap: () -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme
    @State private var currentTime = Date()
    @State private var showSaveErrorAlert = false
    @State private var saveErrorMessage = ""
    
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
                StatItem(title: LocalizationKeys.Training.Stats.volume.localized, value: "\(Int(workout.totalVolume))kg")
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
                
                Button(LocalizationKeys.Training.Active.finish.localized) {
                    workout.finishWorkout()
                    do { try modelContext.save() } catch {
                        saveErrorMessage = error.localizedDescription
                        showSaveErrorAlert = true
                    }
                    HapticManager.shared.impact(.light)
                }
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
        .alert(isPresented: $showSaveErrorAlert) {
            Alert(
                title: Text(LocalizationKeys.Common.error.localized),
                message: Text(saveErrorMessage),
                dismissButton: .default(Text(LocalizationKeys.Common.ok.localized))
            )
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

// MARK: - Workout Templates View
struct WorkoutTemplatesView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    let onSelectWOD: (WODTemplate) -> Void
    let onSelectWODManual: (WODTemplate) -> Void
    let onSelectProgram: (Workout) -> Void
    @State private var favoriteIds: Set<String> = []
    @Query private var allWorkouts: [Workout]
    @State private var previewWOD: WODTemplate? = nil
    
    private var favorites: [WODTemplate] {
        WODLookup.benchmark.filter { favoriteIds.contains($0.id.uuidString) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Programs section (templates)
                Section(header: Text("Programlar")) {
                    ForEach(programTemplates, id: \.id) { pgm in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(pgm.name ?? LocalizationKeys.Training.History.defaultName.localized).font(.headline)
                                Text("\(pgm.parts.count) \(LocalizationKeys.Training.Stats.parts.localized)")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Button(action: { onSelectProgram(pgm) }) {
                                Image(systemName: "chevron.right").foregroundColor(.secondary)
                            }
                        }
                    }
                    if programTemplates.isEmpty {
                        Text("Henüz program şablonu yok").font(.caption).foregroundColor(.secondary)
                    }
                }
                if !favorites.isEmpty {
                    Section(header: Text(LocalizationKeys.Training.WOD.favorites.localized)) {
                        ForEach(favorites) { wod in
                            wodRow(wod)
                        }
                    }
                }
                Section(header: Text(LocalizationKeys.Training.WOD.benchmarks.localized)) {
                    ForEach(WODLookup.benchmark) { wod in
                        wodRow(wod)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(LocalizationKeys.Training.Templates.title.localized)
            .onAppear { loadFavorites() }
            .sheet(item: $previewWOD) { wod in
                WODTemplatePreview(wod: wod, onStart: { onSelectWOD(wod) }, onManual: { onSelectWODManual(wod) })
            }
        }
    }
    
    @ViewBuilder
    private func wodRow(_ wod: WODTemplate) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(wod.name).font(.headline)
                Text(wod.description).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Button(action: { toggleFavorite(wod) }) {
                Image(systemName: favoriteIds.contains(wod.id.uuidString) ? "heart.fill" : "heart")
                    .foregroundColor(.red)
            }
            Button(action: { previewWOD = wod }) {
                Image(systemName: "chevron.right").foregroundColor(.secondary)
            }
        }
    }
    
    private func loadFavorites() {
        favoriteIds = Set(UserDefaults.standard.array(forKey: "training.favorite.wods") as? [String] ?? [])
    }
    
    private func toggleFavorite(_ wod: WODTemplate) {
        if favoriteIds.contains(wod.id.uuidString) {
            favoriteIds.remove(wod.id.uuidString)
        } else {
            favoriteIds.insert(wod.id.uuidString)
        }
        UserDefaults.standard.set(Array(favoriteIds), forKey: "training.favorite.wods")
    }
}

// MARK: - WOD Template Preview
private struct WODTemplatePreview: View {
    let wod: WODTemplate
    let onStart: () -> Void
    let onManual: () -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 12) {
                Text(wod.name).font(.title2).fontWeight(.bold)
                Text(wod.description).font(.subheadline)
                if !wod.movements.isEmpty {
                    Text("Hareketler").font(.headline)
                    ForEach(wod.movements, id: \.self) { mv in
                        HStack(spacing: 8) {
                            Image(systemName: "circle.fill").font(.system(size: 6)).foregroundColor(.secondary)
                            Text(mv).font(.caption)
                        }
                    }
                }
                Spacer()
                HStack(spacing: 12) {
                    Button(action: {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { onManual() }
                    }) {
                        Text("Manuel Oluştur")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.12))
                            .cornerRadius(10)
                    }
                    Button(action: {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { onStart() }
                    }) {
                        Text("Başlat")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
            .navigationTitle("WOD")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(LocalizationKeys.Common.close.localized) { dismiss() } } }
        }
    }
}

private extension WorkoutTemplatesView {
    var programTemplates: [Workout] {
        allWorkouts.filter { $0.isTemplate }.sorted { ($0.name ?? "") < ($1.name ?? "") }
    }
}

// MARK: - New Workout View
struct NewWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var workoutName = ""
    let onWorkoutCreated: (Workout) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text(LocalizationKeys.Training.New.title.localized)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(LocalizationKeys.Training.New.subtitle.localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Workout name
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizationKeys.Training.New.nameLabel.localized)
                        .font(.headline)
                    
                    TextField(LocalizationKeys.Training.New.namePlaceholder.localized, text: $workoutName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                
                // Quick start options
                VStack(spacing: 12) {
                    Text(LocalizationKeys.Training.New.quickStart.localized)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        QuickStartButton(
                            title: LocalizationKeys.Training.New.Empty.title.localized,
                            subtitle: LocalizationKeys.Training.New.Empty.subtitle.localized,
                            icon: "plus.circle.fill",
                            color: .blue
                        ) {
                            startEmptyWorkout()
                        }
                        
                        // Functional quick start removed in new part system
                        
                        QuickStartButton(
                            title: LocalizationKeys.Training.Part.cardio.localized,
                            subtitle: LocalizationKeys.Training.Part.cardioDesc.localized,
                            icon: "figure.run",
                            color: .orange
                        ) {
                            startCardioWorkout()
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationKeys.Training.New.cancel.localized) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func startEmptyWorkout() {
        let workout = Workout(name: workoutName.isEmpty ? LocalizationKeys.Training.History.defaultName.localized : workoutName)
        modelContext.insert(workout)
        do { try modelContext.save() } catch { /* ignore */ }
        
        dismiss()
        
        // Call the callback to show workout detail
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onWorkoutCreated(workout)
        }
    }
    
    // startFunctionalWorkout removed in new part system
    
    private func startCardioWorkout() {
        let workout = Workout(name: workoutName.isEmpty ? LocalizationKeys.Training.Part.cardio.localized : workoutName)
        
        // Add cardio part
        let _ = workout.addPart(name: LocalizationKeys.Training.Part.cardio.localized, type: .cardio)
        
        modelContext.insert(workout)
        do { try modelContext.save() } catch { /* ignore */ }
        
        dismiss()
        
        // Call the callback to show workout detail
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onWorkoutCreated(workout)
        }
    }
}

// MARK: - Quick Start Button
struct QuickStartButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
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
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TrainingView()
        .modelContainer(for: [Workout.self, Exercise.self], inMemory: true)
}

// MARK: - New Workout Flow
struct NewWorkoutFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let onComplete: (Workout) -> Void

    @State private var createdWorkout: Workout? = nil
    @State private var createdPart: WorkoutPart? = nil

    private func inferPartType(from exercise: Exercise) -> WorkoutPartType {
        ExerciseCategory(rawValue: exercise.category)?.toWorkoutPartType() ?? .powerStrength
    }

    var body: some View {
        NavigationStack {
            ExerciseSelectionView(workoutPart: createdPart) { exercise in
                if createdWorkout == nil {
                    let workout = Workout()
                    modelContext.insert(workout)
                    createdWorkout = workout

                    let type = inferPartType(from: exercise)
                    let part = workout.addPart(name: type.displayName, type: type)
                    createdPart = part
                    do { try modelContext.save() } catch { /* ignore */ }
                }

                if let workout = createdWorkout {
                    onComplete(workout)
                    dismiss()
                }
            }
            .navigationTitle("Egzersiz Ekle")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}
