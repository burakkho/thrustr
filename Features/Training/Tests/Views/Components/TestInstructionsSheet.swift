import SwiftUI

/**
 * Modal sheet showing exercise instructions and form tips.
 */
struct TestInstructionsSheet: View {
    let exerciseType: StrengthExerciseType
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.l) {
                    // Header
                    VStack(spacing: theme.spacing.m) {
                        Image(systemName: exerciseType.icon)
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(theme.colors.accent)
                        
                        VStack(spacing: theme.spacing.xs) {
                            Text(exerciseType.name)
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .foregroundColor(theme.colors.textPrimary)
                            
                            Text("\(exerciseType.muscleGroup.emoji) \(exerciseType.muscleGroup.name)")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(theme.colors.textSecondary)
                        }
                    }
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: theme.spacing.m) {
                        Text("strength.instructions.title".localized)
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                            .foregroundColor(theme.colors.textPrimary)
                        
                        Text(exerciseType.instructions)
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(theme.colors.textPrimary)
                            .lineSpacing(4)
                    }
                    
                    // Safety tips
                    VStack(alignment: .leading, spacing: theme.spacing.s) {
                        Text("strength.instructions.safetyTitle".localized)
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                            .foregroundColor(theme.colors.textPrimary)
                        
                        VStack(alignment: .leading, spacing: theme.spacing.xs) {
                            SafetyTip(text: "strength.instructions.warmUp".localized)
                            SafetyTip(text: "strength.instructions.properForm".localized)
                            SafetyTip(text: "strength.instructions.spotter".localized)
                        }
                    }
                }
                .padding(theme.spacing.l)
            }
            .navigationTitle("strength.instructions.navigationTitle".localized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.done".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Safety Tip Component

private struct SafetyTip: View {
    let text: String
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(alignment: .top, spacing: theme.spacing.s) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundColor(.orange)
                .frame(width: 16, alignment: .top)
                .padding(.top, 2)
            
            Text(text)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(theme.colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Preview

#Preview("Test Instructions Sheet") {
    TestInstructionsSheet(exerciseType: .benchPress)
}