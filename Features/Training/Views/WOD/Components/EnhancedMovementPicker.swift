import SwiftUI
import SwiftData

struct EnhancedMovementPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Query private var crossfitMovements: [CrossFitMovement]
    
    let onAdd: (WODBuilderView.WODMovementData) -> Void
    
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var selectedMovement: CrossFitMovement?
    @State private var reps = ""
    @State private var rxWeightMale = ""
    @State private var rxWeightFemale = ""
    @State private var scaledWeightMale = ""
    @State private var scaledWeightFemale = ""
    @State private var notes = ""
    
    
    
    private let categories = [
        "All", "Gymnastics", "Olympic", "Powerlifting", "Cardio", "Bodyweight", "Functional", "Plyometric"
    ]
    
    private var filteredMovements: [CrossFitMovement] {
        let categoryFiltered = selectedCategory == "All" ? 
            crossfitMovements : 
            crossfitMovements.filter { $0.category == selectedCategory }
        
        if searchText.isEmpty {
            return categoryFiltered.sorted { $0.displayName < $1.displayName }
        }
        
        return categoryFiltered
            .filter { 
                $0.displayName.localizedCaseInsensitiveContains(searchText) ||
                $0.nameEN.localizedCaseInsensitiveContains(searchText)
            }
            .sorted { $0.displayName < $1.displayName }
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
                            ForEach(filteredMovements, id: \.nameEN) { movement in
                                CrossFitMovementRow(
                                    movement: movement,
                                    isSelected: false,
                                    onTap: {
                                        selectedMovement = movement
                                        // Auto-fill RX weights if available
                                        rxWeightMale = movement.rxWeightMale ?? ""
                                        rxWeightFemale = movement.rxWeightFemale ?? ""
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
                                    Text(selectedMovement?.displayName ?? "")
                                        .font(theme.typography.headline)
                                        .foregroundColor(theme.colors.textPrimary)
                                }
                                Spacer()
                                Button(CommonKeys.Onboarding.Common.change.localized) {
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
                .navigationTitle(CommonKeys.Navigation.addMovement.localized)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(CommonKeys.Onboarding.Common.cancel.localized) { dismiss() }
                    }
                }
        }
    }
    
    private func addMovement() {
        guard let movement = selectedMovement else { return }
        
        let wodMovement = WODBuilderView.WODMovementData(
            name: movement.displayName,
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

// MARK: - CrossFit Movement Row
private struct CrossFitMovementRow: View {
    let movement: CrossFitMovement
    let isSelected: Bool
    let onTap: () -> Void
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: theme.spacing.m) {
                // Category icon
                Image(systemName: movement.categoryEnum.icon)
                    .font(.title3)
                    .foregroundColor(theme.colors.accent)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(movement.displayName)
                        .font(theme.typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    HStack {
                        Text(movement.category)
                            .font(theme.typography.caption2)
                            .foregroundColor(theme.colors.textSecondary)
                        
                        if let rxMale = movement.rxWeightMale {
                            Text("• RX: \(rxMale)")
                                .font(theme.typography.caption2)
                                .foregroundColor(theme.colors.accent)
                        }
                        
                        Text("• WOD: \(movement.wodSuitability)/10")
                            .font(theme.typography.caption2)
                            .foregroundColor(movement.wodSuitability >= 8 ? theme.colors.success : theme.colors.warning)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(theme.colors.success)
                }
            }
            .padding()
            .background(theme.colors.cardBackground)
            .cornerRadius(theme.radius.m)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Movement Row (Legacy)
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