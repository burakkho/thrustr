import SwiftUI
import SwiftData

struct WODBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Query private var exercises: [Exercise]
    
    @State private var wodName = ""
    @State private var wodType: WODType = .forTime
    @State private var repScheme = ""
    @State private var timeCap = ""
    @State private var movements: [WODMovementData] = []
    @State private var showingMovementPicker = false
    @State private var editingMovement: WODMovementData?
    
    // Temporary data structure for building
    struct WODMovementData: Identifiable {
        let id = UUID()
        var name: String
        var reps: String = ""
        var rxWeightMale: String = ""
        var rxWeightFemale: String = ""
        var notes: String = ""
    }
    
    private var isValid: Bool {
        !wodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !movements.isEmpty
    }
    
    private var suggestedMovements: [String] {
        // Common CrossFit movements
        [
            "Thrusters", "Pull-ups", "Push-ups", "Air Squats",
            "Burpees", "Box Jumps", "Wall Balls", "Kettlebell Swings",
            "Double-unders", "Toes-to-bar", "Clean and Jerk", "Snatches",
            "Deadlifts", "Handstand Push-ups", "Muscle-ups", "Row",
            "Run", "Assault Bike", "Ski Erg"
        ]
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.l) {
                    // WOD Name
                    VStack(alignment: .leading, spacing: theme.spacing.s) {
                        Label("WOD Name", systemImage: "tag")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                        
                        TextField("Enter WOD name", text: $wodName)
                            .textFieldStyle(.plain)
                            .font(theme.typography.body)
                            .padding()
                            .background(theme.colors.backgroundSecondary)
                            .cornerRadius(theme.radius.m)
                    }
                    
                    // WOD Type
                    VStack(alignment: .leading, spacing: theme.spacing.s) {
                        Label("Type", systemImage: "timer")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                        
                        Picker("WOD Type", selection: $wodType) {
                            ForEach(WODType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Rep Scheme (for For Time WODs)
                    if wodType == .forTime {
                        VStack(alignment: .leading, spacing: theme.spacing.s) {
                            Label("Rep Scheme", systemImage: "repeat")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                            
                            TextField("e.g., 21-15-9 or 5 rounds", text: $repScheme)
                                .textFieldStyle(.plain)
                                .font(theme.typography.body)
                                .padding()
                                .background(theme.colors.backgroundSecondary)
                                .cornerRadius(theme.radius.m)
                            
                            Text("Examples: '21-15-9' for decreasing reps, '5' for 5 rounds")
                                .font(theme.typography.caption2)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                    }
                    
                    // Time Cap (for AMRAP or general time limit)
                    if wodType == .amrap || wodType == .emom {
                        VStack(alignment: .leading, spacing: theme.spacing.s) {
                            Label(wodType == .amrap ? "Duration (minutes)" : "Total Minutes", systemImage: "clock")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                            
                            TextField("e.g., 20", text: $timeCap)
                                .textFieldStyle(.plain)
                                .font(theme.typography.body)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(theme.colors.backgroundSecondary)
                                .cornerRadius(theme.radius.m)
                        }
                    }
                    
                    // Movements
                    VStack(alignment: .leading, spacing: theme.spacing.m) {
                        HStack {
                            Label("Movements", systemImage: "figure.run")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                            
                            Spacer()
                            
                            Button(action: { showingMovementPicker = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(theme.colors.accent)
                            }
                        }
                        
                        if movements.isEmpty {
                            Text("Add movements to your WOD")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(theme.colors.backgroundSecondary.opacity(0.5))
                                .cornerRadius(theme.radius.m)
                        } else {
                            ForEach(Array(movements.enumerated()), id: \.element.id) { index, movement in
                                MovementRow(
                                    movement: movement,
                                    index: index + 1,
                                    onEdit: { editingMovement = movement },
                                    onDelete: { movements.removeAll { $0.id == movement.id } }
                                )
                            }
                        }
                    }
                    
                    // Quick Add Buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: theme.spacing.s) {
                            ForEach(suggestedMovements.prefix(5), id: \.self) { movement in
                                Button(action: { addQuickMovement(movement) }) {
                                    Text(movement)
                                        .font(theme.typography.caption)
                                        .padding(.horizontal, theme.spacing.m)
                                        .padding(.vertical, theme.spacing.s)
                                        .background(theme.colors.accent.opacity(0.1))
                                        .foregroundColor(theme.colors.accent)
                                        .cornerRadius(theme.radius.l)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Create WOD")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveWOD() }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingMovementPicker) {
                MovementPickerView { movement in
                    movements.append(movement)
                }
            }
            .sheet(item: $editingMovement) { movement in
                MovementEditView(movement: movement) { updated in
                    if let index = movements.firstIndex(where: { $0.id == movement.id }) {
                        movements[index] = updated
                    }
                }
            }
        }
    }
    
    private func addQuickMovement(_ name: String) {
        let movement = WODMovementData(name: name)
        movements.append(movement)
    }
    
    private func saveWOD() {
        // Parse rep scheme
        let reps: [Int] = {
            if wodType == .forTime {
                let components = repScheme.split(separator: "-")
                return components.compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            }
            return []
        }()
        
        // Parse time cap
        let timeCapSeconds: Int? = {
            if let minutes = Int(timeCap) {
                return minutes * 60
            }
            return nil
        }()
        
        // Create WOD
        let wod = WOD(
            name: wodName,
            type: wodType,
            repScheme: reps,
            timeCap: timeCapSeconds,
            isCustom: true
        )
        
        // Add movements
        for (index, movementData) in movements.enumerated() {
            let movement = WODMovement(
                name: movementData.name,
                rxWeightMale: movementData.rxWeightMale.isEmpty ? nil : movementData.rxWeightMale,
                rxWeightFemale: movementData.rxWeightFemale.isEmpty ? nil : movementData.rxWeightFemale,
                reps: movementData.reps.isEmpty ? nil : Int(movementData.reps),
                orderIndex: index
            )
            movement.wod = wod
            wod.movements.append(movement)
            modelContext.insert(movement)
        }
        
        modelContext.insert(wod)
        
        do {
            try modelContext.save()
            HapticManager.shared.notification(.success)
            dismiss()
        } catch {
            print("Error saving WOD: \(error)")
        }
    }
}

// MARK: - Movement Row
private struct MovementRow: View {
    let movement: WODBuilderView.WODMovementData
    let index: Int
    let onEdit: () -> Void
    let onDelete: () -> Void
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: theme.spacing.m) {
            Text("\(index).")
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(movement.name)
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textPrimary)
                
                HStack(spacing: theme.spacing.s) {
                    if !movement.reps.isEmpty {
                        Text("\(movement.reps) reps")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    
                    if !movement.rxWeightMale.isEmpty {
                        Text("RX: \(movement.rxWeightMale)")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.accent)
                    }
                }
            }
            
            Spacer()
            
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(theme.colors.error)
            }
        }
        .padding()
        .background(theme.colors.backgroundSecondary)
        .cornerRadius(theme.radius.m)
    }
}

// MARK: - Movement Picker
private struct MovementPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    let onSelect: (WODBuilderView.WODMovementData) -> Void
    
    @State private var movementName = ""
    @State private var reps = ""
    @State private var rxWeightMale = ""
    @State private var rxWeightFemale = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Movement") {
                    TextField("Movement name", text: $movementName)
                }
                
                Section("Reps (optional)") {
                    TextField("Number of reps", text: $reps)
                        .keyboardType(.numberPad)
                }
                
                Section("RX Weight (optional)") {
                    TextField("Male (e.g., 43kg)", text: $rxWeightMale)
                    TextField("Female (e.g., 30kg)", text: $rxWeightFemale)
                }
            }
            .navigationTitle("Add Movement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let movement = WODBuilderView.WODMovementData(
                            name: movementName,
                            reps: reps,
                            rxWeightMale: rxWeightMale,
                            rxWeightFemale: rxWeightFemale
                        )
                        onSelect(movement)
                        dismiss()
                    }
                    .disabled(movementName.isEmpty)
                }
            }
        }
    }
}

// MARK: - Movement Edit
private struct MovementEditView: View {
    @Environment(\.dismiss) private var dismiss
    let movement: WODBuilderView.WODMovementData
    let onSave: (WODBuilderView.WODMovementData) -> Void
    
    @State private var movementName: String
    @State private var reps: String
    @State private var rxWeightMale: String
    @State private var rxWeightFemale: String
    
    init(movement: WODBuilderView.WODMovementData, onSave: @escaping (WODBuilderView.WODMovementData) -> Void) {
        self.movement = movement
        self.onSave = onSave
        _movementName = State(initialValue: movement.name)
        _reps = State(initialValue: movement.reps)
        _rxWeightMale = State(initialValue: movement.rxWeightMale)
        _rxWeightFemale = State(initialValue: movement.rxWeightFemale)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Movement") {
                    TextField("Movement name", text: $movementName)
                }
                
                Section("Reps (optional)") {
                    TextField("Number of reps", text: $reps)
                        .keyboardType(.numberPad)
                }
                
                Section("RX Weight (optional)") {
                    TextField("Male (e.g., 43kg)", text: $rxWeightMale)
                    TextField("Female (e.g., 30kg)", text: $rxWeightFemale)
                }
            }
            .navigationTitle("Edit Movement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var updated = movement
                        updated.name = movementName
                        updated.reps = reps
                        updated.rxWeightMale = rxWeightMale
                        updated.rxWeightFemale = rxWeightFemale
                        onSave(updated)
                        dismiss()
                    }
                }
            }
        }
    }
}