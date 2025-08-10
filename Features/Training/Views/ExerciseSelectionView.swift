import SwiftUI
import SwiftData

// MARK: - Exercise Selection View
struct ExerciseSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var exercises: [Exercise]
    
    let workoutPart: WorkoutPart
    let onExerciseSelected: (Exercise) -> Void
    
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory? = nil
    
    var filteredExercises: [Exercise] {
        var result = exercises.filter { $0.isActive }
        
        if !searchText.isEmpty {
            result = result.filter { exercise in
                exercise.nameTR.localizedCaseInsensitiveContains(searchText) ||
                exercise.nameEN.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let category = selectedCategory {
            result = result.filter { $0.category == category.rawValue }
        }
        
        return result.sorted { $0.nameTR < $1.nameTR }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                SearchBar(text: $searchText)
                    .padding()
                
                // Category filter
                CategoryFilterView(selectedCategory: $selectedCategory)
                
                // Exercise list
                if filteredExercises.isEmpty {
                    EmptyExerciseState(searchText: searchText)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredExercises) { exercise in
                                ExerciseRow(exercise: exercise) {
                                    selectExercise(exercise)
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Egzersiz Seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Özel Ekle") {
                        // TODO: Add custom exercise
                    }
                    .font(.subheadline)
                }
            }
        }
    }
    
    private func selectExercise(_ exercise: Exercise) {
        onExerciseSelected(exercise)
        dismiss()
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Egzersiz ara...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button("Temizle") {
                    text = ""
                }
                .foregroundColor(.gray)
                .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Category Filter View
struct CategoryFilterView: View {
    @Binding var selectedCategory: ExerciseCategory?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryChip(
                    title: "Tümü",
                    icon: "list.bullet",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }
                
                ForEach(ExerciseCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.displayName,
                        icon: category.icon,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = selectedCategory == category ? nil : category
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
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color(.systemGray6))
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
    
    var category: ExerciseCategory {
        ExerciseCategory(rawValue: exercise.category) ?? .other
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundColor(category.color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.nameTR)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if !exercise.nameEN.isEmpty && exercise.nameEN != exercise.nameTR {
                        Text(exercise.nameEN)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !exercise.equipment.isEmpty {
                        EquipmentTags(equipment: exercise.equipment)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
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
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
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
                Text("Egzersiz Bulunamadı")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Kategori seçerek filtreleyebilirsin")
                    .foregroundColor(.secondary)
            } else {
                Text("'\(searchText)' için sonuç yok")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Farklı anahtar kelimeler dene")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 60)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Exercise.self, Workout.self, WorkoutPart.self, ExerciseSet.self,
        configurations: config
    )

    let context = container.mainContext
    let exercise = Exercise(
        nameEN: "Bench Press",
        nameTR: "Göğüs Presi",
        category: "push",
        equipment: "barbell,bench"
    )
    context.insert(exercise)

    let workoutPart = WorkoutPart(name: "Strength", type: .strength, orderIndex: 1)

    return ExerciseSelectionView(
        workoutPart: workoutPart,
        onExerciseSelected: { _ in }
    )
    .modelContainer(container)
}

