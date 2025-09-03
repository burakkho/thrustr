import Foundation

// MARK: - Recovery Score Model
struct RecoveryScore {
    let overallScore: Double // 0-100
    let hrvScore: Double
    let sleepScore: Double
    let workoutLoadScore: Double
    let restingHeartRateScore: Double
    let date: Date
    
    var category: RecoveryCategory {
        switch overallScore {
        case 80...100: return .excellent
        case 60..<80: return .good
        case 40..<60: return .moderate
        case 20..<40: return .poor
        default: return .critical
        }
    }
    
    var recommendation: String {
        switch category {
        case .excellent:
            return CommonKeys.HealthKit.recoveryExcellentMessage.localized
        case .good:
            return CommonKeys.HealthKit.recoveryGoodMessage.localized
        case .moderate:
            return CommonKeys.HealthKit.recoveryModerateMessage.localized
        case .poor:
            return CommonKeys.HealthKit.recoveryPoorMessage.localized
        case .critical:
            return CommonKeys.HealthKit.recoveryCriticalMessage.localized
        }
    }
}

enum RecoveryCategory: String, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case moderate = "moderate"
    case poor = "poor"
    case critical = "critical"
    
    var localizedName: String {
        switch self {
        case .excellent: return "health.recovery.excellent".localized
        case .good: return "health.recovery.good".localized
        case .moderate: return "health.recovery.moderate".localized
        case .poor: return "health.recovery.poor".localized
        case .critical: return "health.recovery.critical".localized
        }
    }
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .moderate: return "yellow"
        case .poor: return "orange"
        case .critical: return "red"
        }
    }
    
    var icon: String {
        switch self {
        case .excellent: return "heart.fill"
        case .good: return "heart"
        case .moderate: return "heart.slash"
        case .poor: return "exclamationmark.triangle"
        case .critical: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Health Insights
struct HealthInsight {
    let id = UUID()
    let type: InsightType
    let title: String
    let message: String
    let priority: InsightPriority
    let date: Date
    let actionable: Bool
    let action: String?
    
    enum InsightType: String, CaseIterable {
        case workout = "workout"
        case sleep = "sleep"
        case nutrition = "nutrition"
        case recovery = "recovery"
        case heartHealth = "heart_health"
        case weight = "weight"
        case steps = "steps"
        
        var localizedName: String {
            switch self {
            case .workout: return "health.insight.workout".localized
            case .sleep: return "health.insight.sleep".localized
            case .nutrition: return "health.insight.nutrition".localized
            case .recovery: return "health.insight.recovery".localized
            case .heartHealth: return "health.insight.heart_health".localized
            case .weight: return "health.insight.weight".localized
            case .steps: return "health.insight.steps".localized
            }
        }
    }
    
    enum InsightPriority: String, CaseIterable {
        case high = "high"
        case medium = "medium"
        case low = "low"
        
        var localizedName: String {
            switch self {
            case .high: return "health.priority.high".localized
            case .medium: return "health.priority.medium".localized
            case .low: return "health.priority.low".localized
            }
        }
        
        var color: String {
            switch self {
            case .high: return "red"
            case .medium: return "orange"
            case .low: return "blue"
            }
        }
    }
}

// MARK: - Fitness Level Assessment
struct FitnessLevelAssessment {
    let overallLevel: FitnessLevel
    let cardioLevel: FitnessLevel
    let strengthLevel: FitnessLevel
    let consistencyScore: Double // 0-100
    let progressTrend: TrendDirection
    let assessmentDate: Date
    
    enum FitnessLevel: String, CaseIterable {
        case beginner = "beginner"
        case intermediate = "intermediate"
        case advanced = "advanced"
        case elite = "elite"
        
        var localizedName: String {
            switch self {
            case .beginner: return "health.fitness.beginner".localized
            case .intermediate: return "health.fitness.intermediate".localized
            case .advanced: return "health.fitness.advanced".localized
            case .elite: return "health.fitness.elite".localized
            }
        }
        
        var description: String {
            switch self {
            case .beginner:
                return CommonKeys.HealthKit.fitnessBeginnerDesc.localized
            case .intermediate:
                return CommonKeys.HealthKit.fitnessIntermediateDesc.localized
            case .advanced:
                return CommonKeys.HealthKit.fitnessAdvancedDesc.localized
            case .elite:
                return CommonKeys.HealthKit.fitnessEliteDesc.localized
            }
        }
        
        var color: String {
            switch self {
            case .beginner: return "gray"
            case .intermediate: return "blue"
            case .advanced: return "green"
            case .elite: return "purple"
            }
        }
    }
}

// MARK: - Health Intelligence Service Extension
extension HealthIntelligence {
    static func calculateRecoveryScore(
        hrv: Double?,
        sleepHours: Double,
        workoutIntensityLast7Days: Double,
        restingHeartRate: Double?
    ) -> RecoveryScore {
        
        // HRV Score (0-100)
        let hrvScore: Double = {
            guard let hrv = hrv else { return 50 } // Default if unavailable
            // Normalize HRV to 0-100 scale (assuming healthy range 20-100ms)
            return min(100, max(0, (hrv - 20) / 80 * 100))
        }()
        
        // Sleep Score (0-100)
        let sleepScore: Double = {
            let idealSleep = 8.0
            let sleepEfficiency = min(100, (sleepHours / idealSleep) * 100)
            // Penalize both too little and too much sleep
            if sleepHours < 6 {
                return sleepEfficiency * 0.7
            } else if sleepHours > 10 {
                return sleepEfficiency * 0.8
            }
            return sleepEfficiency
        }()
        
        // Workout Load Score (0-100) - Lower recent intensity = better recovery
        let workoutLoadScore: Double = {
            let maxIntensity = 10.0 // Max workout intensity scale
            let normalized = min(100, max(0, workoutIntensityLast7Days / maxIntensity * 100))
            return 100 - normalized // Invert: less intensity = higher score
        }()
        
        // Resting Heart Rate Score (0-100)
        let rhrScore: Double = {
            guard let rhr = restingHeartRate else { return 50 }
            // Typical healthy range: 40-100 bpm, optimal around 60
            let optimal = 60.0
            let deviation = abs(rhr - optimal)
            return max(0, 100 - (deviation * 2))
        }()
        
        // Weighted overall score
        let overallScore = (hrvScore * 0.3) + (sleepScore * 0.35) + (workoutLoadScore * 0.25) + (rhrScore * 0.1)
        
        return RecoveryScore(
            overallScore: overallScore,
            hrvScore: hrvScore,
            sleepScore: sleepScore,
            workoutLoadScore: workoutLoadScore,
            restingHeartRateScore: rhrScore,
            date: Date()
        )
    }
    
    static func generateHealthInsights(
        recoveryScore: RecoveryScore,
        workoutTrends: WorkoutTrends,
        stepsHistory: [HealthDataPoint],
        weightHistory: [HealthDataPoint]
    ) -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        // Recovery insights
        if recoveryScore.overallScore < 40 {
            insights.append(HealthInsight(
                type: .recovery,
                title: CommonKeys.HealthKit.insightLowRecoveryTitle.localized,
                message: CommonKeys.HealthKit.insightLowRecoveryMessage.localized,
                priority: .high,
                date: Date(),
                actionable: true,
                action: CommonKeys.HealthKit.insightLowRecoveryAction.localized
            ))
        }
        
        // Sleep insights
        if recoveryScore.sleepScore < 70 {
            insights.append(HealthInsight(
                type: .sleep,
                title: CommonKeys.HealthKit.insightSleepQualityTitle.localized,
                message: CommonKeys.HealthKit.insightSleepQualityMessage.localized,
                priority: .medium,
                date: Date(),
                actionable: true,
                action: CommonKeys.HealthKit.insightSleepQualityAction.localized
            ))
        }
        
        // Workout consistency insights
        if workoutTrends.trendsDirection == .decreasing {
            insights.append(HealthInsight(
                type: .workout,
                title: CommonKeys.HealthKit.insightWorkoutFrequencyTitle.localized,
                message: CommonKeys.HealthKit.insightWorkoutFrequencyMessage.localized,
                priority: .medium,
                date: Date(),
                actionable: true,
                action: CommonKeys.HealthKit.insightWorkoutFrequencyAction.localized
            ))
        } else if workoutTrends.workoutsPerWeek > 6 {
            insights.append(HealthInsight(
                type: .workout,
                title: CommonKeys.HealthKit.insightIntenseTrainingTitle.localized,
                message: String(format: "%@ %.1f %@. %@", CommonKeys.HealthKit.weeklyWorkouts.localized, workoutTrends.workoutsPerWeek, CommonKeys.HealthKit.workoutsDoing.localized, CommonKeys.HealthKit.insightIntenseTrainingMessage.localized),
                priority: .medium,
                date: Date(),
                actionable: true,
                action: CommonKeys.HealthKit.insightIntenseTrainingAction.localized
            ))
        }
        
        // Steps insights
        let stepsTrend = HealthDataTrend(dataPoints: stepsHistory)
        if stepsTrend.average < 8000 {
            insights.append(HealthInsight(
                type: .steps,
                title: CommonKeys.HealthKit.insightLowActivityTitle.localized,
                message: String(format: "%@ %d. %@", CommonKeys.HealthKit.dailyAverageSteps.localized, Int(stepsTrend.average), CommonKeys.HealthKit.insightLowActivityMessage.localized),
                priority: .low,
                date: Date(),
                actionable: true,
                action: CommonKeys.HealthKit.insightLowActivityAction.localized
            ))
        }
        
        // Weight insights
        let weightTrend = HealthDataTrend(dataPoints: weightHistory)
        if abs(weightTrend.percentChange) > 5 {
            let direction = weightTrend.percentChange > 0 ? CommonKeys.HealthKit.weightIncrease.localized : CommonKeys.HealthKit.weightDecrease.localized
            insights.append(HealthInsight(
                type: .weight,
                title: CommonKeys.HealthKit.insightWeightChangeTitle.localized,
                message: String(format: "%@ %%%@ %@ %@.", CommonKeys.HealthKit.weightChangePeriod.localized, String(format: "%.1f", abs(weightTrend.percentChange)), direction, CommonKeys.HealthKit.weightChangeExists.localized),
                priority: .medium,
                date: Date(),
                actionable: true,
                action: CommonKeys.HealthKit.insightWeightChangeAction.localized
            ))
        }
        
        return insights.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    static func assessFitnessLevel(
        workoutTrends: WorkoutTrends,
        vo2Max: Double?,
        consistencyScore: Double
    ) -> FitnessLevelAssessment {
        
        // Cardio fitness assessment based on VO2 Max
        let cardioLevel: FitnessLevelAssessment.FitnessLevel = {
            guard let vo2 = vo2Max else { return .beginner }
            switch vo2 {
            case 55...100: return .elite
            case 45..<55: return .advanced
            case 35..<45: return .intermediate
            default: return .beginner
            }
        }()
        
        // Strength assessment based on workout frequency and duration
        let strengthLevel: FitnessLevelAssessment.FitnessLevel = {
            let avgDuration = workoutTrends.averageDuration / 60 // minutes
            let weeklyWorkouts = workoutTrends.workoutsPerWeek
            
            if weeklyWorkouts >= 5 && avgDuration >= 60 {
                return .elite
            } else if weeklyWorkouts >= 3 && avgDuration >= 45 {
                return .advanced
            } else if weeklyWorkouts >= 2 && avgDuration >= 30 {
                return .intermediate
            } else {
                return .beginner
            }
        }()
        
        // Overall level (weighted average)
        let cardioWeight = 0.4
        let strengthWeight = 0.6
        
        let cardioScore = Double(cardioLevel.rawValue.count) * cardioWeight
        let strengthScore = Double(strengthLevel.rawValue.count) * strengthWeight
        let totalScore = cardioScore + strengthScore
        
        let overallLevel: FitnessLevelAssessment.FitnessLevel = {
            if totalScore >= 15 { return .elite }
            else if totalScore >= 12 { return .advanced }
            else if totalScore >= 8 { return .intermediate }
            else { return .beginner }
        }()
        
        return FitnessLevelAssessment(
            overallLevel: overallLevel,
            cardioLevel: cardioLevel,
            strengthLevel: strengthLevel,
            consistencyScore: consistencyScore,
            progressTrend: workoutTrends.trendsDirection,
            assessmentDate: Date()
        )
    }
}

struct HealthIntelligence {
    @MainActor
    static func generateComprehensiveHealthReport(
        healthKitService: HealthKitService,
        workoutTrends: WorkoutTrends
    ) -> HealthReport {
        
        let recoveryScore = calculateRecoveryScore(
            hrv: healthKitService.heartRateVariability,
            sleepHours: healthKitService.lastNightSleep,
            workoutIntensityLast7Days: 5.0, // Simplified for now
            restingHeartRate: healthKitService.restingHeartRate
        )
        
        let insights = generateHealthInsights(
            recoveryScore: recoveryScore,
            workoutTrends: workoutTrends,
            stepsHistory: healthKitService.stepsHistory,
            weightHistory: healthKitService.weightHistory
        )
        
        let fitnessAssessment = assessFitnessLevel(
            workoutTrends: workoutTrends,
            vo2Max: healthKitService.vo2Max,
            consistencyScore: 75.0 // Calculate based on actual consistency
        )
        
        return HealthReport(
            recoveryScore: recoveryScore,
            insights: insights,
            fitnessAssessment: fitnessAssessment,
            generatedDate: Date()
        )
    }
}

struct HealthReport {
    let recoveryScore: RecoveryScore
    let insights: [HealthInsight]
    let fitnessAssessment: FitnessLevelAssessment
    let generatedDate: Date
}