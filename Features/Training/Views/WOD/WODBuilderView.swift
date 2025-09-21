import SwiftUI
import SwiftData

struct WODBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(UnitSettings.self) var unitSettings
    @Query private var exercises: [Exercise]

    @State private var viewModel: WODBuilderViewModel?

    // Computed properties that delegate to ViewModel
    private var wodName: String {
        get { viewModel?.wodName ?? "" }
        set { viewModel?.updateWODName(newValue) }
    }

    private var wodType: WODType {
        get { viewModel?.wodType ?? .forTime }
        set { viewModel?.updateWODType(newValue) }
    }

    private var repScheme: String {
        get { viewModel?.repScheme ?? "" }
        set { viewModel?.updateRepScheme(newValue) }
    }

    private var timeCap: String {
        get { viewModel?.timeCap ?? "" }
        set { viewModel?.updateTimeCap(newValue) }
    }

    private var movements: [WODBuilderViewModel.WODMovementData] {
        viewModel?.movements ?? []
    }

    private var showingMovementPicker: Bool {
        get { viewModel?.showingMovementPicker ?? false }
        set { viewModel?.showingMovementPicker = newValue }
    }

    private var editingMovement: WODBuilderViewModel.WODMovementData? {
        get { viewModel?.editingMovement }
        set { viewModel?.editingMovement = newValue }
    }

    private var errorMessage: String? {
        viewModel?.errorMessage
    }

    private var successMessage: String? {
        viewModel?.successMessage
    }

    private var showingCancelAlert: Bool {
        get { viewModel?.showingCancelAlert ?? false }
        set { viewModel?.showingCancelAlert = newValue }
    }
    
    // Computed properties that delegate to ViewModel
    private var isValid: Bool {
        viewModel?.isValid ?? false
    }

    private var isNameValid: Bool {
        viewModel?.isNameValid ?? false
    }

    private var hasMovements: Bool {
        viewModel?.hasMovements ?? false
    }

    private var isTimeCapValid: Bool {
        viewModel?.isTimeCapValid ?? false
    }

    private var isRepSchemeValid: Bool {
        viewModel?.isRepSchemeValid ?? false
    }

    private var hasUnsavedChanges: Bool {
        viewModel?.hasUnsavedChanges ?? false
    }

    private var suggestedMovements: [String] {
        viewModel?.suggestedMovements ?? []
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.l) {
                    // WOD Name
                    VStack(alignment: .leading, spacing: theme.spacing.s) {
                        Label("wod.name_label".localized, systemImage: "tag")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                        
                        TextField("wod.enter_name_placeholder".localized, text: Binding(
                            get: { wodName },
                            set: { viewModel?.updateWODName($0) }
                        ))
                            .textFieldStyle(.plain)
                            .font(theme.typography.body)
                            .padding()
                            .background(theme.colors.backgroundSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: theme.radius.m)
                                    .stroke(
                                        !wodName.isEmpty && !isNameValid ? theme.colors.error : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                            .cornerRadius(theme.radius.m)
                        
                        if let errorText = viewModel?.getValidationError(for: .name) {
                            Text(errorText)
                                .font(theme.typography.caption2)
                                .foregroundColor(theme.colors.error)
                        }
                    }
                    
                    // WOD Type
                    VStack(alignment: .leading, spacing: theme.spacing.s) {
                        Label("wod.type_label".localized, systemImage: "timer")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                        
                        Picker("wod.type_label".localized, selection: Binding(
                            get: { wodType },
                            set: { viewModel?.updateWODType($0) }
                        )) {
                            ForEach(WODType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Rep Scheme (for For Time WODs)
                    if wodType == .forTime {
                        VStack(alignment: .leading, spacing: theme.spacing.s) {
                            Label("wod.rep_scheme_label".localized, systemImage: "repeat")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                            
                            TextField("wod.rep_scheme_placeholder".localized, text: Binding(
                                get: { repScheme },
                                set: { viewModel?.updateRepScheme($0) }
                            ))
                                .textFieldStyle(.plain)
                                .font(theme.typography.body)
                                .padding()
                                .background(theme.colors.backgroundSecondary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: theme.radius.m)
                                        .stroke(
                                            !repScheme.isEmpty && !isRepSchemeValid ? theme.colors.error : Color.clear,
                                            lineWidth: 1
                                        )
                                )
                                .cornerRadius(theme.radius.m)
                            
                            if let errorText = viewModel?.getValidationError(for: .repScheme) {
                                Text(errorText)
                                    .font(theme.typography.caption2)
                                    .foregroundColor(theme.colors.error)
                            } else if let helperText = viewModel?.getHelperText(for: .repScheme) {
                                Text(helperText)
                                    .font(theme.typography.caption2)
                                    .foregroundColor(theme.colors.textSecondary)
                            }
                        }
                    }
                    
                    // Time Cap (for AMRAP or general time limit)
                    if wodType == .amrap || wodType == .emom {
                        VStack(alignment: .leading, spacing: theme.spacing.s) {
                            Label(wodType == .amrap ? "wod.duration_label".localized : "wod.total_minutes_label".localized, systemImage: "clock")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                            
                            TextField("wod.duration_placeholder".localized, text: Binding(
                                get: { timeCap },
                                set: { viewModel?.updateTimeCap($0) }
                            ))
                                .textFieldStyle(.plain)
                                .font(theme.typography.body)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(theme.colors.backgroundSecondary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: theme.radius.m)
                                        .stroke(
                                            !timeCap.isEmpty && !isTimeCapValid ? theme.colors.error : Color.clear,
                                            lineWidth: 1
                                        )
                                )
                                .cornerRadius(theme.radius.m)
                            
                            if let errorText = viewModel?.getValidationError(for: .timeCap) {
                                Text(errorText)
                                    .font(theme.typography.caption2)
                                    .foregroundColor(theme.colors.error)
                            }
                        }
                    }
                    
                    // Movements
                    VStack(alignment: .leading, spacing: theme.spacing.m) {
                        HStack {
                            Label("wod.movements_label".localized, systemImage: "figure.run")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                            
                            Spacer()
                            
                            Button(action: { viewModel?.showMovementPicker() }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(theme.colors.accent)
                            }
                        }
                        
                        if movements.isEmpty {
                            VStack(spacing: theme.spacing.s) {
                                Text("wod.add_movements".localized)
                                    .font(theme.typography.caption)
                                    .foregroundColor(theme.colors.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(theme.colors.backgroundSecondary.opacity(0.5))
                                    .cornerRadius(theme.radius.m)
                                
                                if let errorText = viewModel?.getValidationError(for: .movements) {
                                    Text(errorText)
                                        .font(theme.typography.caption2)
                                        .foregroundColor(theme.colors.error)
                                }
                            }
                        } else {
                            ForEach(Array(movements.enumerated()), id: \.element.id) { index, movement in
                                MovementRow(
                                    movement: movement,
                                    index: index + 1,
                                    onEdit: { viewModel?.editMovement(movement) },
                                    onDelete: { viewModel?.removeMovement(withId: movement.id) }
                                )
                            }
                        }
                    }
                    
                    // Quick Add Buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: theme.spacing.s) {
                            ForEach(suggestedMovements.prefix(5), id: \.self) { movement in
                                Button(action: { viewModel?.addQuickMovement(movement) }) {
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
            .navigationTitle("wod.create_title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        if hasUnsavedChanges {
                            viewModel?.showCancelAlert()
                        } else {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.save".localized) {
                        Task {
                            let result = await viewModel?.saveWOD()
                            if case .success = result {
                                // Dismiss after short delay to show success message
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    dismiss()
                                }
                            }
                        }
                    }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                }
            }
            .sheet(isPresented: Binding(
                get: { showingMovementPicker },
                set: { viewModel?.showingMovementPicker = $0 }
            )) {
                EnhancedMovementPicker { movementData in
                    viewModel?.addMovement(movementData)
                }
            }
            .sheet(item: Binding(
                get: { editingMovement },
                set: { viewModel?.editingMovement = $0 }
            )) { movement in
                MovementEditView(movement: movement) { updated in
                    viewModel?.updateMovement(updated)
                }
            }
            .alert("common.confirm_discard".localized, isPresented: Binding(
                get: { showingCancelAlert },
                set: { viewModel?.showingCancelAlert = $0 }
            )) {
                Button("common.cancel".localized, role: .cancel) {
                    viewModel?.hideCancelAlert()
                }
                Button("common.discard".localized, role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("common.discard_message".localized)
            }
        }
        .overlay(alignment: .bottom) {
            // Error Toast
            if let errorMessage = errorMessage {
                ToastView(text: errorMessage, icon: "exclamationmark.triangle.fill")
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            withAnimation { viewModel?.clearError() }
                        }
                    }
            }
            
            // Success Toast
            if let successMessage = successMessage {
                ToastView(text: successMessage, icon: "checkmark.circle.fill")
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation { viewModel?.clearSuccess() }
                        }
                    }
            }
        }
        .animation(.easeInOut, value: errorMessage)
        .animation(.easeInOut, value: successMessage)
        .onAppear {
            if viewModel == nil {
                viewModel = WODBuilderViewModel()
                viewModel?.setModelContext(modelContext)
            }
        }
    }
    
}

// MARK: - Movement Row
private struct MovementRow: View {
    let movement: WODBuilderViewModel.WODMovementData
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
                        Text("\(movement.reps) \("common.reps".localized)")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    
                    if !movement.rxWeightMale.isEmpty {
                        Text("\("wod.rx_prefix".localized): \(movement.rxWeightMale)")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.accent)
                    }
                    
                    if !movement.notes.isEmpty {
                        Text("• \(movement.notes)")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                            .lineLimit(1)
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


// MARK: - Movement Edit
private struct MovementEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(UnitSettings.self) var unitSettings
    let movement: WODBuilderViewModel.WODMovementData
    let onSave: (WODBuilderViewModel.WODMovementData) -> Void
    
    @State private var movementName: String
    @State private var reps: String
    @State private var rxWeightMale: String
    @State private var rxWeightFemale: String
    @State private var scaledWeightMale: String
    @State private var scaledWeightFemale: String
    @State private var notes: String
    
    init(movement: WODBuilderViewModel.WODMovementData, onSave: @escaping (WODBuilderViewModel.WODMovementData) -> Void) {
        self.movement = movement
        self.onSave = onSave
        _movementName = State(initialValue: movement.name)
        _reps = State(initialValue: movement.reps)
        _rxWeightMale = State(initialValue: movement.rxWeightMale)
        _rxWeightFemale = State(initialValue: movement.rxWeightFemale)
        _scaledWeightMale = State(initialValue: movement.scaledWeightMale)
        _scaledWeightFemale = State(initialValue: movement.scaledWeightFemale)
        _notes = State(initialValue: movement.notes)
    }
    
    private var weightUnit: String {
        unitSettings.unitSystem == .metric ? "kg" : "lb"
    }
    
    private var malePlaceholder: String {
        "Male (e.g., \(unitSettings.unitSystem == .metric ? "43" : "95")\(weightUnit))"
    }
    
    private var femalePlaceholder: String {
        "Female (e.g., \(unitSettings.unitSystem == .metric ? "30" : "65")\(weightUnit))"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("wod.movement_section".localized) {
                    TextField("wod.movement_name_placeholder".localized, text: $movementName)
                }
                
                Section("wod.reps_optional_section".localized) {
                    TextField("wod.number_of_reps_placeholder".localized, text: $reps)
                        .keyboardType(.numberPad)
                }
                
                Section("wod.rx_weight_optional_section".localized) {
                    TextField(malePlaceholder, text: $rxWeightMale)
                    TextField(femalePlaceholder, text: $rxWeightFemale)
                }
                
                Section("Scaled Weight (Optional)") {
                    TextField("Male scaled weight", text: $scaledWeightMale)
                    TextField("Female scaled weight", text: $scaledWeightFemale)
                }
                
                Section("Notes (Optional)") {
                    TextField("Movement notes or variations", text: $notes)
                }
            }
            .navigationTitle("wod.edit_movement_title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.save".localized) {
                        var updated = movement
                        updated.name = movementName
                        updated.reps = reps
                        updated.rxWeightMale = rxWeightMale
                        updated.rxWeightFemale = rxWeightFemale
                        updated.scaledWeightMale = scaledWeightMale
                        updated.scaledWeightFemale = scaledWeightFemale
                        updated.notes = notes
                        onSave(updated)
                        dismiss()
                    }
                }
            }
        }
    }
}