import SwiftUI
import SwiftData

struct QuickSetEditor: View {
    @Bindable var exerciseSet: ExerciseSet
    let setNumber: Int
    let onDelete: () -> Void
    
    @Environment(\.theme) private var theme
    @AppStorage("weightUnit") private var weightUnit: String = "kg"
    @FocusState private var focusedField: Field?
    
    enum Field {
        case weight, reps
    }
    
    var body: some View {
        HStack(spacing: theme.spacing.m) {
            // Set number
            Text("\(setNumber)")
                .font(theme.typography.caption)
                .fontWeight(.medium)
                .foregroundColor(theme.colors.textSecondary)
                .frame(width: 24)
            
            // Weight input
            HStack(spacing: theme.spacing.s) {
                TextField("0", value: $exerciseSet.weight, format: .number)
                    .textFieldStyle(.plain)
                    .font(theme.typography.body)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .frame(width: 60)
                    .padding(.vertical, theme.spacing.s)
                    .padding(.horizontal, theme.spacing.m)
                    .background(theme.colors.backgroundSecondary)
                    .cornerRadius(theme.radius.s)
                    .focused($focusedField, equals: .weight)
                    .keyboardType(.decimalPad)
                
                Text(weightUnit)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            // Multiply symbol
            Text("×")
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
            
            // Reps input
            HStack(spacing: theme.spacing.s) {
                TextField("0", value: $exerciseSet.reps, format: .number)
                    .textFieldStyle(.plain)
                    .font(theme.typography.body)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .frame(width: 50)
                    .padding(.vertical, theme.spacing.s)
                    .padding(.horizontal, theme.spacing.m)
                    .background(theme.colors.backgroundSecondary)
                    .cornerRadius(theme.radius.s)
                    .focused($focusedField, equals: .reps)
                    .keyboardType(.numberPad)
                
                Text(LocalizationKeys.Training.Set.reps.localized)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            Spacer()
            
            // Complete/Incomplete toggle
            Button(action: {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    exerciseSet.isCompleted.toggle()
                }
            }) {
                Image(systemName: exerciseSet.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(exerciseSet.isCompleted ? theme.colors.success : theme.colors.textSecondary.opacity(0.5))
            }
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(theme.colors.error)
            }
        }
        .padding(.horizontal, theme.spacing.m)
        .padding(.vertical, theme.spacing.s)
        .background(exerciseSet.isCompleted ? theme.colors.success.opacity(0.05) : Color.clear)
        .animation(.easeInOut(duration: 0.2), value: exerciseSet.isCompleted)
    }
}