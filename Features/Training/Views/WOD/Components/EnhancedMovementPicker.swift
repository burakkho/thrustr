import SwiftUI
import SwiftData

struct EnhancedMovementPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Query private var exercises: [Exercise]
    
    let onAdd: (WODMovementData) -> Void
    
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var selectedMovement: Exercise?
    @State private var reps = ""
    @State private var rxWeightMale = ""
    @State private var rxWeightFemale = ""
    @State private var scaledWeightMale = ""
    @State private var scaledWeightFemale = ""
    @State private var notes = ""
    
    // Movement data structure
    struct WODMovementData {
        let name: String
        let reps: String
        let rxWeightMale: String
        let rxWeightFemale: String
        let scaledWeightMale: String
        let scaledWeightFemale: String
        let notes: String
    }
    
    // CrossFit specific movements
    private let crossfitMovements = [
        "Pull-ups", "Push-ups", "Air Squats", "Burpees",
        "Box Jumps", "Wall Balls", "Kettlebell Swings",
        "Double-unders", "Toes-to-bar", "Muscle-ups",
        "Thrusters", "Clean and Jerk", "Snatches",
        "Deadlifts", "Front Squats", "Back Squats",
        "Overhead Squats", "Handstand Push-ups",
        "Ring Dips", "Ring Rows", "Rope Climbs",
        "400m Run", "500m Row", "Cal Bike", "Cal Ski"
    ]
    
    private let categories = [
        "All", "Gymnastics", "Weightlifting", "Cardio", "Bodyweight"
    ]
    
    private var filteredMovements: [String] {
        let allMovements = crossfitMovements + exercises.map { $0.nameTR }
        
        if searchText.isEmpty {
            return Array(Set(allMovements)).sorted()
        }
        
        return Array(Set(allMovements))
            .filter { $0.localizedCaseInsensitiveContains(searchText) }
            .sorted()
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(theme.colors.textSecondary)
                    TextField("Search movements...", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(theme.colors.textSecondary)
                        }
                    }
                }
                .padding(theme.spacing.m)
                .background(theme.colors.backgroundSecondary)
                .cornerRadius(theme.radius.m)
                .padding()
                
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: theme.spacing.m) {
                        ForEach(categories, id: \.self) { category in
                            MovementCategoryChip(
                                title: category,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
                
                if selectedMovement == nil {
                    // Movement List
                    ScrollView {
                        LazyVStack(spacing: theme.spacing.s) {
                            ForEach(filteredMovements, id: \.self) { movement in
                                MovementRow(
                                    name: movement,
                                    isSelected: false,
                                    onTap: {
                                        selectedMovement = exercises.first { $0.nameTR == movement }
                                        if selectedMovement == nil {
                                            // Create temporary Exercise object for custom movement
                                            let temp = Exercise(nameEN: movement, nameTR: movement, category: "Custom", equipment: "")
                                            selectedMovement = temp
                                        }
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                } else {
                    // Movement Details
                    ScrollView {
                        VStack(spacing: theme.spacing.l) {
                            // Selected Movement
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Selected Movement")
                                        .font(theme.typography.caption)
                                        .foregroundColor(theme.colors.textSecondary)
                                    Text(selectedMovement?.nameTR ?? "")
                                        .font(theme.typography.headline)
                                        .foregroundColor(theme.colors.textPrimary)
                                }
                                Spacer()
                                Button("Change") {
                                    selectedMovement = nil
                                }
                                .foregroundColor(theme.colors.accent)
                            }
                            .padding()
                            .background(theme.colors.backgroundSecondary)
                            .cornerRadius(theme.radius.m)
                            
                            // Reps
                            VStack(alignment: .leading, spacing: theme.spacing.s) {
                                Label("Reps per round (optional)", systemImage: "number")
                                    .font(theme.typography.caption)
                                    .foregroundColor(theme.colors.textSecondary)
                                
                                TextField("Leave empty if using rep scheme", text: $reps)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(.plain)
                                    .padding()
                                    .background(theme.colors.backgroundSecondary)
                                    .cornerRadius(theme.radius.m)
                            }
                            
                            // RX Weights
                            VStack(alignment: .leading, spacing: theme.spacing.s) {
                                Label("RX Weight (optional)", systemImage: "scalemass")
                                    .font(theme.typography.caption)
                                    .foregroundColor(theme.colors.textSecondary)
                                
                                HStack(spacing: theme.spacing.m) {
                                    VStack(alignment: .leading) {
                                        Text("Male")
                                            .font(theme.typography.caption2)
                                            .foregroundColor(theme.colors.textSecondary)
                                        TextField("e.g., 43kg", text: $rxWeightMale)
                                            .textFieldStyle(.plain)
                                            .padding()
                                            .background(theme.colors.backgroundSecondary)
                                            .cornerRadius(theme.radius.m)
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text("Female")
                                            .font(theme.typography.caption2)
                                            .foregroundColor(theme.colors.textSecondary)
                                        TextField("e.g., 30kg", text: $rxWeightFemale)
                                            .textFieldStyle(.plain)
                                            .padding()
                                            .background(theme.colors.backgroundSecondary)
                                            .cornerRadius(theme.radius.m)
                                    }
                                }
                            }
                            
                            // Scaled Weights
                            VStack(alignment: .leading, spacing: theme.spacing.s) {
                                Label("Scaled Weight (optional)", systemImage: "scalemass")
                                    .font(theme.typography.caption)
                                    .foregroundColor(theme.colors.textSecondary)
                                
                                HStack(spacing: theme.spacing.m) {
                                    VStack(alignment: .leading) {
                                        Text("Male")
                                            .font(theme.typography.caption2)
                                            .foregroundColor(theme.colors.textSecondary)
                                        TextField("e.g., 30kg", text: $scaledWeightMale)
                                            .textFieldStyle(.plain)
                                            .padding()
                                            .background(theme.colors.backgroundSecondary)
                                            .cornerRadius(theme.radius.m)
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text("Female")
                                            .font(theme.typography.caption2)
                                            .foregroundColor(theme.colors.textSecondary)
                                        TextField("e.g., 20kg", text: $scaledWeightFemale)
                                            .textFieldStyle(.plain)
                                            .padding()
                                            .background(theme.colors.backgroundSecondary)
                                            .cornerRadius(theme.radius.m)
                                    }
                                }
                            }
                            
                            // Notes
                            VStack(alignment: .leading, spacing: theme.spacing.s) {
                                Label("Notes (optional)", systemImage: "note.text")
                                    .font(theme.typography.caption)
                                    .foregroundColor(theme.colors.textSecondary)
                                
                                TextField("e.g., chest to bar, american swings", text: $notes)
                                    .textFieldStyle(.plain)
                                    .padding()
                                    .background(theme.colors.backgroundSecondary)
                                    .cornerRadius(theme.radius.m)
                            }
                        }
                        .padding()
                    }
                    
                    // Add Button
                    Button(action: addMovement) {
                        Text("Add Movement")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(theme.colors.accent)
                            .foregroundColor(.white)
                            .cornerRadius(theme.radius.m)
                    }
                    .padding()
                }
            }
        }
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Add Movement")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
    }
    
    private func addMovement() {
        guard let movement = selectedMovement else { return }
        
        let wodMovement = WODMovementData(
            name: movement.nameTR,
            reps: reps,
            rxWeightMale: rxWeightMale,
            rxWeightFemale: rxWeightFemale,
            scaledWeightMale: scaledWeightMale,
            scaledWeightFemale: scaledWeightFemale,
            notes: notes
        )
        
        onAdd(wodMovement)
        dismiss()
    }
}

// MARK: - Movement Category Chip
private struct MovementCategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(theme.typography.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, theme.spacing.m)
                .padding(.vertical, theme.spacing.s)
                .background(isSelected ? theme.colors.accent : theme.colors.backgroundSecondary)
                .foregroundColor(isSelected ? .white : theme.colors.textPrimary)
                .cornerRadius(theme.radius.l)
        }
    }
}

// MARK: - Movement Row
private struct MovementRow: View {
    let name: String
    let isSelected: Bool
    let onTap: () -> Void
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(name)
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textPrimary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(theme.colors.accent)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            .padding()
            .background(theme.colors.backgroundSecondary)
            .cornerRadius(theme.radius.m)
        }
    }
}