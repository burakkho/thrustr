import SwiftUI
import SwiftData

// Import Exercise extensions for localizedName support

// MARK: - Exercise Library View
struct ExerciseLibraryView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query private var allExercises: [Exercise]
    @Binding var selectedExercises: [LiftExercise]
    @Binding var isPresented: Bool
    
    @State private var searchText = ""
    @State private var selectedForAddition: Set<UUID> = []
    @State private var currentPage = 1
    @State private var itemsPerPage = 20
    
    private var filteredExercises: [Exercise] {
        let filtered: [Exercise]
        
        if searchText.isEmpty {
            filtered = allExercises
        } else {
            filtered = allExercises.filter { exercise in
                exercise.nameEN.localizedCaseInsensitiveContains(searchText) ||
                exercise.nameTR.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        let totalItems = currentPage * itemsPerPage
        return Array(filtered.prefix(totalItems))
    }
    
    private var hasMoreItems: Bool {
        let baseData = searchText.isEmpty ? allExercises : allExercises.filter { exercise in
            exercise.nameEN.localizedCaseInsensitiveContains(searchText) ||
            exercise.nameTR.localizedCaseInsensitiveContains(searchText)
        }
        return baseData.count > filteredExercises.count
    }
    
    private var popularExercises: [Exercise] {
        // Return some popular exercises if search is empty
        let popularNames = ["Bench Press", "Squat", "Deadlift", "Pull Up", "Overhead Press", "Barbell Row"]
        return allExercises.filter { popularNames.contains($0.nameEN) }
    }
    
    private var exercisesToShow: [Exercise] {
        if searchText.isEmpty {
            // When no search, show popular exercises first, then others
            let popular = popularExercises
            let others = allExercises.filter { exercise in
                !popularNames.contains(exercise.nameEN)
            }.prefix(44) // 50 - 6 popular = 44 others
            return Array(popular + others)
        } else {
            // When searching, show all filtered results
            return filteredExercises
        }
    }
    
    private var popularNames: [String] {
        ["Bench Press", "Squat", "Deadlift", "Pull Up", "Overhead Press", "Barbell Row"]
    }
    
    private var alreadySelectedIds: Set<UUID> {
        Set(selectedExercises.map { $0.exerciseId })
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search header
                searchHeaderSection
                
                // Exercise list
                exerciseListSection
                
                // Bottom action
                if !selectedForAddition.isEmpty {
                    bottomActionSection
                }
            }
            .navigationTitle("training.exercise.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                    .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
    }
    
    // MARK: - Search Header Section
    private var searchHeaderSection: some View {
        VStack(spacing: theme.spacing.m) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(theme.colors.textSecondary)
                
                TextField("training.exercise.searchPlaceholder".localized, text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(theme.typography.body)
                    .onChange(of: searchText) { _, _ in
                        resetPagination()
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
            }
            .padding()
            .background(theme.colors.backgroundSecondary)
            .cornerRadius(theme.radius.m)
            
            // Selection counter
            if !selectedForAddition.isEmpty {
                HStack {
                    Text("Selected: \(selectedForAddition.count) exercises")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.accent)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(theme.colors.backgroundPrimary)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(theme.colors.textSecondary)
                .opacity(0.2),
            alignment: .bottom
        )
    }
    
    // MARK: - Exercise List Section
    private var exerciseListSection: some View {
        ScrollView {
            LazyVStack(spacing: theme.spacing.s) {
                // All exercises (no duplicates)
                allExercisesSection
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    

    
    // MARK: - All Exercises Section  
    private var allExercisesSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            if !searchText.isEmpty {
                HStack {
                    Text("Search Results")
                        .font(theme.typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Spacer()
                    
                    Text("\(exercisesToShow.count) exercises")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
                .padding(.horizontal)
            }
            
            ForEach(exercisesToShow, id: \.id) { exercise in
                ExerciseSelectionRow(
                    exercise: exercise,
                    isSelected: selectedForAddition.contains(exercise.id),
                    isAlreadyAdded: alreadySelectedIds.contains(exercise.id),
                    onToggle: {
                        toggleExerciseSelection(exercise)
                    }
                )
            }
            
            // Load More Button
            if hasMoreItems {
                LoadMoreButton {
                    loadMoreExercises()
                }
                .padding(.horizontal)
            }
            
            // Show message if no results
            if exercisesToShow.isEmpty && !searchText.isEmpty {
                VStack(spacing: theme.spacing.m) {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(theme.colors.textSecondary)
                    
                    Text("training.exercise.empty.searchTitle".localized)
                        .font(theme.typography.headline)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text("training.exercise.empty.searchSubtitle".localized)
                        .font(theme.typography.body)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, theme.spacing.xl)
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Bottom Action Section
    private var bottomActionSection: some View {
        VStack(spacing: theme.spacing.m) {
            Button(action: addSelectedExercises) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    Text("Add Selected (\(selectedForAddition.count))")
                        .font(theme.typography.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacing.m)
                .background(theme.colors.accent)
                .cornerRadius(theme.radius.m)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(theme.colors.backgroundPrimary)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(theme.colors.textSecondary)
                .opacity(0.2),
            alignment: .top
        )
    }
    
    // MARK: - Actions
    private func toggleExerciseSelection(_ exercise: Exercise) {
        // Don't allow selection if already added
        if alreadySelectedIds.contains(exercise.id) {
            return
        }
        
        if selectedForAddition.contains(exercise.id) {
            selectedForAddition.remove(exercise.id)
        } else {
            selectedForAddition.insert(exercise.id)
        }
    }
    
    private func loadMoreExercises() {
        currentPage += 1
    }
    
    private func resetPagination() {
        currentPage = 1
    }
    
    private func addSelectedExercises() {
        let exercisesToAdd = allExercises.filter { selectedForAddition.contains($0.id) }
        let startingIndex = selectedExercises.count
        
        for (index, exercise) in exercisesToAdd.enumerated() {
            let liftExercise = LiftExercise(
                exerciseId: exercise.id,
                exerciseName: exercise.nameEN,
                orderIndex: startingIndex + index
            )
            selectedExercises.append(liftExercise)
        }
        
        selectedForAddition.removeAll()
        dismiss()
    }
}

// MARK: - Exercise Selection Row Component
struct ExerciseSelectionRow: View {
    @Environment(\.theme) private var theme
    
    let exercise: Exercise
    let isSelected: Bool
    let isAlreadyAdded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: theme.spacing.m) {
                // Checkbox
                Image(systemName: checkboxIcon)
                    .font(.title2)
                    .foregroundColor(checkboxColor)
                
                // Exercise info
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.nameEN)
                        .font(theme.typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(textColor)
                    
                    if let category = exerciseCategoryDisplay {
                        Text(category)
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
                
                Spacer()
                
                if isAlreadyAdded {
                    Text("Added")
                        .font(theme.typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.success)
                        .padding(.horizontal, theme.spacing.s)
                        .padding(.vertical, 4)
                        .background(theme.colors.success.opacity(0.1))
                        .cornerRadius(theme.radius.s)
                }
            }
            .padding()
            .background(rowBackgroundColor)
            .cornerRadius(theme.radius.m)
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.m)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isAlreadyAdded)
        .padding(.horizontal)
    }
    
    private var checkboxIcon: String {
        if isAlreadyAdded {
            return "checkmark.circle.fill"
        } else if isSelected {
            return "checkmark.circle.fill"
        } else {
            return "circle"
        }
    }
    
    private var checkboxColor: Color {
        if isAlreadyAdded {
            return theme.colors.success
        } else if isSelected {
            return theme.colors.accent
        } else {
            return theme.colors.textSecondary
        }
    }
    
    private var textColor: Color {
        isAlreadyAdded ? theme.colors.textSecondary : theme.colors.textPrimary
    }
    
    private var rowBackgroundColor: Color {
        if isAlreadyAdded {
            return theme.colors.backgroundSecondary
        } else if isSelected {
            return theme.colors.accent.opacity(0.1)
        } else {
            return theme.colors.cardBackground
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return theme.colors.accent.opacity(0.3)
        } else {
            return Color.clear
        }
    }
    
    private var exerciseCategoryDisplay: String? {
        // Simple category mapping
        switch exercise.category.lowercased() {
        case "push": return "Push • \(exercise.equipment.capitalized)"
        case "pull": return "Pull • \(exercise.equipment.capitalized)"
        case "legs": return "Legs • \(exercise.equipment.capitalized)"
        case "core": return "Core • \(exercise.equipment.capitalized)"
        case "strength": return "Strength • \(exercise.equipment.capitalized)"
        case "isolation": return "Isolation • \(exercise.equipment.capitalized)"
        default: return exercise.equipment.capitalized
        }
    }
}

// MARK: - Load More Button Component
struct LoadMoreButton: View {
    @Environment(\.theme) private var theme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "arrow.down.circle")
                Text("Load More")
                    .fontWeight(.medium)
            }
            .foregroundColor(theme.colors.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacing.m)
            .background(theme.colors.accent.opacity(0.1))
            .cornerRadius(theme.radius.m)
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.m)
                    .stroke(theme.colors.accent.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var sampleExercises: [LiftExercise] = []
    @Previewable @State var isPresented = true
    
    return ExerciseLibraryView(
        selectedExercises: $sampleExercises,
        isPresented: $isPresented
    )
}