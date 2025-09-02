import SwiftUI

/**
 * Interactive body visualization showing strength levels for different muscle groups.
 * 
 * Displays a simplified body outline with color-coded muscle group indicators
 * based on strength test results. Reusable across test results and dashboard.
 */
struct BodyStrengthVisualization: View {
    // MARK: - Properties
    let results: [StrengthTestResult]
    let size: CGFloat
    let isInteractive: Bool
    let onMuscleGroupTap: ((MuscleGroup) -> Void)?
    
    @State private var selectedMuscleGroup: MuscleGroup?
    @Environment(\.theme) private var theme
    
    // MARK: - Initialization
    init(
        results: [StrengthTestResult],
        size: CGFloat = 200,
        isInteractive: Bool = true,
        onMuscleGroupTap: ((MuscleGroup) -> Void)? = nil
    ) {
        self.results = results
        self.size = size
        self.isInteractive = isInteractive
        self.onMuscleGroupTap = onMuscleGroupTap
    }
    
    var body: some View {
        ZStack {
            // Body outline
            bodyOutline
            
            // Muscle group indicators
            ForEach(MuscleGroup.allCases, id: \.self) { muscleGroup in
                muscleGroupIndicator(for: muscleGroup)
            }
            
            // Selected muscle group overlay
            if let selectedMuscleGroup = selectedMuscleGroup {
                muscleGroupOverlay(for: selectedMuscleGroup)
            }
        }
        .frame(width: size, height: size * 1.2)
        .background(
            RoundedRectangle(cornerRadius: theme.radius.l)
                .fill(theme.colors.cardBackground)
                .shadow(color: theme.shadows.card.opacity(0.05), radius: 2)
        )
    }
    
    // MARK: - Body Outline
    
    private var bodyOutline: some View {
        ZStack {
            // Head
            Circle()
                .stroke(theme.colors.textSecondary.opacity(0.3), lineWidth: 2)
                .frame(width: size * 0.15, height: size * 0.15)
                .offset(y: -size * 0.45)
            
            // Torso
            RoundedRectangle(cornerRadius: size * 0.05)
                .stroke(theme.colors.textSecondary.opacity(0.3), lineWidth: 2)
                .frame(width: size * 0.35, height: size * 0.45)
                .offset(y: -size * 0.1)
            
            // Arms
            ForEach([-1, 1], id: \.self) { side in
                RoundedRectangle(cornerRadius: size * 0.02)
                    .stroke(theme.colors.textSecondary.opacity(0.3), lineWidth: 2)
                    .frame(width: size * 0.08, height: size * 0.25)
                    .offset(x: CGFloat(side) * size * 0.25, y: -size * 0.05)
            }
            
            // Legs
            ForEach([-1, 1], id: \.self) { side in
                RoundedRectangle(cornerRadius: size * 0.03)
                    .stroke(theme.colors.textSecondary.opacity(0.3), lineWidth: 2)
                    .frame(width: size * 0.12, height: size * 0.35)
                    .offset(x: CGFloat(side) * size * 0.08, y: size * 0.25)
            }
        }
    }
    
    // MARK: - Muscle Group Indicators
    
    @ViewBuilder
    private func muscleGroupIndicator(for muscleGroup: MuscleGroup) -> some View {
        let result = results.first { $0.exerciseTypeEnum.muscleGroup == muscleGroup }
        let position = muscleGroupPosition(for: muscleGroup)
        let color = muscleGroupColor(for: result)
        
        Button {
            if isInteractive {
                handleMuscleGroupTap(muscleGroup)
            }
        } label: {
            ZStack {
                // Background circle
                Circle()
                    .fill(color.opacity(0.8))
                    .frame(width: size * 0.12, height: size * 0.12)
                
                // Muscle group emoji
                Text(muscleGroup.emoji)
                    .font(.system(size: size * 0.05))
                
                // Level indicator ring (if result exists)
                if let result = result {
                    Circle()
                        .trim(from: 0, to: result.percentileScore)
                        .stroke(color, lineWidth: 2)
                        .frame(width: size * 0.14, height: size * 0.14)
                        .rotationEffect(.degrees(-90))
                }
            }
            .scaleEffect(selectedMuscleGroup == muscleGroup ? 1.2 : 1.0)
            .animation(.spring(duration: 0.3), value: selectedMuscleGroup)
        }
        .buttonStyle(.plain)
        .disabled(!isInteractive)
        .offset(x: position.x, y: position.y)
    }
    
    // MARK: - Muscle Group Overlay
    
    @ViewBuilder
    private func muscleGroupOverlay(for muscleGroup: MuscleGroup) -> some View {
        if let result = results.first(where: { $0.exerciseTypeEnum.muscleGroup == muscleGroup }) {
            VStack(spacing: theme.spacing.xs) {
                Text(muscleGroup.name)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(result.strengthLevelEnum.name)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(theme.colors.textSecondary)
                
                Text(result.displayValue)
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundColor(theme.colors.accent)
            }
            .padding(theme.spacing.s)
            .background(
                RoundedRectangle(cornerRadius: theme.radius.s)
                    .fill(theme.colors.cardBackground)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            .offset(y: -size * 0.6)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
    
    // MARK: - Helper Methods
    
    private func muscleGroupPosition(for muscleGroup: MuscleGroup) -> CGPoint {
        switch muscleGroup {
        case .chest:
            return CGPoint(x: 0, y: -size * 0.15) // Center chest
        case .shoulders:
            return CGPoint(x: size * 0.25, y: -size * 0.25) // Right shoulder
        case .back:
            return CGPoint(x: -size * 0.25, y: -size * 0.25) // Left shoulder (representing back)
        case .legs:
            return CGPoint(x: 0, y: size * 0.15) // Center legs
        case .hips:
            return CGPoint(x: 0, y: size * 0.05) // Lower torso
        }
    }
    
    private func muscleGroupColor(for result: StrengthTestResult?) -> Color {
        guard let result = result else {
            return theme.colors.textSecondary.opacity(0.3)
        }
        
        switch result.strengthLevelEnum.color {
        case "red":
            return .red
        case "orange":
            return .orange
        case "yellow":
            return .yellow
        case "green":
            return .green
        case "blue":
            return .blue
        case "purple":
            return .purple
        default:
            return .gray
        }
    }
    
    private func handleMuscleGroupTap(_ muscleGroup: MuscleGroup) {
        if selectedMuscleGroup == muscleGroup {
            selectedMuscleGroup = nil
        } else {
            selectedMuscleGroup = muscleGroup
        }
        
        onMuscleGroupTap?(muscleGroup)
    }
}

// MARK: - Compact Dashboard Version

/**
 * Smaller version for dashboard cards showing overall strength profile.
 */
struct CompactBodyVisualization: View {
    let results: [StrengthTestResult]
    let size: CGFloat
    
    @Environment(\.theme) private var theme
    
    init(results: [StrengthTestResult], size: CGFloat = 80) {
        self.results = results
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Simplified body outline
            VStack(spacing: 2) {
                // Head
                Circle()
                    .fill(theme.colors.textSecondary.opacity(0.2))
                    .frame(width: size * 0.2, height: size * 0.2)
                
                // Torso with muscle indicators
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.05)
                        .fill(theme.colors.textSecondary.opacity(0.1))
                        .frame(width: size * 0.6, height: size * 0.7)
                    
                    // Muscle group dots
                    ForEach(MuscleGroup.allCases, id: \.self) { muscleGroup in
                        if let result = results.first(where: { $0.exerciseTypeEnum.muscleGroup == muscleGroup }) {
                            Circle()
                                .fill(muscleGroupColor(for: result))
                                .frame(width: size * 0.08, height: size * 0.08)
                                .offset(compactMusclePosition(for: muscleGroup))
                        }
                    }
                }
            }
        }
        .frame(width: size, height: size * 1.2)
    }
    
    private func compactMusclePosition(for muscleGroup: MuscleGroup) -> CGSize {
        switch muscleGroup {
        case .chest:
            return CGSize(width: 0, height: -size * 0.15)
        case .shoulders:
            return CGSize(width: size * 0.15, height: -size * 0.2)
        case .back:
            return CGSize(width: -size * 0.15, height: -size * 0.2)
        case .legs:
            return CGSize(width: 0, height: size * 0.15)
        case .hips:
            return CGSize(width: 0, height: size * 0.05)
        }
    }
    
    private func muscleGroupColor(for result: StrengthTestResult) -> Color {
        switch result.strengthLevelEnum.color {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        default: return .gray
        }
    }
}

// MARK: - Legend Component

/**
 * Color-coded legend showing strength levels.
 */
struct StrengthLevelLegend: View {
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            Text("strength.legend.title".localized)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: theme.spacing.xs) {
                ForEach(StrengthLevel.allCases, id: \.self) { level in
                    HStack(spacing: theme.spacing.xs) {
                        Circle()
                            .fill(levelColor(for: level))
                            .frame(width: 12, height: 12)
                        
                        Text(level.name)
                            .font(.system(.caption2, design: .rounded))
                            .foregroundColor(theme.colors.textSecondary)
                        
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .padding(theme.spacing.m)
        .background(theme.colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.m))
    }
    
    private func levelColor(for level: StrengthLevel) -> Color {
        switch level.color {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        default: return .gray
        }
    }
}

// MARK: - Preview

#Preview("Body Strength Visualization") {
    let sampleResults = [
        StrengthTestResult(exerciseType: .benchPress, value: 80, strengthLevel: .intermediate, percentileScore: 0.6),
        StrengthTestResult(exerciseType: .pullUp, value: 10, strengthLevel: .advanced, percentileScore: 0.8),
        StrengthTestResult(exerciseType: .backSquat, value: 100, strengthLevel: .advanced, percentileScore: 0.75)
    ]
    
    return VStack(spacing: 20) {
        BodyStrengthVisualization(results: sampleResults)
        
        HStack(spacing: 20) {
            CompactBodyVisualization(results: sampleResults)
            StrengthLevelLegend()
        }
    }
    .padding()
}