import SwiftUI

// MARK: - Set Tracking Row (Hevy Style)
struct SetTrackingRow: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var unitSettings: UnitSettings
    @Binding var set: SetData
    let setNumber: Int
    let previousSet: SetData?
    let onComplete: () -> Void
    let onDelete: (() -> Void)?
    
    @FocusState private var isWeightFocused: Bool
    @FocusState private var isRepsFocused: Bool
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    
    // Optimized formatters
    private static let weightFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    // Optimized for memory and performance
    
    // Unit-aware formatting
    private var weightPlaceholder: String {
        unitSettings.unitSystem == .metric ? "kg" : "lb"
    }
    
    private var weightHeaderTitle: String {
        unitSettings.unitSystem == .metric ? "KG" : "LB"
    }
    
    private var backgroundColor: Color {
        if set.isCompleted {
            return theme.colors.success.opacity(0.05)
        } else if set.isWarmup {
            return theme.colors.warning.opacity(0.05)
        } else {
            return .clear
        }
    }
    
    // MARK: - View Components
    
    private var setNumberSection: some View {
        HStack(spacing: 4) {
            Text("\(setNumber)")
                .font(theme.typography.body)
                .fontWeight(.medium)
                .foregroundColor(theme.colors.textPrimary)
                .frame(width: 20, alignment: .center)
            
            if set.isWarmup {
                Text("W")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.warning)
            }
        }
    }
    
    private var previousSetInfo: some View {
        Group {
            if let prev = previousSet {
                Text(prev.displayText)
                    .font(theme.typography.caption2)
                    .foregroundColor(theme.colors.textSecondary.opacity(0.6))
                    .frame(width: 60)
                    .lineLimit(1)
            } else {
                Spacer()
                    .frame(width: 60)
            }
        }
    }
    
    private var weightInputSection: some View {
        HStack(spacing: 4) {
            decreaseWeightButton
            weightTextField
            increaseWeightButton
        }
    }
    
    private var decreaseWeightButton: some View {
        Button(action: {
            let currentWeight = set.weight ?? 0
            let increment = unitSettings.unitSystem == .metric ? 2.5 : UnitsConverter.lbsToKg(5.0)
            set.weight = max(0, currentWeight - increment)
            updateWeightText()
            HapticManager.shared.impact(.medium)
        }) {
            Image(systemName: "minus")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.colors.textSecondary)
                .frame(width: 32, height: 32)
                .background(theme.colors.backgroundSecondary, in: RoundedRectangle(cornerRadius: theme.radius.s))
        }
    }
    
    private var weightTextField: some View {
        TextField(weightPlaceholder, text: $weightText)
            .focused($isWeightFocused)
            .multilineTextAlignment(.center)
            .keyboardType(.decimalPad)
            .font(theme.typography.body)
            .frame(width: 50)
            .padding(.vertical, 4)
            .background(theme.colors.backgroundSecondary, in: RoundedRectangle(cornerRadius: theme.radius.s))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.s)
                    .stroke(isWeightFocused ? theme.colors.accent : Color.clear, lineWidth: 2)
            )
            .onChange(of: weightText) { _, newValue in
                if let weight = parseWeightFromInput(newValue) {
                    set.weight = weight
                }
            }
            .onSubmit {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isWeightFocused = false
                    isRepsFocused = true
                }
            }
    }
    
    private var increaseWeightButton: some View {
        Button(action: {
            let currentWeight = set.weight ?? previousSet?.weight ?? 0
            let increment = unitSettings.unitSystem == .metric ? 2.5 : UnitsConverter.lbsToKg(5.0)
            set.weight = currentWeight + increment
            updateWeightText()
            HapticManager.shared.impact(.medium)
        }) {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.colors.textSecondary)
                .frame(width: 32, height: 32)
                .background(theme.colors.backgroundSecondary, in: RoundedRectangle(cornerRadius: theme.radius.s))
        }
    }
    
    private var multiplySymbol: some View {
        Text("×")
            .font(theme.typography.body)
            .foregroundColor(theme.colors.textSecondary)
    }
    
    private var repsInputSection: some View {
        HStack(spacing: 4) {
            decreaseRepsButton
            repsTextField
            increaseRepsButton
        }
    }
    
    private var decreaseRepsButton: some View {
        Button(action: {
            if set.reps > 0 {
                set.reps -= 1
                updateRepsText()
                HapticManager.shared.impact(.medium)
            }
        }) {
            Image(systemName: "minus")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.colors.textSecondary)
                .frame(width: 32, height: 32)
                .background(theme.colors.backgroundSecondary, in: RoundedRectangle(cornerRadius: theme.radius.s))
        }
    }
    
    private var repsTextField: some View {
        TextField("0", text: $repsText)
            .focused($isRepsFocused)
            .multilineTextAlignment(.center)
            .keyboardType(.numberPad)
            .font(theme.typography.body)
            .frame(width: 38)
            .padding(.vertical, 4)
            .background(theme.colors.backgroundSecondary, in: RoundedRectangle(cornerRadius: theme.radius.s))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.s)
                    .stroke(isRepsFocused ? theme.colors.accent : Color.clear, lineWidth: 2)
            )
            .onChange(of: repsText) { _, newValue in
                if let reps = Int(newValue) {
                    set.reps = reps
                }
            }
            .onSubmit {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isRepsFocused = false
                }
                
                if set.weight != nil && set.reps > 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.3)) {
                            set.isCompleted = true
                            set.timestamp = Date()
                            onComplete()
                        }
                    }
                }
            }
    }
    
    private var increaseRepsButton: some View {
        Button(action: {
            set.reps += 1
            updateRepsText()
            HapticManager.shared.impact(.medium)
        }) {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.colors.textSecondary)
                .frame(width: 32, height: 32)
                .background(theme.colors.backgroundSecondary, in: RoundedRectangle(cornerRadius: theme.radius.s))
        }
    }
    
    private var completeButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                set.isCompleted.toggle()
                if set.isCompleted {
                    set.timestamp = Date()
                    onComplete()
                }
            }
            HapticManager.shared.impact(set.isCompleted ? .heavy : .medium)
        }) {
            Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 24))
                .foregroundColor(set.isCompleted ? theme.colors.success : theme.colors.textSecondary)
                .animation(.easeInOut(duration: 0.2), value: set.isCompleted)
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            setNumberSection
            previousSetInfo
            weightInputSection
            multiplySymbol
            repsInputSection
            Spacer(minLength: 4)
            completeButton
        }
        .padding(.horizontal, theme.spacing.xs)
        .padding(.vertical, 8)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: theme.radius.s))
        .onAppear {
            setupInitialValues()
        }
        .onTapGesture {
            // Smart focus management with animation
            withAnimation(.easeInOut(duration: 0.2)) {
                // Auto-focus weight if no field is focused and set is incomplete
                if !isWeightFocused && !isRepsFocused && !set.isCompleted {
                    if set.weight == nil {
                        isWeightFocused = true
                    } else if set.reps == 0 {
                        isRepsFocused = true
                    }
                } else {
                    // Dismiss keyboard if already focused
                    isWeightFocused = false
                    isRepsFocused = false
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if let onDelete = onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
    
    private func setupInitialValues() {
        // Set initial weight - convert for display
        if let weight = set.weight {
            weightText = formatWeightForDisplay(weight)
        } else if let prevWeight = previousSet?.weight {
            set.weight = prevWeight
            weightText = formatWeightForDisplay(prevWeight)
        }
        
        // Set initial reps
        repsText = String(set.reps)
    }
    
    private func updateWeightText() {
        if let weight = set.weight {
            weightText = formatWeightForDisplay(weight)
        }
    }
    
    private func updateRepsText() {
        repsText = String(set.reps)
    }
    
    // MARK: - Unit Conversion Helpers
    private func formatWeightForDisplay(_ kg: Double) -> String {
        switch unitSettings.unitSystem {
        case .metric:
            return Self.weightFormatter.string(from: NSNumber(value: kg)) ?? "0"
        case .imperial:
            let lbs = UnitsConverter.kgToLbs(kg)
            return Self.weightFormatter.string(from: NSNumber(value: lbs)) ?? "0"
        }
    }
    
    private func parseWeightFromInput(_ input: String) -> Double? {
        guard let value = Double(input), value > 0 else { return nil }
        
        switch unitSettings.unitSystem {
        case .metric:
            return value // Already in kg
        case .imperial:
            return UnitsConverter.lbsToKg(value) // Convert lbs to kg for storage
        }
    }
}

// MARK: - Quick Weight Buttons
struct QuickWeightButtons: View {
    @Environment(\.theme) private var theme
    @Binding var weight: Double?
    let increments: [Double] = [1.25, 2.5, 5, 10]
    
    var body: some View {
        HStack(spacing: theme.spacing.s) {
            ForEach(increments, id: \.self) { increment in
                Button(action: {
                    let current = weight ?? 0
                    weight = current + increment
                    HapticManager.shared.impact(.light)
                }) {
                    Text("+\(increment.clean)")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.accent)
                        .padding(.horizontal, theme.spacing.s)
                        .padding(.vertical, 4)
                        .background(theme.colors.accent.opacity(0.1))
                        .cornerRadius(theme.radius.s)
                }
            }
        }
    }
}

// MARK: - Helper Extensions
extension Double {
    var clean: String {
        return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(format: "%.1f", self)
    }
}
