import SwiftUI

/**
 * Comprehensive test results summary with analysis and recommendations.
 * 
 * Shows overall score, individual exercise breakdown, strength profile,
 * and actionable recommendations for training.
 */
struct TestResultSummary: View {
    // MARK: - Properties
    let strengthTest: StrengthTest
    let onShareTapped: () -> Void
    let onSaveTapped: () -> Void
    
    @State private var showingShareSheet = false
    @State private var animateResults = false
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.xxl) {
                // Hero Section with overall score
                heroSection
                
                // Key Metrics Cards
                metricsCardsSection
                
                // Individual exercise results
                exerciseResultsSection
                
                // Strength profile analysis
                strengthProfileSection
                
                // Strength Level Guide
                strengthLevelGuideSection
                
                // Recommendations
                recommendationsSection
                
                // Action buttons
                actionButtonsSection
                
                Spacer(minLength: theme.spacing.xl)
            }
            .padding(theme.spacing.l)
            .padding(.top, theme.spacing.m)
        }
        .background(theme.colors.backgroundSecondary)
        .onAppear {
            withAnimation(.spring(duration: 1.2).delay(0.2)) {
                animateResults = true
            }
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: theme.spacing.xl) {
            // Celebration header
            VStack(spacing: theme.spacing.l) {
                // Clean celebration design
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.colors.accent.opacity(0.15), theme.colors.accent.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .scaleEffect(animateResults ? 1.0 : 0.5)
                        .overlay(
                            Circle()
                                .stroke(theme.colors.accent.opacity(0.2), lineWidth: 2)
                        )
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(theme.colors.accent)
                        .scaleEffect(animateResults ? 1.0 : 0.3)
                }
                .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1), value: animateResults)
                
                VStack(spacing: theme.spacing.s) {
                    Text(TrainingKeys.Tests.testCompleted.localized)
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundColor(theme.colors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(TrainingKeys.Tests.performanceAnalysis.localized)
                        .font(.system(.title3, design: .rounded))
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(animateResults ? 1.0 : 0.0)
                .offset(y: animateResults ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.3), value: animateResults)
            }
            
            // Main Level Display
            modernLevelDisplay
                .scaleEffect(animateResults ? 1.0 : 0.8)
                .opacity(animateResults ? 1.0 : 0.0)
                .animation(.spring(duration: 0.8).delay(0.6), value: animateResults)
        }
        .padding(.vertical, theme.spacing.l)
        .background(
            RoundedRectangle(cornerRadius: theme.radius.xxl)
                .fill(theme.colors.cardBackground)
                .shadow(color: theme.shadows.card.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Exercise Results Section
    
    private var exerciseResultsSection: some View {
        VStack(spacing: theme.spacing.l) {
            // Section header
            HStack {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(TrainingKeys.Tests.exerciseDetails.localized)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text(TrainingKeys.Tests.exerciseAnalysisDesc.localized)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                Spacer()
            }
            
            // Exercise cards
            LazyVStack(spacing: theme.spacing.m) {
                ForEach(Array(strengthTest.results.enumerated()), id: \.element.exerciseType) { index, result in
                    ModernExerciseResultCard(result: result)
                        .opacity(animateResults ? 1.0 : 0.0)
                        .offset(x: animateResults ? 0 : 50)
                        .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.1 + 1.2), value: animateResults)
                }
            }
        }
    }
    
    // MARK: - Strength Profile Section
    
    private var strengthProfileSection: some View {
        VStack(spacing: theme.spacing.l) {
            // Section header
            HStack {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text("Kuvvet Profili")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text(TrainingKeys.Tests.bodyBalanceAnalysis.localized)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                Spacer()
                
                // Clean profile indicator
                ZStack {
                    Circle()
                        .fill(profileColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .fill(profileColor)
                        .frame(width: 16, height: 16)
                }
                .scaleEffect(animateResults ? 1.0 : 0.5)
                .animation(.spring(duration: 0.5).delay(1.5), value: animateResults)
            }
            
            // Profile insight card
            ModernProfileInsight(
                title: profileTitle,
                description: profileDescription,
                color: profileColor
            )
            .opacity(animateResults ? 1.0 : 0.0)
            .offset(y: animateResults ? 0 : 20)
            .animation(.easeOut(duration: 0.6).delay(1.6), value: animateResults)
        }
    }
    
    // MARK: - Strength Level Guide Section
    
    private var strengthLevelGuideSection: some View {
        VStack(spacing: theme.spacing.l) {
            // Section header
            HStack {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text("Seviye Rehberi")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text(TrainingKeys.Tests.strengthLevelsMeaning.localized)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                Spacer()
                
                // Guide indicator
                ZStack {
                    Circle()
                        .fill(theme.colors.accent.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "info.circle.fill")
                        .font(.system(.title3, weight: .medium))
                        .foregroundColor(theme.colors.accent)
                }
                .scaleEffect(animateResults ? 1.0 : 0.5)
                .animation(.spring(duration: 0.5).delay(2.0), value: animateResults)
            }
            
            // Level progression guide
            strengthLevelProgressionView
                .opacity(animateResults ? 1.0 : 0.0)
                .offset(y: animateResults ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(2.1), value: animateResults)
        }
    }
    
    // MARK: - Recommendations Section
    
    private var recommendationsSection: some View {
        VStack(spacing: theme.spacing.l) {
            // Section header
            HStack {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(TrainingKeys.Tests.recommendations.localized)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text(TrainingKeys.Tests.personalizedRecommendations.localized)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                Spacer()
                
                // Clean recommendations indicator
                ZStack {
                    Circle()
                        .fill(theme.colors.accent.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "lightbulb.fill")
                        .font(.system(.title3, weight: .medium))
                        .foregroundColor(theme.colors.accent)
                }
                .scaleEffect(animateResults ? 1.0 : 0.5)
                .animation(.spring(duration: 0.5).delay(1.8), value: animateResults)
            }
            
            // Recommendations list
            let recommendations = safeGenerateRecommendations()
            
            if recommendations.isEmpty {
                // Empty state for recommendations
                HStack {
                    Image(systemName: "lightbulb")
                        .foregroundColor(theme.colors.textSecondary)
                    Text(TrainingKeys.Tests.loadingRecommendations.localized)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(theme.colors.textSecondary)
                }
                .padding(.vertical, theme.spacing.l)
            } else {
                LazyVStack(spacing: theme.spacing.m) {
                    ForEach(Array(recommendations.enumerated()), id: \.offset) { index, recommendation in
                        ModernRecommendationItem(text: recommendation, index: index)
                            .opacity(animateResults ? 1.0 : 0.0)
                            .offset(x: animateResults ? 0 : 30)
                            .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.1 + 1.9), value: animateResults)
                    }
                }
            }
        }
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: theme.spacing.l) {
            // Primary action - Save results
            Button(action: onSaveTapped) {
                HStack(spacing: ButtonTokens.primary.iconSpacing) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.headline)
                    
                    Text(TrainingKeys.Tests.saveResults.localized)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle(.primary))
            .shadow(color: theme.colors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
            .scaleEffect(animateResults ? 1.0 : 0.95)
            .opacity(animateResults ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(2.3), value: animateResults)
            
            // Secondary actions
            HStack(spacing: theme.spacing.m) {
                // Share button
                Button(action: onShareTapped) {
                    HStack(spacing: ButtonTokens.secondary.iconSpacing) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.subheadline)
                        
                        Text("Share")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle(.secondary))
                
                // View details button  
                Button {
                    // Future: Navigate to detailed analysis
                } label: {
                    HStack(spacing: ButtonTokens.secondary.iconSpacing) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.subheadline)
                        
                        Text("Detaylar")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle(.secondary))
            }
            .opacity(animateResults ? 1.0 : 0.0)
            .offset(y: animateResults ? 0 : 20)
            .animation(.easeOut(duration: 0.6).delay(2.5), value: animateResults)
        }
    }
    
    // MARK: - Helper Properties
    
    private var profileTitle: String {
        switch strengthTest.strengthProfile {
        case "balanced":
            return "strength.profile.balanced.title".localized
        case "upper_dominant":
            return "strength.profile.upperDominant.title".localized
        case "lower_dominant":
            return "strength.profile.lowerDominant.title".localized
        default:
            return "strength.profile.unknown.title".localized
        }
    }
    
    private var profileDescription: String {
        switch strengthTest.strengthProfile {
        case "balanced":
            return "strength.profile.balanced.description".localized
        case "upper_dominant":
            return "strength.profile.upperDominant.description".localized
        case "lower_dominant":
            return "strength.profile.lowerDominant.description".localized
        default:
            return "strength.profile.unknown.description".localized
        }
    }
    
    private var profileColor: Color {
        guard !strengthTest.strengthProfile.isEmpty else { return .gray }
        
        switch strengthTest.strengthProfile {
        case "balanced":
            return .green
        case "upper_dominant":
            return .blue
        case "lower_dominant":
            return .orange
        default:
            return .gray
        }
    }
    
    // MARK: - Safe Helper Methods
    
    private func safeGenerateRecommendations() -> [String] {
        // Check if test is properly completed
        guard !strengthTest.results.isEmpty else {
            return ["Test sonuçları henüz hazır değil."]
        }
        
        let recommendations = TestScoringService.shared.generateRecommendations(for: strengthTest)
        
        if recommendations.isEmpty {
            return ["Analiziniz tamamlandığında öneriler burada görünecek."]
        }
        
        return recommendations
    }
    
    private var strengthLevelProgressionView: some View {
        VStack(spacing: theme.spacing.m) {
            // Current level highlight
            currentLevelCard
            
            // Level progression chart
            levelProgressionChart
            
            // Standards context
            standardsContextCard
        }
    }
    
    private var currentLevelCard: some View {
        let currentLevel = safeAverageStrengthLevel
        let currentLevelDescription = levelDescription(for: currentLevel)
        
        return HStack(spacing: theme.spacing.l) {
            // Level indicator
            ZStack {
                Circle()
                    .fill(levelBorderColor.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Circle()
                    .fill(levelBorderColor)
                    .frame(width: 20, height: 20)
            }
            
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text("Mevcut Seviyeniz: \(currentLevel.name)")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(currentLevelDescription)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(theme.colors.textSecondary)
                    .lineLimit(nil)
            }
            
            Spacer()
        }
        .padding(theme.spacing.l)
        .background(
            RoundedRectangle(cornerRadius: theme.radius.l)
                .fill(levelBorderColor.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radius.l)
                        .stroke(levelBorderColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var levelProgressionChart: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            Text(TrainingKeys.Tests.levelScale.localized)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundColor(theme.colors.textSecondary)
                .textCase(.uppercase)
            
            HStack(spacing: 2) {
                ForEach(StrengthLevel.allCases, id: \.self) { level in
                    levelProgressBar(for: level)
                }
            }
            .frame(height: 24)
        }
    }
    
    private func levelProgressBar(for level: StrengthLevel) -> some View {
        let isCurrentLevel = level == safeAverageStrengthLevel
        let color = colorForLevel(level)
        
        return VStack(spacing: theme.spacing.xs) {
            Rectangle()
                .fill(isCurrentLevel ? color : color.opacity(0.3))
                .frame(maxWidth: .infinity)
                .scaleEffect(y: isCurrentLevel ? 1.5 : 1.0)
                .animation(.spring(duration: 0.3), value: isCurrentLevel)
            
            Text(level.name)
                .font(.system(.caption2, design: .rounded, weight: isCurrentLevel ? .semibold : .regular))
                .foregroundColor(isCurrentLevel ? theme.colors.textPrimary : theme.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var standardsContextCard: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text(TrainingKeys.Tests.aboutStandards.localized)
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundColor(theme.colors.textPrimary)
            
            VStack(alignment: .leading, spacing: theme.spacing.s) {
                contextRow(icon: "person", text: "Base standartlar: 25 yaş, 80kg erkek")
                contextRow(icon: "slider.horizontal.3", text: "Sizin için demografik ayarlama uygulandı")
                contextRow(icon: "chart.bar", text: "Percentile: Seviye içindeki pozisyonunuz")
            }
        }
        .padding(theme.spacing.l)
        .background(
            RoundedRectangle(cornerRadius: theme.radius.l)
                .fill(theme.colors.cardBackground.opacity(0.5))
        )
    }
    
    private func contextRow(icon: String, text: String) -> some View {
        HStack(spacing: theme.spacing.m) {
            Image(systemName: icon)
                .font(.system(.caption, weight: .medium))
                .foregroundColor(theme.colors.accent)
                .frame(width: 16)
            
            Text(text)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(theme.colors.textSecondary)
        }
    }
    
    private func levelDescription(for level: StrengthLevel) -> String {
        switch level {
        case .beginner:
            return "Fitness journey'ine yeni başlayanlar"
        case .novice:
            return "Temel antrenman deneyimi olanlar"
        case .intermediate:
            return "Düzenli antrenman yapan sporcular"
        case .advanced:
            return "İleri seviye deneyimli sporcular"
        case .expert:
            return "Uzman seviyede performans"
        case .elite:
            return "Competitive/profesyonel seviye"
        }
    }
    
    private func colorForLevel(_ level: StrengthLevel) -> Color {
        switch level {
        case .beginner: return .red
        case .novice: return .orange
        case .intermediate: return .yellow
        case .advanced: return .green
        case .expert: return .blue
        case .elite: return .purple
        }
    }
}

// MARK: - Supporting Components

// MARK: - Modern Level Display

private extension TestResultSummary {
    var modernLevelDisplay: some View {
        VStack(spacing: theme.spacing.l) {
            // Main level indicator
            ZStack {
                // Background circle
                Circle()
                    .stroke(theme.colors.accent.opacity(0.1), lineWidth: 8)
                    .frame(width: 160, height: 160)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: animateResults ? strengthTest.overallScore : 0)
                    .stroke(
                        LinearGradient(
                            colors: [theme.colors.accent, theme.colors.accent.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.5).delay(0.8), value: animateResults)
                
                // Center content
                VStack(spacing: theme.spacing.xs) {
                    Text(String(format: "%.0f%%", strengthTest.overallScore * 100))
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Text("Genel Skor")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            
            // Clean level badge
            HStack(spacing: theme.spacing.m) {
                // Level indicator dot
                Circle()
                    .fill(levelBorderColor)
                    .frame(width: 12, height: 12)
                
                Text(safeAverageStrengthLevel.name)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
            }
            .padding(.horizontal, theme.spacing.l)
            .padding(.vertical, theme.spacing.m)
            .background(
                Capsule()
                    .fill(levelBackgroundColor)
                    .overlay(
                        Capsule()
                            .stroke(levelBorderColor, lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Safe Access Helpers
    
    /**
     * Safely gets average strength level with fallback.
     * Uses direct calculation to avoid infinite loops.
     */
    private var safeAverageStrengthLevel: StrengthLevel {
        guard !strengthTest.results.isEmpty else {
            return .beginner
        }
        
        // Direct calculation to avoid calling the computed property
        let validStrengthLevels = strengthTest.results.compactMap { result -> Int? in
            let level = result.strengthLevel
            if level >= 0 && level <= 5 {
                return level
            } else {
                return nil
            }
        }
        
        guard !validStrengthLevels.isEmpty else {
            return .beginner
        }
        
        let sum = validStrengthLevels.reduce(0, +)
        let averageFloat = Double(sum) / Double(validStrengthLevels.count)
        let averageLevel = Int(averageFloat.rounded())
        let clampedLevel = max(0, min(5, averageLevel))
        
        return StrengthLevel(rawValue: clampedLevel) ?? .beginner
    }
    
    private var levelBackgroundColor: Color {
        switch safeAverageStrengthLevel {
        case .beginner: return Color.red.opacity(0.1)
        case .novice: return Color.orange.opacity(0.1)
        case .intermediate: return Color.yellow.opacity(0.1)
        case .advanced: return Color.green.opacity(0.1)
        case .expert: return Color.blue.opacity(0.1)
        case .elite: return Color.purple.opacity(0.1)
        }
    }
    
    private var levelBorderColor: Color {
        switch safeAverageStrengthLevel {
        case .beginner: return Color.red.opacity(0.3)
        case .novice: return Color.orange.opacity(0.3)
        case .intermediate: return Color.yellow.opacity(0.3)
        case .advanced: return Color.green.opacity(0.3)
        case .expert: return Color.blue.opacity(0.3)
        case .elite: return Color.purple.opacity(0.3)
        }
    }
}

// MARK: - Metrics Cards Section

private extension TestResultSummary {
    var metricsCardsSection: some View {
        let profile = strengthTest.strengthProfile
        let profileText = profile == "balanced" ? "Dengeli" : 
                         profile == "upper_dominant" ? "Üst Vücut" : 
                         profile == "lower_dominant" ? "Alt Vücut" : "Bilinmiyor"
        let resultsCount = strengthTest.results.count
        
        return HStack(spacing: theme.spacing.m) {
            SummaryMetricCard(
                title: "Kuvvet Profili",
                value: profileText,
                color: profileCardColor
            )
            
            SummaryMetricCard(
                title: "Tamamlanan",
                value: "\(resultsCount)/5",
                color: .green
            )
        }
        .opacity(animateResults ? 1.0 : 0.0)
        .offset(y: animateResults ? 0 : 30)
        .animation(.easeOut(duration: 0.6).delay(1.0), value: animateResults)
    }
    
    
    private var profileCardColor: Color {
        guard !strengthTest.strengthProfile.isEmpty else { return .gray }
        
        switch strengthTest.strengthProfile {
        case "balanced": return .green
        case "upper_dominant": return .blue
        case "lower_dominant": return .orange
        default: return .gray
        }
    }
}

private struct SummaryMetricCard: View {
    let title: String
    let value: String
    let color: Color
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: theme.spacing.s) {
            // Clean color indicator
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundColor(theme.colors.textPrimary)
            
            Text(title)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, theme.spacing.l)
        .background(
            RoundedRectangle(cornerRadius: theme.radius.l)
                .fill(color.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radius.l)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

private struct MetricItem: View {
    let title: String
    let value: String
    let color: Color
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: theme.spacing.xs) {
            Text(value)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

private struct ModernExerciseResultCard: View {
    let result: StrengthTestResult
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: theme.spacing.l) {
            // Exercise info with clean indicator
            HStack(spacing: theme.spacing.m) {
                // Clean color indicator instead of emoji
                RoundedRectangle(cornerRadius: theme.radius.m)
                    .fill(safeExerciseColor.opacity(0.15))
                    .frame(width: 4, height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radius.m)
                            .fill(safeExerciseColor)
                            .frame(width: 4, height: 20)
                    )
                
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    HStack {
                        Text(safeExerciseName)
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .foregroundColor(theme.colors.textPrimary)
                        
                        // PR badge
                        if result.isPersonalRecord {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                Text("PR")
                                    .font(.system(.caption2, design: .rounded, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [.orange, .red],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                        }
                    }
                    
                    Text(result.displayValue)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundColor(safeExerciseColor)
                    
                    Text(safeStrengthLevelName)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(theme.colors.textSecondary)
                    
                    // Next level target
                    if let nextTarget = nextLevelTarget {
                        Text("Sonraki: \(nextTarget)")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundColor(theme.colors.accent)
                    }
                }
            }
            
            Spacer()
            
            // Modern level indicator
            VStack(spacing: theme.spacing.xs) {
                ZStack {
                    Circle()
                        .stroke(safeExerciseColor.opacity(0.2), lineWidth: 3)
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .trim(from: 0, to: result.percentileScore)
                        .stroke(safeExerciseColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-90))
                    
                    Text(String(format: "%.0f", result.percentileScore * 100))
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .foregroundColor(theme.colors.textPrimary)
                }
                
                Text("%")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
        .padding(theme.spacing.l)
        .background(
            RoundedRectangle(cornerRadius: theme.radius.l)
                .fill(theme.colors.cardBackground)
                .shadow(color: theme.shadows.card.opacity(0.08), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Safe Properties
    
    private var safeExerciseName: String {
        guard let exerciseType = StrengthExerciseType(rawValue: result.exerciseType) else {
            return "Egzersiz"
        }
        return exerciseType.name
    }
    
    
    private var safeExerciseColor: Color {
        guard let level = StrengthLevel(rawValue: result.strengthLevel) else {
            return .gray
        }
        
        switch level {
        case .beginner: return .red
        case .novice: return .orange
        case .intermediate: return .yellow
        case .advanced: return .green
        case .expert: return .blue
        case .elite: return .purple
        }
    }
    
    private var safeStrengthLevelName: String {
        guard let level = StrengthLevel(rawValue: result.strengthLevel) else {
            return "Bilinmiyor"
        }
        return level.name
    }
    
    private var nextLevelTarget: String? {
        guard let exerciseType = StrengthExerciseType(rawValue: result.exerciseType),
              let currentLevel = StrengthLevel(rawValue: result.strengthLevel) else {
            return nil
        }
        
        // Get next level
        let nextLevelRawValue = currentLevel.rawValue + 1
        guard nextLevelRawValue < StrengthLevel.allCases.count,
              let nextLevel = StrengthLevel(rawValue: nextLevelRawValue) else {
            return nil // Already at max level
        }
        
        // Get base standards for this exercise
        let baseStandards = exerciseType.baseStandards
        guard nextLevelRawValue < baseStandards.count else {
            return nil
        }
        
        let nextLevelValue = baseStandards[nextLevelRawValue]
        
        // Format based on exercise type
        if exerciseType == .pullUp {
            return "\(Int(nextLevelValue)) tekrar (\(nextLevel.name))"
        } else {
            return "\(Int(nextLevelValue))kg (\(nextLevel.name))"
        }
    }
}

private struct ModernProfileInsight: View {
    let title: String
    let description: String
    let color: Color
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            // Header with icon
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Circle()
                        .fill(color)
                        .frame(width: 12, height: 12)
                }
                
                Text(title)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                
                Spacer()
            }
            
            // Description
            Text(description)
                .font(.system(.body, design: .rounded))
                .foregroundColor(theme.colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
        }
        .padding(theme.spacing.l)
        .background(
            RoundedRectangle(cornerRadius: theme.radius.l)
                .fill(color.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radius.l)
                        .stroke(color.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

private struct ModernRecommendationItem: View {
    let text: String
    let index: Int
    @Environment(\.theme) private var theme
    
    private var accentColor: Color {
        switch index {
        case 0: return .blue
        case 1: return .green
        case 2: return .orange
        default: return .purple
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: theme.spacing.m) {
            // Clean indicator bar
            RoundedRectangle(cornerRadius: 2)
                .fill(accentColor)
                .frame(width: 3, height: 32)
            
            // Text content
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text("Öneri \(index + 1)")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundColor(accentColor)
                    .textCase(.uppercase)
                
                Text(text)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(theme.colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(1)
            }
            
            Spacer()
        }
        .cardStyle(.default, shadowColor: theme.shadows.card)
    }
}

// MARK: - Preview

#Preview("Test Result Summary") {
    let sampleTest = StrengthTest(
        userAge: 25,
        userGender: .male,
        userWeight: 80.0
    )
    
    // Add sample results
    sampleTest.isCompleted = true
    sampleTest.overallScore = 0.65
    sampleTest.strengthProfile = "balanced"
    
    let sampleResults = [
        StrengthTestResult(exerciseType: .benchPress, value: 80, strengthLevel: .intermediate, percentileScore: 0.6, isPersonalRecord: true),
        StrengthTestResult(exerciseType: .pullUp, value: 10, strengthLevel: .advanced, percentileScore: 0.8)
    ]
    
    sampleTest.results = sampleResults
    
    return TestResultSummary(
        strengthTest: sampleTest,
        onShareTapped: { },
        onSaveTapped: { }
    )
}
