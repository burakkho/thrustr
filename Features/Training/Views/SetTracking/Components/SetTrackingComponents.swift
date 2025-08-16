import SwiftUI
import SwiftData

// MARK: - Exercise Header
struct ExerciseHeader: View {
    let exercise: Exercise
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.nameTR)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if !exercise.nameEN.isEmpty && exercise.nameEN != exercise.nameTR {
                        Text(exercise.nameEN)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Exercise category icon
                let category = ExerciseCategory(rawValue: exercise.category) ?? .other
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(category.color)
            }
            .padding(.horizontal)
            
            if !exercise.equipment.isEmpty {
                HStack {
                    Text(LocalizationKeys.Training.Set.equipment.localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(exercise.equipment.replacingOccurrences(of: ",", with: ", "))
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            Divider()
        }
        .background(Color(.systemBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exercise.nameTR) başlık")
    }
}

// MARK: - Set Table Header
struct SetTableHeader: View {
    let exercise: Exercise
    
    var body: some View {
        HStack(spacing: 0) {
            // Set number
            Text(LocalizationKeys.Training.Set.Header.set.localized)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(width: 40)
            
            if exercise.supportsWeight {
                Text(LocalizationKeys.Training.Set.Header.weight.localized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
            
            if exercise.supportsReps {
                Text(LocalizationKeys.Training.Set.Header.reps.localized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }

            if exercise.supportsTime {
                Text(LocalizationKeys.Training.Set.Header.time.localized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }

            if exercise.supportsDistance {
                Text(LocalizationKeys.Training.Set.Header.distance.localized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }

            // RPE column (optional, for weight+reps movements)
            if exercise.supportsWeight || exercise.supportsReps {
                Text(LocalizationKeys.Training.Set.Header.rpe.localized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
            
            // Complete button space
            Text("")
                .frame(width: 60)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Set Row
struct SetRow: View {
    @Binding var setData: SetData
    let setNumber: Int
    let exercise: Exercise
    let onComplete: () -> Void
    let oneRMFormula: OneRMFormula
    var shouldAutofocus: Bool = false
    var onNextField: (() -> Void)?
    var onPreviousField: (() -> Void)?
    var onCompleteSet: (() -> Void)?
    var onDelete: (() -> Void)?
    var onRepeat: (() -> Void)?
    var isLoading: Bool = false
    var isSaved: Bool = false
    var hasError: Bool = false
    
    @FocusState private var weightFocused: Bool
    @FocusState private var repsFocused: Bool
    @FocusState private var timeFocused: Bool
    @FocusState private var distanceFocused: Bool
    
    var body: some View {
		HStack(spacing: 0) {
            // Set number
            Text("\(setNumber)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(setData.isCompleted ? .green : .primary)
                .frame(width: 40)
            
            if exercise.supportsWeight {
                NumberInputField(
                    value: $setData.weight,
                    placeholder: UnitSettings().unitSystem == .imperial ? LocalizationKeys.Training.Set.lb.localized : LocalizationKeys.Training.Set.kg.localized,
                    isEnabled: !setData.isCompleted,
                    isWeight: true,
                    onNextField: { focusNextField() },
                    onPreviousField: { focusPreviousField() },
                    onCompleteSet: onCompleteSet
                )
                .frame(maxWidth: .infinity)
                .focused($weightFocused)
            }
            
            if exercise.supportsReps {
                NumberInputField(
                    value: Binding(
                        get: { Double(setData.reps) },
                        set: { setData.reps = Int($0) }
                    ),
                    placeholder: LocalizationKeys.Training.Set.reps.localized,
                    isEnabled: !setData.isCompleted,
                    allowDecimals: false,
                    isReps: true,
                    onNextField: { focusNextField() },
                    onPreviousField: { focusPreviousField() },
                    onCompleteSet: onCompleteSet
                )
                .frame(maxWidth: .infinity)
                .focused($repsFocused)
            }

            if exercise.supportsTime {
                TimeInputField(
                    seconds: $setData.durationSeconds,
                    isEnabled: !setData.isCompleted
                )
                .frame(maxWidth: .infinity)
            }

            if exercise.supportsDistance {
                NumberInputField(
                    value: $setData.distanceMeters,
                    placeholder: LocalizationKeys.Training.Set.meters.localized,
                    isEnabled: !setData.isCompleted,
                    allowDecimals: true
                )
                .frame(maxWidth: .infinity)
            }

            // RPE
            if exercise.supportsWeight || exercise.supportsReps {
                RPEPicker(rpe: $setData.rpe, isEnabled: !setData.isCompleted)
                    .frame(maxWidth: .infinity)
            }

            if let estimate = estimatedOneRM() {
                Text("~\(Int(estimate)) 1RM")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 70)
            }
            
			// Complete button with loading/success states
            Button(action: onComplete) {
                Group {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(0.8)
                    } else if setData.isCompleted && isSaved {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    } else if setData.isCompleted && hasError {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    } else if setData.isCompleted {
                        Image(systemName: "clock.circle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                    } else {
                        Image(systemName: "circle")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(setData.isCompleted ? LocalizationKeys.Training.Set.completed.localized : LocalizationKeys.Training.Set.finishExercise.localized)
            .accessibilityHint(LocalizationKeys.Training.Set.finishExercise.localized)
            .frame(width: 60)
            .disabled(setData.isCompleted || !setData.hasValidData || isLoading)
            .contextMenu {
                if hasError {
                    Button("Tekrar Dene") {
                        onComplete()
                    }
                }
                
                if !setData.isCompleted {
                    Button(LocalizationKeys.Training.Set.finishExercise.localized) {
                        onComplete()
                    }
                } else {
                    Button("Düzenle") {
                        setData.isCompleted = false
                    }
                }
                
                Button(LocalizationKeys.Common.delete.localized, role: .destructive) {
                    onDelete?()
                }
                
                if setData.isCompleted {
                    Button("Tekrarla") {
                        onRepeat?()
                    }
                }
            }
        }
		.accessibilityElement(children: .combine)
		.accessibilityLabel(accessibleSummary())
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(backgroundColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .scaleEffect(setData.isCompleted ? 1.0 : (isAnyFieldFocused ? 1.02 : 1.0))
        .animation(.easeInOut(duration: 0.2), value: setData.isCompleted)
        .animation(.easeInOut(duration: 0.15), value: isAnyFieldFocused)
        .onAppear {
            if shouldAutofocus && !setData.isCompleted {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    // Focus on the first available field
                    if exercise.supportsWeight {
                        weightFocused = true
                    } else if exercise.supportsReps {
                        repsFocused = true
                    } else if exercise.supportsTime {
                        timeFocused = true
                    } else if exercise.supportsDistance {
                        distanceFocused = true
                    }
                }
            }
        }
    }

    private func estimatedOneRM() -> Double? {
        guard exercise.supportsWeight, exercise.supportsReps else { return nil }
        let w = setData.weight
        let r = setData.reps
        guard w > 0, r > 0 else { return nil }
        return oneRMFormula.estimate1RM(weight: w, reps: r)
    }
    
    private var isAnyFieldFocused: Bool {
        weightFocused || repsFocused || timeFocused || distanceFocused
    }
    
    private var backgroundColor: Color {
        if isLoading {
            return Color.blue.opacity(0.1)
        } else if setData.isCompleted && hasError {
            return Color.red.opacity(0.1)
        } else if setData.isCompleted && isSaved {
            return Color.green.opacity(0.1)
        } else if setData.isCompleted {
            return Color.orange.opacity(0.1)
        } else if isAnyFieldFocused {
            return Color.blue.opacity(0.05)
        } else {
            return Color(.systemBackground)
        }
    }
    
    private var borderColor: Color {
        if isLoading {
            return Color.blue
        } else if setData.isCompleted && hasError {
            return Color.red
        } else if setData.isCompleted && isSaved {
            return Color.green
        } else if setData.isCompleted {
            return Color.orange
        } else if isAnyFieldFocused {
            return Color.blue
        } else {
            return Color(.systemGray4)
        }
    }
    
    private var borderWidth: CGFloat {
        if isLoading || setData.isCompleted || isAnyFieldFocused {
            return 2
        } else {
            return 1
        }
    }

    private func focusNextField() {
        if weightFocused && exercise.supportsReps {
            repsFocused = true
        } else if repsFocused && exercise.supportsTime {
            timeFocused = true
        } else if (repsFocused && !exercise.supportsTime && exercise.supportsDistance) || (timeFocused && exercise.supportsDistance) {
            distanceFocused = true
        } else {
            // Complete the set if we're at the last field
            onCompleteSet?()
        }
    }
    
    private func focusPreviousField() {
        if repsFocused && exercise.supportsWeight {
            weightFocused = true
        } else if timeFocused && exercise.supportsReps {
            repsFocused = true
        } else if distanceFocused {
            if exercise.supportsTime {
                timeFocused = true
            } else if exercise.supportsReps {
                repsFocused = true
            } else if exercise.supportsWeight {
                weightFocused = true
            }
        }
    }

	private func accessibleSummary() -> String {
		var pieces: [String] = ["Set \(setNumber)"]
		if exercise.supportsWeight, setData.weight > 0 { pieces.append("\(Int(setData.weight)) kilogram") }
		if exercise.supportsReps, setData.reps > 0 { pieces.append("\(setData.reps) tekrar") }
		if exercise.supportsTime, setData.durationSeconds > 0 {
			let m = setData.durationSeconds / 60
			let s = setData.durationSeconds % 60
			pieces.append("\(m) dakika \(s) saniye")
		}
		if exercise.supportsDistance, setData.distanceMeters > 0 { pieces.append("\(Int(setData.distanceMeters)) metre") }
		pieces.append(setData.isCompleted ? "tamamlandı" : "tamamlanmadı")
		return pieces.joined(separator: ", ")
	}
}

// MARK: - Add Set Button
struct AddSetButton: View {
    let action: () -> Void
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(theme.colors.accent)
                Text(LocalizationKeys.Training.Set.addSet.localized)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(theme.spacing.m)
            .background(theme.colors.accent.opacity(0.1))
            .cornerRadius(8)
        }
        .foregroundColor(theme.colors.accent)
        .buttonStyle(PressableStyle())
    }
}

// MARK: - Quick Reps Selector
struct QuickRepsSelector: View {
    @Binding var reps: Int
    let isEnabled: Bool
    @Environment(\.theme) private var theme
    
    private let commonReps = [6, 8, 10, 12, 15]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hızlı Tekrar Seçimi")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                ForEach(commonReps, id: \.self) { repCount in
                    Button("\(repCount)") {
                        reps = repCount
                        HapticManager.shared.impact(.light)
                    }
                    .font(.caption)
                    .foregroundColor(reps == repCount ? .white : theme.colors.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(reps == repCount ? theme.colors.accent : theme.colors.accent.opacity(0.1))
                    .cornerRadius(6)
                    .disabled(!isEnabled)
                }
                Spacer()
            }
        }
    }
}

// MARK: - Notes Section
struct NotesSection: View {
    @Binding var notes: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizationKeys.Training.Set.notes.localized)
                .font(.headline)
                .foregroundColor(.secondary)
            
            TextField(LocalizationKeys.Training.Set.notesPlaceholder.localized, text: $notes, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
        }
    }
}

