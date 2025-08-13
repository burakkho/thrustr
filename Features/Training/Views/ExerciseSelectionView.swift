import SwiftUI
import SwiftData

// MARK: - Exercise Selection View
struct ExerciseSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var exercises: [Exercise]
    
    let workoutPart: WorkoutPart?
    let onExerciseSelected: (Exercise) -> Void
    
    @State private var searchText = ""
    @State private var debouncedSearchText = ""
    @State private var searchDebounceWork: DispatchWorkItem? = nil
    @State private var selectedPartType: WorkoutPartType? = nil
    @State private var selectedSegment: ExercisePickerSegment = .all
    @State private var recentIds: [UUID] = []

    enum ExercisePickerSegment: Int, CaseIterable {
        case all = 0, favorites = 1, recent = 2
        var title: String {
            switch self {
            case .all: return LocalizationKeys.Training.Exercise.all.localized
            case .favorites: return LocalizationKeys.Nutrition.Favorites.favorites.localized
            case .recent: return LocalizationKeys.Nutrition.Favorites.recent.localized
            }
        }
    }

    private var availablePartTypes: [WorkoutPartType] {
        WorkoutPartType.allCases.filter { partType in
            let allowed = Set(partType.suggestedExerciseCategories.map { $0.rawValue })
            return exercises.contains { $0.isActive && allowed.contains($0.category) }
        }
    }
    
    var filteredExercises: [Exercise] {
        var result = exercises.filter { $0.isActive }

        // Segment filter
        switch selectedSegment {
        case .favorites:
            result = result.filter { $0.isFavorite }
        case .recent:
            let setIds = Set(recentIds)
            result = result.filter { setIds.contains($0.id) }
        case .all:
            break
        }

        if let partType = selectedPartType {
            let allowed = Set(partType.suggestedExerciseCategories.map { $0.rawValue })
            result = result.filter { allowed.contains($0.category) }
        }

        if !debouncedSearchText.isEmpty {
            result = result.filter { exercise in
                exercise.nameTR.localizedCaseInsensitiveContains(debouncedSearchText) ||
                exercise.nameEN.localizedCaseInsensitiveContains(debouncedSearchText)
            }
        }

        return result.sorted { $0.nameTR < $1.nameTR }
    }

    private var recentExercises: [Exercise] {
        let setIds = Set(recentIds)
        return exercises.filter { setIds.contains($0.id) && $0.isActive }
            .sorted { $0.nameTR < $1.nameTR }
    }

    private var mainExercisesExcludingRecent: [Exercise] {
        guard !recentIds.isEmpty else { return filteredExercises }
        let recentIdSet = Set(recentIds)
        return filteredExercises.filter { !recentIdSet.contains($0.id) }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header (aligned with Add Part sheet style)
                VStack(spacing: 8) {
                    Text(LocalizationKeys.Training.Exercise.title.localized)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text(LocalizationKeys.Training.Exercise.emptySubtitle.localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)

                // Segments
                Picker("", selection: $selectedSegment) {
                    Text(ExercisePickerSegment.all.title).tag(ExercisePickerSegment.all)
                    Text(ExercisePickerSegment.favorites.title).tag(ExercisePickerSegment.favorites)
                    Text(ExercisePickerSegment.recent.title).tag(ExercisePickerSegment.recent)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .accessibilityLabel("Egzersiz filtreleri")

                // Search bar
                 SearchBar(text: $searchText, onSubmit: { debouncedSearchText = searchText })
                    .padding(.horizontal)
                    .padding(.top, 12)
                
                // Removed category/part filters for simplicity
                
                // Exercise list
                ScrollView {
                    LazyVStack(spacing: 8) {
                        // Recent section on top
                        if !recentIds.isEmpty {
                            Section {
                                ForEach(recentExercises.prefix(8)) { exercise in
                                    ExerciseRow(exercise: exercise) { selectExercise(exercise) }
                                }
                            } header: {
                                Text(LocalizationKeys.Nutrition.Favorites.recent.localized)
                                    .font(.headline)
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                            }
                        }

                        // All filtered list
                        ForEach(mainExercisesExcludingRecent) { exercise in
                            ExerciseRow(exercise: exercise) { selectExercise(exercise) }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                
                Spacer()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                 ToolbarItem(placement: .navigationBarLeading) {
                     Button(LocalizationKeys.Training.Exercise.cancel.localized) {
                         dismiss()
                     }
                     .accessibilityLabel(LocalizationKeys.Training.Exercise.cancel.localized)
                 }
                 // Trailing "Özel Ekle" butonu henüz uygulanmadığından gizlendi
            }
        }
        .onAppear {
            // Varsayılan olarak geçerli bölüm türünü seçili getir (varsa)
            selectedPartType = workoutPart?.workoutPartType
            // Load recent from UserDefaults
            if let data = UserDefaults.standard.array(forKey: "training.recent.exercises") as? [String] {
                recentIds = data.compactMap { UUID(uuidString: $0) }
            }
            debouncedSearchText = searchText
        }
        .onChange(of: searchText) { _, newValue in
            // debounce 300ms
            searchDebounceWork?.cancel()
            let task = DispatchWorkItem { debouncedSearchText = newValue }
            searchDebounceWork = task
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
        }
    }
    
    private func selectExercise(_ exercise: Exercise) {
        onExerciseSelected(exercise)
        // Track recent (cap 20)
        var current = recentIds
        current.removeAll { $0 == exercise.id }
        current.insert(exercise.id, at: 0)
        recentIds = Array(current.prefix(20))
        UserDefaults.standard.set(recentIds.map { $0.uuidString }, forKey: "training.recent.exercises")
        dismiss()
    }
            }

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    var onSubmit: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(LocalizationKeys.Training.Exercise.searchPlaceholder.localized, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .submitLabel(.search)
                .onSubmit { onSubmit?() }
                .accessibilityLabel(LocalizationKeys.Training.Exercise.searchPlaceholder.localized)
            
            if !text.isEmpty {
                Button(LocalizationKeys.Training.Exercise.clear.localized) {
                    text = ""
                    onSubmit?()
                }
                .foregroundColor(.gray)
                .font(.caption)
                .accessibilityLabel(LocalizationKeys.Training.Exercise.clear.localized)
            }
        }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.borderPrimary, lineWidth: 1)
            )
            .cornerRadius(10)
    }
}

// MARK: - Part Type Filter View
struct PartTypeFilterView: View {
    @Binding var selectedPartType: WorkoutPartType?
    let availablePartTypes: [WorkoutPartType]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                 CategoryChip(
                    title: LocalizationKeys.Training.Exercise.all.localized,
                    icon: "list.bullet",
                    isSelected: selectedPartType == nil
                ) {
                    selectedPartType = nil
                }
                
                ForEach(availablePartTypes, id: \.self) { partType in
                    CategoryChip(
                        title: partType.displayName,
                        icon: partType.icon,
                        isSelected: selectedPartType == partType
                    ) {
                        selectedPartType = selectedPartType == partType ? nil : partType
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                 Image(systemName: icon)
                    .font(.caption)
                    .accessibilityLabel(title)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, theme.spacing.m)
            .padding(.vertical, theme.spacing.s)
            .background(isSelected ? theme.colors.accent : theme.colors.backgroundSecondary)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Exercise Row
struct ExerciseRow: View {
    let exercise: Exercise
    let action: () -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme
    
    var partType: WorkoutPartType {
        WorkoutPartType.from(rawOrLegacy: exercise.category)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: partType.icon)
                .font(.title2)
                .foregroundColor(partType.color)
                .frame(width: 30)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.nameTR)
                    .font(.headline)
                    .foregroundColor(.primary)

                if !exercise.equipment.isEmpty {
                    EquipmentTags(equipment: exercise.equipment)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if exercise.supportsWeight {
                    InputTypeIcon(icon: "scalemass", color: .blue)
                }
                if exercise.supportsTime {
                    InputTypeIcon(icon: "timer", color: .orange)
                }
                if exercise.supportsDistance {
                    InputTypeIcon(icon: "ruler", color: .green)
                }
            }

            // Favorite toggle (bağımsız dokunma hedefi)
            Button(action: {
                exercise.isFavorite.toggle()
                do { try modelContext.save() } catch { /* ignore */ }
            }) {
                Image(systemName: exercise.isFavorite ? "heart.fill" : "heart")
                    .foregroundColor(.red)
            }
            .accessibilityLabel(exercise.isFavorite ? LocalizationKeys.Common.delete.localized : LocalizationKeys.Common.add.localized)
        }
        .padding(theme.spacing.m)
        .background(theme.colors.cardBackground)
            .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(partType.color.opacity(0.2), lineWidth: 2)
        )
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture { action() }
    }
}

// MARK: - Equipment Tags
struct EquipmentTags: View {
    let equipment: String
    
    var equipmentList: [String] {
        equipment.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(equipmentList.prefix(2), id: \.self) { item in
                Text(item)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5))
                    .cornerRadius(4)
            }
            
            if equipmentList.count > 2 {
                Text("+\(equipmentList.count - 2)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Input Type Icon
struct InputTypeIcon: View {
    let icon: String
    let color: Color
    
    var body: some View {
        Image(systemName: icon)
            .font(.caption)
            .foregroundColor(color)
    }
}

// MARK: - Empty Exercise State
struct EmptyExerciseState: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            if searchText.isEmpty {
                Text(LocalizationKeys.Training.Exercise.emptyTitle.localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(LocalizationKeys.Training.Exercise.emptySubtitle.localized)
                    .foregroundColor(.secondary)
            } else {
                Text(String(format: LocalizationKeys.Training.Exercise.emptySearchTitle.localized, searchText))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(LocalizationKeys.Training.Exercise.emptySearchSubtitle.localized)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 60)
    }
}

#Preview {
    ExerciseSelectionView(
        workoutPart: nil,
        onExerciseSelected: { _ in }
    )
    .modelContainer(for: [Exercise.self, Workout.self, WorkoutPart.self, ExerciseSet.self], inMemory: true)
}

