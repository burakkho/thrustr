import SwiftUI
import SwiftData

struct ExerciseSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.nameEN) private var exercises: [Exercise]
    
    let onSelect: (Exercise) -> Void
    
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory? = nil
    @State private var selectedEquipment: String? = nil
    
    private var filteredExercises: [Exercise] {
        exercises.filter { exercise in
            let matchesSearch = searchText.isEmpty || 
                exercise.nameEN.localizedCaseInsensitiveContains(searchText) ||
                exercise.nameTR.localizedCaseInsensitiveContains(searchText)
            
            let matchesCategory = selectedCategory == nil || 
                ExerciseCategory(rawValue: exercise.category) == selectedCategory
            
            let matchesEquipment = selectedEquipment == nil || 
                exercise.equipment == selectedEquipment
            
            return matchesSearch && matchesCategory && matchesEquipment
        }
    }
    
    private var categories: [ExerciseCategory] {
        [.strength, .push, .pull, .legs, .core, .isolation]
    }
    
    private var equipmentTypes: [String] {
        Array(Set(exercises.map { $0.equipment })).sorted()
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(theme.colors.textSecondary)
                    
                    TextField("Search exercises...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(theme.colors.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, theme.spacing.m)
                .padding(.vertical, theme.spacing.s)
                .background(theme.colors.backgroundSecondary)
                .cornerRadius(theme.radius.m)
                .padding()
                
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: theme.spacing.s) {
                        FilterChip(
                            title: "All",
                            isSelected: selectedCategory == nil,
                            action: { selectedCategory = nil }
                        )
                        
                        ForEach(categories, id: \.self) { category in
                            FilterChip(
                                title: category.displayName,
                                isSelected: selectedCategory == category,
                                action: { 
                                    selectedCategory = selectedCategory == category ? nil : category
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, theme.spacing.s)
                
                // Exercise List
                if filteredExercises.isEmpty {
                    VStack(spacing: theme.spacing.m) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(theme.colors.textSecondary)
                        
                        Text("No exercises found")
                            .font(theme.typography.headline)
                            .foregroundColor(theme.colors.textSecondary)
                        
                        Text("Try adjusting your filters")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredExercises) { exercise in
                                ExerciseRow(exercise: exercise) {
                                    onSelect(exercise)
                                    dismiss()
                                }
                                
                                if exercise.id != filteredExercises.last?.id {
                                    Divider()
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Exercise Row
struct ExerciseRow: View {
    @Environment(\.theme) private var theme
    let exercise: Exercise
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.nameEN)
                        .font(theme.typography.headline)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    HStack(spacing: theme.spacing.s) {
                        if !exercise.equipment.isEmpty {
                            Label(exercise.equipment, systemImage: "dumbbell")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                        
                        if let category = ExerciseCategory(rawValue: exercise.category) {
                            Label(category.displayName, systemImage: category.icon)
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                // Supported tracking types
                HStack(spacing: 4) {
                    if exercise.supportsWeight {
                        Image(systemName: "scalemass")
                            .font(.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    if exercise.supportsReps {
                        Image(systemName: "repeat")
                            .font(.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    if exercise.supportsTime {
                        Image(systemName: "timer")
                            .font(.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    if exercise.supportsDistance {
                        Image(systemName: "location")
                            .font(.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    @Environment(\.theme) private var theme
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(theme.typography.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : theme.colors.textPrimary)
                .padding(.horizontal, theme.spacing.m)
                .padding(.vertical, theme.spacing.s)
                .background(isSelected ? theme.colors.accent : theme.colors.backgroundSecondary)
                .cornerRadius(theme.radius.m)
        }
    }
}