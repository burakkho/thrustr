import SwiftUI

// MARK: - Set Tracking Row (Hevy Style)
struct SetTrackingRow: View {
    @Environment(\.theme) private var theme
    @Binding var set: SetData
    let setNumber: Int
    let previousSet: SetData?
    let onComplete: () -> Void
    let onDelete: (() -> Void)?
    
    @FocusState private var isWeightFocused: Bool
    @FocusState private var isRepsFocused: Bool
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    
    private var backgroundColor: Color {
        if set.isCompleted {
            return theme.colors.success.opacity(0.05)
        } else if set.isWarmup {
            return theme.colors.warning.opacity(0.05)
        } else {
            return Color.clear
        }
    }
    
    var body: some View {
        HStack(spacing: theme.spacing.s) {
            // Set number
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
            
            // Previous set info (ghost) - more compact
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
            
            // Weight input
            HStack(spacing: 4) {
                Button(action: {
                    let currentWeight = set.weight ?? 0
                    set.weight = max(0, currentWeight - 2.5)
                    updateWeightText()
                    HapticManager.shared.impact(.light)
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.colors.textSecondary)
                        .frame(width: 24, height: 24)
                        .background(theme.colors.backgroundSecondary)
                        .cornerRadius(theme.radius.s)
                }
                
                TextField("0", text: $weightText)
                    .focused($isWeightFocused)
                    .multilineTextAlignment(.center)
                    .keyboardType(.decimalPad)
                    .font(theme.typography.body)
                    .frame(width: 50)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: theme.radius.s)
                            .fill(theme.colors.backgroundSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: theme.radius.s)
                                    .stroke(isWeightFocused ? theme.colors.accent : Color.clear, lineWidth: 2)
                            )
                    )
                    .onChange(of: weightText) { _, newValue in
                        if let weight = Double(newValue) {
                            set.weight = weight
                        }
                    }
                
                Button(action: {
                    let currentWeight = set.weight ?? previousSet?.weight ?? 0
                    set.weight = currentWeight + 2.5
                    updateWeightText()
                    HapticManager.shared.impact(.light)
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.colors.textSecondary)
                        .frame(width: 24, height: 24)
                        .background(theme.colors.backgroundSecondary)
                        .cornerRadius(theme.radius.s)
                }
            }
            
            Text("×")
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
            
            // Reps input
            HStack(spacing: 4) {
                Button(action: {
                    if set.reps > 0 {
                        set.reps -= 1
                        updateRepsText()
                        HapticManager.shared.impact(.light)
                    }
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.colors.textSecondary)
                        .frame(width: 24, height: 24)
                        .background(theme.colors.backgroundSecondary)
                        .cornerRadius(theme.radius.s)
                }
                
                TextField("0", text: $repsText)
                    .focused($isRepsFocused)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .font(theme.typography.body)
                    .frame(width: 40)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: theme.radius.s)
                            .fill(theme.colors.backgroundSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: theme.radius.s)
                                    .stroke(isRepsFocused ? theme.colors.accent : Color.clear, lineWidth: 2)
                            )
                    )
                    .onChange(of: repsText) { _, newValue in
                        if let reps = Int(newValue) {
                            set.reps = reps
                        }
                    }
                
                Button(action: {
                    set.reps += 1
                    updateRepsText()
                    HapticManager.shared.impact(.light)
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.colors.textSecondary)
                        .frame(width: 24, height: 24)
                        .background(theme.colors.backgroundSecondary)
                        .cornerRadius(theme.radius.s)
                }
            }
            
            Spacer()
            
            // Complete button
            Button(action: {
                set.isCompleted.toggle()
                if set.isCompleted {
                    set.timestamp = Date()
                    onComplete()
                }
                HapticManager.shared.impact(set.isCompleted ? .medium : .light)
            }) {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(set.isCompleted ? theme.colors.success : theme.colors.textSecondary)
                    .animation(.easeInOut(duration: 0.2), value: set.isCompleted)
            }
        }
        .padding(.horizontal, theme.spacing.s)
        .padding(.vertical, theme.spacing.s)
        .background(backgroundColor)
        .cornerRadius(theme.radius.s)
        .onAppear {
            setupInitialValues()
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            isWeightFocused = false
            isRepsFocused = false
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
        // Set initial weight
        if let weight = set.weight {
            weightText = String(format: "%.1f", weight).replacingOccurrences(of: ".0", with: "")
        } else if let prevWeight = previousSet?.weight {
            set.weight = prevWeight
            weightText = String(format: "%.1f", prevWeight).replacingOccurrences(of: ".0", with: "")
        }
        
        // Set initial reps
        repsText = String(set.reps)
    }
    
    private func updateWeightText() {
        if let weight = set.weight {
            weightText = String(format: "%.1f", weight).replacingOccurrences(of: ".0", with: "")
        }
    }
    
    private func updateRepsText() {
        repsText = String(set.reps)
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