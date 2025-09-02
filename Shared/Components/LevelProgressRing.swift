import SwiftUI

/**
 * Circular progress ring showing strength level with color-coded visualization.
 * 
 * Displays current strength level as a colored ring with percentage fill
 * and level emoji indicator.
 */
struct LevelProgressRing: View {
    // MARK: - Properties
    let level: StrengthLevel
    let percentileInLevel: Double
    let size: CGFloat
    let lineWidth: CGFloat
    let showPercentage: Bool
    
    @Environment(\.theme) private var theme
    
    // MARK: - Initialization
    init(
        level: StrengthLevel,
        percentileInLevel: Double,
        size: CGFloat = 80,
        lineWidth: CGFloat = 8,
        showPercentage: Bool = true
    ) {
        self.level = level
        self.percentileInLevel = max(0.0, min(1.0, percentileInLevel))
        self.size = size
        self.lineWidth = lineWidth
        self.showPercentage = showPercentage
    }
    
    var body: some View {
        ZStack {
            // Background circle with subtle shadow
            Circle()
                .stroke(backgroundGradient, lineWidth: lineWidth)
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            
            // Progress circle with gradient
            Circle()
                .trim(from: 0, to: percentileInLevel)
                .stroke(
                    levelGradient,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 1.2, dampingFraction: 0.8), value: percentileInLevel)
            
            // Glow effect for higher levels
            if level.rawValue >= 3 {
                Circle()
                    .trim(from: 0, to: percentileInLevel)
                    .stroke(
                        levelColor.opacity(0.3),
                        style: StrokeStyle(
                            lineWidth: lineWidth + 2,
                            lineCap: .round
                        )
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                    .blur(radius: 3)
                    .animation(.spring(response: 1.2, dampingFraction: 0.8), value: percentileInLevel)
            }
            
            // Center content with enhanced styling
            VStack(spacing: 2) {
                Text(level.emoji)
                    .font(.system(size: size * 0.28, weight: .medium))
                    .scaleEffect(showPercentage ? 0.9 : 1.0)
                
                if showPercentage {
                    Text("\(Int(percentileInLevel * 100))%")
                        .font(.system(size: size * 0.14, weight: .bold, design: .rounded))
                        .foregroundColor(theme.colors.textPrimary)
                        .opacity(0.9)
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var levelColor: Color {
        switch level {
        case .beginner:
            return Color(red: 0.91, green: 0.30, blue: 0.24) // Modern red
        case .novice:
            return Color(red: 0.98, green: 0.55, blue: 0.09) // Modern orange
        case .intermediate:
            return Color(red: 0.95, green: 0.77, blue: 0.06) // Modern yellow
        case .advanced:
            return Color(red: 0.20, green: 0.78, blue: 0.35) // Modern green
        case .expert:
            return Color(red: 0.20, green: 0.60, blue: 0.86) // Modern blue
        case .elite:
            return Color(red: 0.69, green: 0.32, blue: 0.87) // Modern purple
        }
    }
    
    private var levelSecondaryColor: Color {
        switch level {
        case .beginner:
            return Color(red: 0.96, green: 0.45, blue: 0.40)
        case .novice:
            return Color(red: 0.99, green: 0.70, blue: 0.30)
        case .intermediate:
            return Color(red: 0.97, green: 0.85, blue: 0.25)
        case .advanced:
            return Color(red: 0.40, green: 0.85, blue: 0.55)
        case .expert:
            return Color(red: 0.40, green: 0.75, blue: 0.92)
        case .elite:
            return Color(red: 0.80, green: 0.50, blue: 0.93)
        }
    }
    
    private var levelGradient: AngularGradient {
        AngularGradient(
            colors: [levelColor, levelSecondaryColor, levelColor],
            center: .center,
            angle: .degrees(0)
        )
    }
    
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [levelColor.opacity(0.1), levelColor.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

/**
 * Compact version of level progress ring for lists and cards.
 */
struct CompactLevelRing: View {
    let level: StrengthLevel
    let percentileInLevel: Double
    let size: CGFloat
    
    init(
        level: StrengthLevel,
        percentileInLevel: Double,
        size: CGFloat = 40
    ) {
        self.level = level
        self.percentileInLevel = percentileInLevel
        self.size = size
    }
    
    var body: some View {
        LevelProgressRing(
            level: level,
            percentileInLevel: percentileInLevel,
            size: size,
            lineWidth: size * 0.1, // Proportional line width
            showPercentage: false
        )
    }
}

/**
 * Large version for detailed views and results.
 */
struct DetailedLevelRing: View {
    let level: StrengthLevel
    let percentileInLevel: Double
    let exerciseType: StrengthExerciseType
    let size: CGFloat
    
    @Environment(\.theme) private var theme
    @State private var animateScale = false
    
    init(
        level: StrengthLevel,
        percentileInLevel: Double,
        exerciseType: StrengthExerciseType,
        size: CGFloat = 120
    ) {
        self.level = level
        self.percentileInLevel = percentileInLevel
        self.exerciseType = exerciseType
        self.size = size
    }
    
    var body: some View {
        VStack(spacing: theme.spacing.l) {
            // Enhanced ring with background glow
            ZStack {
                // Outer glow for elite levels
                if level.rawValue >= 4 {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [levelColor.opacity(0.2), Color.clear],
                                center: .center,
                                startRadius: size * 0.4,
                                endRadius: size * 0.7
                            )
                        )
                        .frame(width: size * 1.4, height: size * 1.4)
                        .scaleEffect(animateScale ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateScale)
                }
                
                LevelProgressRing(
                    level: level,
                    percentileInLevel: percentileInLevel,
                    size: size,
                    lineWidth: size * 0.08,
                    showPercentage: true
                )
            }
            .onAppear {
                animateScale = true
            }
            
            // Level information with improved styling
            VStack(spacing: theme.spacing.s) {
                HStack {
                    Text(level.name)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text(level.emoji)
                        .font(.title3)
                }
                
                HStack(spacing: theme.spacing.xs) {
                    Text(exerciseType.muscleGroup.emoji)
                        .font(.subheadline)
                    
                    Text(exerciseType.muscleGroup.name)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
    }
    
    private var levelColor: Color {
        switch level {
        case .beginner: return Color(red: 0.91, green: 0.30, blue: 0.24)
        case .novice: return Color(red: 0.98, green: 0.55, blue: 0.09)
        case .intermediate: return Color(red: 0.95, green: 0.77, blue: 0.06)
        case .advanced: return Color(red: 0.20, green: 0.78, blue: 0.35)
        case .expert: return Color(red: 0.20, green: 0.60, blue: 0.86)
        case .elite: return Color(red: 0.69, green: 0.32, blue: 0.87)
        }
    }
}

// MARK: - Multiple Exercise Overview

/**
 * Grid of compact level rings for showing all exercise levels at once.
 */
struct ExerciseLevelGrid: View {
    let results: [StrengthTestResult]
    
    @Environment(\.theme) private var theme
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: theme.spacing.m) {
            ForEach(StrengthExerciseType.allCases) { exerciseType in
                VStack(spacing: theme.spacing.s) {
                    if let result = results.first(where: { $0.exerciseTypeEnum == exerciseType }) {
                        CompactLevelRing(
                            level: result.strengthLevelEnum,
                            percentileInLevel: result.percentileScore,
                            size: 35
                        )
                        
                        Text(result.displayValue)
                            .font(.system(.caption2, design: .rounded, weight: .medium))
                            .foregroundColor(theme.colors.textPrimary)
                    } else {
                        CompactLevelRing(
                            level: .beginner,
                            percentileInLevel: 0.0,
                            size: 35
                        )
                        .opacity(0.3)
                        
                        Text("--")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    
                    Text(exerciseType.muscleGroup.emoji)
                        .font(.system(size: 16))
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Preview

#Preview("Level Progress Rings") {
    ScrollView {
        VStack(spacing: 40) {
            // Compact rings comparison
            VStack(spacing: 20) {
                Text("Compact Level Rings")
                    .font(.headline)
                
                HStack(spacing: 20) {
                    CompactLevelRing(level: .beginner, percentileInLevel: 0.3, size: 50)
                    CompactLevelRing(level: .intermediate, percentileInLevel: 0.7, size: 50)
                    CompactLevelRing(level: .elite, percentileInLevel: 0.9, size: 50)
                }
            }
            
            // Detailed ring
            VStack(spacing: 20) {
                Text("Detailed Level Ring")
                    .font(.headline)
                
                DetailedLevelRing(
                    level: .advanced,
                    percentileInLevel: 0.65,
                    exerciseType: .benchPress,
                    size: 140
                )
            }
            
            // Exercise grid
            VStack(spacing: 20) {
                Text("Exercise Level Grid")
                    .font(.headline)
                
                ExerciseLevelGrid(results: [
                    StrengthTestResult(exerciseType: .benchPress, value: 80, strengthLevel: .intermediate, percentileScore: 0.6),
                    StrengthTestResult(exerciseType: .pullUp, value: 10, strengthLevel: .advanced, percentileScore: 0.8),
                    StrengthTestResult(exerciseType: .deadlift, value: 180, strengthLevel: .expert, percentileScore: 0.95)
                ])
            }
        }
        .padding()
    }
}