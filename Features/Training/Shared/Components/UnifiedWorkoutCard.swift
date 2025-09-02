import SwiftUI
import SwiftData

enum WorkoutCardStyle {
    case compact
    case detailed
    case hero
}

struct UnifiedWorkoutCard: View {
    @Environment(\.theme) private var theme
    let title: String
    let subtitle: String?
    let description: String?
    let primaryStats: [WorkoutStat]
    let secondaryInfo: [String]
    let isFavorite: Bool
    let cardStyle: WorkoutCardStyle
    let primaryAction: () -> Void
    let secondaryAction: (() -> Void)?
    
    // MARK: - Performance Optimizations
    private var hasSecondaryAction: Bool { secondaryAction != nil }
    private var hasDescription: Bool { description?.isEmpty == false }
    private var hasSubtitle: Bool { subtitle?.isEmpty == false }
    private var hasSecondaryInfo: Bool { !secondaryInfo.isEmpty }
    private var displayedPrimaryStats: [WorkoutStat] { Array(primaryStats.prefix(3)) } // Limit stats for performance
    
    init(
        title: String,
        subtitle: String? = nil,
        description: String? = nil,
        primaryStats: [WorkoutStat] = [],
        secondaryInfo: [String] = [],
        isFavorite: Bool = false,
        cardStyle: WorkoutCardStyle = .detailed,
        primaryAction: @escaping () -> Void,
        secondaryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.primaryStats = primaryStats
        self.secondaryInfo = secondaryInfo
        self.isFavorite = isFavorite
        self.cardStyle = cardStyle
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
    }
    
    var body: some View {
        switch cardStyle {
        case .compact:
            compactCard
        case .detailed:
            detailedCard
        case .hero:
            heroCard
        }
    }
    
    private var compactCard: some View {
        Button(action: primaryAction) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(theme.typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(theme.colors.textPrimary)
                        .lineLimit(1)
                    
                    if hasSubtitle {
                        Text(subtitle!)
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
                
                Spacer()
                
                if isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(theme.colors.warning)
                }
                
                if hasSecondaryAction {
                    Button(action: secondaryAction!) {
                        Image(systemName: "play.circle.fill")
                            .font(.title3)
                            .foregroundColor(theme.colors.accent)
                    }
                }
            }
            .padding(theme.spacing.m)
            .background(theme.colors.cardBackground)
            .cornerRadius(theme.radius.m)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var detailedCard: some View {
        Button(action: primaryAction) {
            VStack(alignment: .leading, spacing: theme.spacing.s) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(theme.typography.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.colors.textPrimary)
                        
                        if hasSubtitle {
                            Text(subtitle!)
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                        
                        if hasDescription {
                            Text(description!)
                                .font(theme.typography.body)
                                .foregroundColor(theme.colors.textSecondary)
                                .lineLimit(2)
                                .padding(.top, 2)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: theme.spacing.s) {
                        if isFavorite {
                            Image(systemName: "star.fill")
                                .font(.body)
                                .foregroundColor(theme.colors.warning)
                        }
                        
                        if let action = secondaryAction {
                            Button(action: action) {
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(theme.colors.accent)
                            }
                        }
                    }
                }
                
                // Stats
                if !displayedPrimaryStats.isEmpty {
                    HStack(spacing: theme.spacing.l) {
                        ForEach(displayedPrimaryStats) { stat in
                            WorkoutStatView(stat: stat)
                        }
                        Spacer()
                    }
                }
                
                // Secondary Info
                if hasSecondaryInfo {
                    HStack(spacing: theme.spacing.m) {
                        ForEach(secondaryInfo, id: \.self) { info in
                            Label(info, systemImage: "circle.fill")
                                .font(.caption2)
                                .foregroundColor(theme.colors.textSecondary)
                                .labelStyle(CustomLabelStyle())
                        }
                        Spacer()
                    }
                }
            }
            .padding(theme.spacing.m)
            .background(theme.colors.cardBackground)
            .cornerRadius(theme.radius.m)
            .shadow(color: theme.shadows.card.opacity(0.05), radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var heroCard: some View {
        Button(action: primaryAction) {
            VStack(spacing: 0) {
                // Gradient Header
                LinearGradient(
                    gradient: Gradient(colors: [
                        theme.colors.accent.opacity(0.3),
                        theme.colors.accent.opacity(0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 80)
                .overlay(
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .font(theme.typography.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            if let subtitle = subtitle {
                                Text(subtitle)
                                    .font(theme.typography.body)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        Spacer()
                        
                        if isFavorite {
                            Image(systemName: "star.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                )
                
                // Content
                VStack(alignment: .leading, spacing: theme.spacing.m) {
                    if let description = description {
                        Text(description)
                            .font(theme.typography.body)
                            .foregroundColor(theme.colors.textSecondary)
                            .lineLimit(3)
                    }
                    
                    if !displayedPrimaryStats.isEmpty {
                        HStack(spacing: theme.spacing.xl) {
                            ForEach(displayedPrimaryStats) { stat in
                                WorkoutStatView(stat: stat, style: .large)
                            }
                        }
                    }
                    
                    if hasSecondaryAction {
                        let action = secondaryAction!
                        Button(action: action) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                Text("Start Workout")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, theme.spacing.m)
                            .background(theme.colors.accent)
                            .cornerRadius(theme.radius.m)
                        }
                    }
                }
                .padding(theme.spacing.m)
            }
            .background(theme.colors.cardBackground)
            .cornerRadius(theme.radius.l)
            .shadow(color: theme.shadows.card.opacity(0.1), radius: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WorkoutStat: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    let icon: String?
    
    init(label: String, value: String, icon: String? = nil) {
        self.label = label
        self.value = value
        self.icon = icon
    }
}

private struct WorkoutStatView: View {
    @Environment(\.theme) private var theme
    let stat: WorkoutStat
    var style: StatStyle = .normal
    
    enum StatStyle {
        case normal, large
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let icon = stat.icon {
                Image(systemName: icon)
                    .font(style == .large ? .caption : .caption2)
                    .foregroundColor(theme.colors.accent)
            }
            
            Text(stat.value)
                .font(style == .large ? theme.typography.headline : theme.typography.body)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
            
            Text(stat.label)
                .font(style == .large ? theme.typography.caption : .caption2)
                .foregroundColor(theme.colors.textSecondary)
        }
    }
}

private struct CustomLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 2) {
            configuration.icon
                .font(.system(size: 3))
            configuration.title
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        UnifiedWorkoutCard(
            title: "Push Day",
            subtitle: "Chest, Shoulders, Triceps",
            description: "Complete upper body push workout focusing on strength",
            primaryStats: [
                WorkoutStat(label: "Duration", value: "45 min", icon: "clock"),
                WorkoutStat(label: "Exercises", value: "8", icon: "dumbbell"),
                WorkoutStat(label: "Volume", value: "12,500 kg", icon: "scalemass")
            ],
            secondaryInfo: ["Intermediate", "Barbell Required"],
            isFavorite: true,
            cardStyle: .detailed,
            primaryAction: { print("Card tapped") },
            secondaryAction: { print("Start workout") }
        )
        
        UnifiedWorkoutCard(
            title: "Quick HIIT",
            subtitle: "20 min • High Intensity",
            cardStyle: .compact,
            primaryAction: { print("Compact card") }
        )
    }
    .padding()
}