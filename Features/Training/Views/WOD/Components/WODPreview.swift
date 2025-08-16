import SwiftUI

struct WODPreview: View {
    let wodName: String
    let wodType: WODType
    let repScheme: [Int]
    let timeCap: String
    let movements: [MovementData]
    
    @Environment(\.theme) private var theme
    @State private var isExpanded = true
    
    struct MovementData {
        let name: String
        let reps: String
        let rxWeightMale: String
        let rxWeightFemale: String
    }
    
    private var formattedRepScheme: String {
        if repScheme.count == 1 {
            return "\(repScheme[0]) Rounds"
        }
        return repScheme.map { String($0) }.joined(separator: "-")
    }
    
    private var formattedTimeCap: String? {
        guard !timeCap.isEmpty, let minutes = Int(timeCap) else { return nil }
        return "\(minutes) minutes"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            // Header
            HStack {
                Label("WOD Preview", systemImage: "eye")
                    .font(theme.typography.headline)
                    .foregroundColor(theme.colors.textPrimary)
                
                Spacer()
                
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            
            if isExpanded {
                // WOD Card Preview
                VStack(alignment: .leading, spacing: theme.spacing.m) {
                    // Name and Type
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(wodName.isEmpty ? "Untitled WOD" : wodName)
                                .font(theme.typography.title3)
                                .fontWeight(.bold)
                                .foregroundColor(theme.colors.textPrimary)
                            
                            Text(wodType.displayName)
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        // Type Badge
                        Text(wodType.rawValue.uppercased())
                            .font(theme.typography.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, theme.spacing.s)
                            .padding(.vertical, 4)
                            .background(typeColor.opacity(0.2))
                            .foregroundColor(typeColor)
                            .cornerRadius(theme.radius.s)
                    }
                    
                    // Rep Scheme or Time
                    HStack(spacing: theme.spacing.l) {
                        if !repScheme.isEmpty && wodType == .forTime {
                            HStack(spacing: theme.spacing.s) {
                                Image(systemName: "repeat")
                                    .foregroundColor(theme.colors.accent)
                                Text(formattedRepScheme)
                                    .font(theme.typography.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(theme.colors.accent)
                            }
                        }
                        
                        if let timeCapText = formattedTimeCap, (wodType == .amrap || wodType == .emom) {
                            HStack(spacing: theme.spacing.s) {
                                Image(systemName: "clock")
                                    .foregroundColor(theme.colors.warning)
                                Text(timeCapText)
                                    .font(theme.typography.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(theme.colors.warning)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Movements
                    if movements.isEmpty {
                        Text("No movements added")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                            .italic()
                    } else {
                        VStack(alignment: .leading, spacing: theme.spacing.s) {
                            ForEach(Array(movements.enumerated()), id: \.offset) { index, movement in
                                MovementPreviewRow(
                                    index: index + 1,
                                    movement: movement,
                                    repScheme: repScheme,
                                    wodType: wodType
                                )
                            }
                        }
                    }
                    
                    // Summary
                    if !movements.isEmpty {
                        VStack(alignment: .leading, spacing: theme.spacing.s) {
                            Divider()
                            
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(theme.colors.textSecondary)
                                
                                Text(generateSummary())
                                    .font(theme.typography.caption)
                                    .foregroundColor(theme.colors.textSecondary)
                            }
                        }
                    }
                }
                .padding()
                .background(theme.colors.backgroundSecondary)
                .cornerRadius(theme.radius.m)
            }
        }
    }
    
    private var typeColor: Color {
        switch wodType {
        case .forTime:
            return theme.colors.accent
        case .amrap:
            return theme.colors.warning
        case .emom:
            return theme.colors.success
        case .custom:
            return theme.colors.textSecondary
        }
    }
    
    private func generateSummary() -> String {
        switch wodType {
        case .forTime:
            if repScheme.count == 1 {
                return "\(repScheme[0]) rounds for time"
            } else if !repScheme.isEmpty {
                return "\(formattedRepScheme) reps of each movement"
            }
            return "Complete for time"
            
        case .amrap:
            if let time = formattedTimeCap {
                return "As many rounds as possible in \(time)"
            }
            return "AMRAP"
            
        case .emom:
            if let time = formattedTimeCap {
                return "Every minute on the minute for \(time)"
            }
            return "EMOM"
            
        case .custom:
            return "Custom workout format"
        }
    }
}

// MARK: - Movement Preview Row
private struct MovementPreviewRow: View {
    let index: Int
    let movement: WODPreview.MovementData
    let repScheme: [Int]
    let wodType: WODType
    
    @Environment(\.theme) private var theme
    
    private var displayReps: String {
        // If movement has specific reps, use those
        if !movement.reps.isEmpty {
            return movement.reps
        }
        
        // Otherwise use rep scheme
        if wodType == .forTime && !repScheme.isEmpty {
            if repScheme.count == 1 {
                // Rounds format - no specific rep count per movement
                return ""
            } else {
                // Variable rep scheme (21-15-9, etc)
                return repScheme.map { String($0) }.joined(separator: "-")
            }
        }
        
        return ""
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: theme.spacing.m) {
            Text("\(index).")
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
                .frame(width: 20, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: theme.spacing.s) {
                    if !displayReps.isEmpty {
                        Text(displayReps)
                            .font(theme.typography.body)
                            .fontWeight(.medium)
                            .foregroundColor(theme.colors.accent)
                    }
                    
                    Text(movement.name)
                        .font(theme.typography.body)
                        .foregroundColor(theme.colors.textPrimary)
                }
                
                if !movement.rxWeightMale.isEmpty || !movement.rxWeightFemale.isEmpty {
                    HStack(spacing: theme.spacing.s) {
                        if !movement.rxWeightMale.isEmpty {
                            Text("M: \(movement.rxWeightMale)")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                        
                        if !movement.rxWeightFemale.isEmpty {
                            Text("F: \(movement.rxWeightFemale)")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                    }
                }
            }
            
            Spacer()
        }
    }
}