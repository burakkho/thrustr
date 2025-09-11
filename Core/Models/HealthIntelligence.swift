import Foundation
import SwiftUI

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
struct HealthInsight: Identifiable {
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
        
        // HRV Score (0-100) - Based on scientific research
        let hrvScore: Double = {
            guard let hrv = hrv else { return 50 } // Default if unavailable
            
            // HRV norms based on age and gender (simplified)
            // Elite athletes: 50-100ms, Average: 20-50ms, Poor: <20ms
            let normalizedHRV: Double
            
            switch hrv {
            case 0..<15:
                normalizedHRV = (hrv / 15) * 20 // Very poor: 0-20 points
            case 15..<25:
                normalizedHRV = 20 + ((hrv - 15) / 10) * 30 // Poor: 20-50 points
            case 25..<35:
                normalizedHRV = 50 + ((hrv - 25) / 10) * 25 // Fair: 50-75 points
            case 35..<50:
                normalizedHRV = 75 + ((hrv - 35) / 15) * 20 // Good: 75-95 points
            default:
                normalizedHRV = 95 + min(5, (hrv - 50) / 10) // Excellent: 95-100 points
            }
            
            return min(100, max(0, normalizedHRV))
        }()
        
        // Sleep Score (0-100) - Based on sleep research
        let sleepScore: Double = {
            // Optimal sleep duration varies by age, using 7-9 hours for adults
            let optimalMin = 7.0
            let optimalMax = 9.0
            
            let sleepQuality: Double
            
            if sleepHours < 4.0 {
                sleepQuality = 0 // Severely sleep deprived
            } else if sleepHours < optimalMin {
                // Linear increase from 4 to 7 hours (20-85 points)
                sleepQuality = 20 + ((sleepHours - 4) / (optimalMin - 4)) * 65
            } else if sleepHours <= optimalMax {
                // Optimal range (85-100 points)
                sleepQuality = 85 + ((sleepHours - optimalMin) / (optimalMax - optimalMin)) * 15
            } else if sleepHours <= 11.0 {
                // Too much sleep penalty (100-70 points)
                sleepQuality = 100 - ((sleepHours - optimalMax) / 2) * 30
            } else {
                sleepQuality = 40 // Excessive sleep (potential health issues)
            }
            
            return min(100, max(0, sleepQuality))
        }()
        
        // Workout Load Score (0-100) - Based on Training Stress Score concepts
        let workoutLoadScore: Double = {
            // Convert workout intensity to recovery impact
            // Higher recent training = lower recovery score
            
            // Training Load Zones:
            // Zone 1 (Active Recovery): 0-2 intensity = 90-100 recovery
            // Zone 2 (Moderate): 2-4 intensity = 70-90 recovery  
            // Zone 3 (Hard): 4-6 intensity = 50-70 recovery
            // Zone 4 (Very Hard): 6-8 intensity = 30-50 recovery
            // Zone 5 (Extreme): 8-10+ intensity = 0-30 recovery
            
            let recoveryScore: Double
            
            switch workoutIntensityLast7Days {
            case 0..<2:
                recoveryScore = 90 + (2 - workoutIntensityLast7Days) / 2 * 10
            case 2..<4:
                recoveryScore = 70 + (4 - workoutIntensityLast7Days) / 2 * 20
            case 4..<6:
                recoveryScore = 50 + (6 - workoutIntensityLast7Days) / 2 * 20
            case 6..<8:
                recoveryScore = 30 + (8 - workoutIntensityLast7Days) / 2 * 20
            default:
                recoveryScore = max(0, 30 - (workoutIntensityLast7Days - 8) * 5)
            }
            
            return min(100, max(0, recoveryScore))
        }()
        
        // Resting Heart Rate Score (0-100) - Based on cardiovascular fitness
        let rhrScore: Double = {
            guard let rhr = restingHeartRate else { return 50 }
            
            // RHR norms by fitness level:
            // Elite athletes: 40-50 bpm (95-100 points)
            // Excellent: 50-60 bpm (85-95 points)  
            // Good: 60-70 bpm (70-85 points)
            // Average: 70-80 bpm (50-70 points)
            // Below Average: 80-90 bpm (25-50 points)
            // Poor: 90+ bpm (0-25 points)
            
            let rhrQuality: Double
            
            switch rhr {
            case 0..<40:
                rhrQuality = 100 // Exceptional (very rare)
            case 40..<50:
                rhrQuality = 95 + (50 - rhr) / 10 * 5 // Elite: 95-100
            case 50..<60:
                rhrQuality = 85 + (60 - rhr) / 10 * 10 // Excellent: 85-95
            case 60..<70:
                rhrQuality = 70 + (70 - rhr) / 10 * 15 // Good: 70-85
            case 70..<80:
                rhrQuality = 50 + (80 - rhr) / 10 * 20 // Average: 50-70
            case 80..<90:
                rhrQuality = 25 + (90 - rhr) / 10 * 25 // Below Average: 25-50
            default:
                rhrQuality = max(0, 25 - (rhr - 90) * 2.5) // Poor: 0-25
            }
            
            return min(100, max(0, rhrQuality))
        }()
        
        // Scientific weighted average based on recovery research
        // HRV is most predictive (40%), Sleep is critical (35%), Training Load (20%), RHR (5%)
        let overallScore = (hrvScore * 0.4) + (sleepScore * 0.35) + (workoutLoadScore * 0.2) + (rhrScore * 0.05)
        
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
        
        // MARK: - Advanced Recovery Pattern Analysis
        
        // Multi-factor recovery analysis
        if recoveryScore.overallScore < 40 {
            let dominantFactor = identifyRecoveryBottleneck(recoveryScore)
            
            insights.append(HealthInsight(
                type: .recovery,
                title: "Düşük toparlanma skoru tespit edildi",
                message: generateRecoveryInsightMessage(score: recoveryScore, bottleneck: dominantFactor),
                priority: .high,
                date: Date(),
                actionable: true,
                action: generateRecoveryAction(bottleneck: dominantFactor)
            ))
        } else if recoveryScore.overallScore > 85 {
            // Peak performance opportunity
            insights.append(HealthInsight(
                type: .recovery,
                title: "Mükemmel toparlanma durumu",
                message: "Toparlanma skorun çok yüksek. Bu dönemin değerini maksimize etmek için yoğun antrenman yapabilirsin.",
                priority: .medium,
                date: Date(),
                actionable: true,
                action: "Bugün zorlayıcı bir antrenman planla - vücudun hazır!"
            ))
        }
        
        // MARK: - Sleep Pattern Intelligence
        
        let sleepInsights = analyzeSleepPatterns(sleepScore: recoveryScore.sleepScore)
        insights.append(contentsOf: sleepInsights)
        
        // MARK: - Workout Intelligence & Pattern Recognition
        
        let workoutInsights = analyzeWorkoutPatterns(workoutTrends: workoutTrends, recoveryScore: recoveryScore)
        insights.append(contentsOf: workoutInsights)
        
        // MARK: - Activity & Movement Analysis
        
        let stepsInsights = analyzeStepsPatterns(stepsHistory: stepsHistory, workoutTrends: workoutTrends)
        insights.append(contentsOf: stepsInsights)
        
        // MARK: - Body Composition Trends
        
        let weightInsights = analyzeWeightTrends(weightHistory: weightHistory, workoutTrends: workoutTrends)
        insights.append(contentsOf: weightInsights)
        
        // MARK: - Cross-Metric Pattern Recognition
        
        let crossMetricInsights = analyzeCrossMetricPatterns(
            recoveryScore: recoveryScore,
            workoutTrends: workoutTrends,
            stepsHistory: stepsHistory,
            weightHistory: weightHistory
        )
        insights.append(contentsOf: crossMetricInsights)
        
        // Sort by priority and limit to most actionable insights
        return insights
            .sorted { insight1, insight2 in
                if insight1.priority != insight2.priority {
                    return insight1.priority.rawValue == "high"
                }
                return insight1.actionable && !insight2.actionable
            }
            .prefix(6) // Limit to 6 most important insights
            .map { $0 }
    }
    
    // MARK: - Recovery Analysis
    
    private static func identifyRecoveryBottleneck(_ recoveryScore: RecoveryScore) -> RecoveryBottleneck {
        let scores = [
            ("hrv", recoveryScore.hrvScore),
            ("sleep", recoveryScore.sleepScore),
            ("workload", recoveryScore.workoutLoadScore),
            ("rhr", recoveryScore.restingHeartRateScore)
        ]
        
        let lowest = scores.min { $0.1 < $1.1 }
        
        switch lowest?.0 {
        case "hrv": return .heartRateVariability
        case "sleep": return .sleep
        case "workload": return .trainingLoad
        case "rhr": return .restingHeartRate
        default: return .sleep
        }
    }
    
    private static func generateRecoveryInsightMessage(score: RecoveryScore, bottleneck: RecoveryBottleneck) -> String {
        let overallScore = Int(score.overallScore)
        
        switch bottleneck {
        case .heartRateVariability:
            return "Toparlanma skorun \(overallScore)/100. Kalp hızı değişkenliği düşük - stres seviyeni kontrol et."
        case .sleep:
            return "Toparlanma skorun \(overallScore)/100. Uyku kaliten düşük - uyku rutinini gözden geçir."
        case .trainingLoad:
            return "Toparlanma skorun \(overallScore)/100. Antrenman yükün yüksek - dinlenme günü ekle."
        case .restingHeartRate:
            return "Toparlanma skorun \(overallScore)/100. Dinlenme nabzın yüksek - kardiyovasküler stres var."
        }
    }
    
    private static func generateRecoveryAction(bottleneck: RecoveryBottleneck) -> String {
        switch bottleneck {
        case .heartRateVariability:
            return "Nefes egzersizleri yap, meditasyon dene ve stres kaynaklarını azalt"
        case .sleep:
            return "Erken yat, ekran süresini azalt ve yatak odası ortamını optimize et"
        case .trainingLoad:
            return "1-2 gün aktif dinlenme yap, hafif yürüyüş veya yoga tercih et"
        case .restingHeartRate:
            return "Hidrasyon durumunu kontrol et, kafein alımını azalt ve dinlenme prioriten yap"
        }
    }
    
    // MARK: - Sleep Pattern Analysis
    
    private static func analyzeSleepPatterns(sleepScore: Double) -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        if sleepScore < 50 {
            insights.append(HealthInsight(
                type: .sleep,
                title: "Kritik uyku eksikliği",
                message: "Uyku skorun \(Int(sleepScore))/100. Bu seviye performansını ve sağlığını ciddi şekilde etkiliyor.",
                priority: .high,
                date: Date(),
                actionable: true,
                action: "Bu gece mutlaka 8 saat uyumaya odaklan - telefonu kapalı tut"
            ))
        } else if sleepScore < 70 {
            insights.append(HealthInsight(
                type: .sleep,
                title: "Uyku kalitesi iyileştirilmeli",
                message: "Uyku skorun \(Int(sleepScore))/100. Daha iyi toparlanma için uyku rutinini optimize edebilirsin.",
                priority: .medium,
                date: Date(),
                actionable: true,
                action: "Uyku öncesi rutini oluştur: dim ışık, serin oda, düzenli yatış saati"
            ))
        } else if sleepScore > 90 {
            insights.append(HealthInsight(
                type: .sleep,
                title: "Mükemmel uyku kalitesi",
                message: "Uyku skorun \(Int(sleepScore))/100. Bu mükemmel toparlanma için ideal antrenman günü!",
                priority: .low,
                date: Date(),
                actionable: true,
                action: "Bu enerji ile zorlu antrenmana hazırsın - performans hedeflerini zorla"
            ))
        }
        
        return insights
    }
    
    // MARK: - Workout Pattern Analysis
    
    private static func analyzeWorkoutPatterns(workoutTrends: WorkoutTrends, recoveryScore: RecoveryScore) -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        let weeklyWorkouts = workoutTrends.workoutsPerWeek
        let _ = workoutTrends.averageDuration / 60.0 // minutes
        
        // Training frequency analysis
        if weeklyWorkouts < 2 {
            insights.append(HealthInsight(
                type: .workout,
                title: "Düşük antrenman sıklığı",
                message: "Haftada sadece \(String(format: "%.1f", weeklyWorkouts)) antrenman yapıyorsun. Sağlık için minimum 3 antrenman ideal.",
                priority: .medium,
                date: Date(),
                actionable: true,
                action: "Bu hafta 1 antrenman daha ekle - kısa bile olsa düzenlilik önemli"
            ))
        } else if weeklyWorkouts > 6 && recoveryScore.overallScore < 60 {
            insights.append(HealthInsight(
                type: .workout,
                title: "Aşırı antrenman riski",
                message: "Haftada \(String(format: "%.1f", weeklyWorkouts)) antrenman yapıyorsun ama toparlanma skorun \(Int(recoveryScore.overallScore)). Burnout riski var.",
                priority: .high,
                date: Date(),
                actionable: true,
                action: "2-3 gün dinlen, sonra antrenman sıklığını azalt"
            ))
        }
        
        // Training consistency analysis
        if workoutTrends.trendsDirection == TrendDirection.decreasing {
            insights.append(HealthInsight(
                type: .workout,
                title: "Antrenman motivasyonu düşüyor",
                message: "Son haftalarda antrenman sıklığın azalıyor. Momentum kaybetmeyelim!",
                priority: .medium,
                date: Date(),
                actionable: true,
                action: "Küçük başla - 20 dakikalık kolay bir antrenman planla"
            ))
        } else if workoutTrends.trendsDirection == TrendDirection.increasing && recoveryScore.overallScore > 70 {
            insights.append(HealthInsight(
                type: .workout,
                title: "Harika ilerleme trendi",
                message: "Antrenman sıklığın artıyor ve toparlanman iyi. Mükemmel kombinasyon!",
                priority: .low,
                date: Date(),
                actionable: true,
                action: "Bu momentumu korumak için hedeflerin yavaş yavaş zorlaştır"
            ))
        }
        
        return insights
    }
    
    // MARK: - Steps Pattern Analysis
    
    private static func analyzeStepsPatterns(stepsHistory: [HealthDataPoint], workoutTrends: WorkoutTrends) -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        let stepsTrend = HealthDataTrend(dataPoints: stepsHistory)
        let dailyAverage = Int(stepsTrend.average)
        
        if stepsTrend.average < 5000 {
            insights.append(HealthInsight(
                type: .steps,
                title: "Çok düşük günlük aktivite",
                message: "Günlük ortalama \(dailyAverage) adım. Bu sedanter yaşam sınıfında - sağlık riski yüksek.",
                priority: .high,
                date: Date(),
                actionable: true,
                action: "Günde 2000 adım hedefle başla - asansör yerine merdiven kullan"
            ))
        } else if stepsTrend.average < 8000 {
            insights.append(HealthInsight(
                type: .steps,
                title: "Günlük aktivite artırılabilir",
                message: "Günlük ortalama \(dailyAverage) adım. 10.000 adım hedefi için biraz daha aktif ol.",
                priority: .medium,
                date: Date(),
                actionable: true,
                action: "Günde 500-1000 adım arttır - öğle arası yürüyüş ekle"
            ))
        }
        
        // Cross-analysis with workouts
        if workoutTrends.workoutsPerWeek > 4 && stepsTrend.average < 6000 {
            insights.append(HealthInsight(
                type: .steps,
                title: "Antrenman dışında hareketsizlik",
                message: "Düzenli antrenman yapıyorsun ama günlük adımların az. NEAT (antrenman dışı aktivite) arttır.",
                priority: .medium,
                date: Date(),
                actionable: true,
                action: "Antrenman günlerinde de aktif kal - yürüyerek git/gel"
            ))
        }
        
        return insights
    }
    
    // MARK: - Weight Trend Analysis
    
    private static func analyzeWeightTrends(weightHistory: [HealthDataPoint], workoutTrends: WorkoutTrends) -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        guard !weightHistory.isEmpty else { return insights }
        
        let weightTrend = HealthDataTrend(dataPoints: weightHistory)
        
        if abs(weightTrend.percentChange) > 10 {
            let direction = weightTrend.percentChange > 0 ? "artış" : "azalış"
            let priority: HealthInsight.InsightPriority = abs(weightTrend.percentChange) > 15 ? .high : .medium
            
            insights.append(HealthInsight(
                type: .weight,
                title: "Hızlı kilo değişimi",
                message: "Son dönemde %\(String(format: "%.1f", abs(weightTrend.percentChange))) kilo \(direction). Bu hızlı değişim dikkat gerektirir.",
                priority: priority,
                date: Date(),
                actionable: true,
                action: "Beslenme ve antrenman rutinini gözden geçir, gerekirse uzman desteği al"
            ))
        }
        
        // Volatility analysis
        if weightTrend.isVolatile && workoutTrends.workoutsPerWeek > 3 {
            insights.append(HealthInsight(
                type: .weight,
                title: "Kilo dalgalanmaları yüksek",
                message: "Düzenli antrenman yapıyorsun ama kilo çok dalgalanıyor. Su tutma veya beslenme düzensizliği olabilir.",
                priority: .medium,
                date: Date(),
                actionable: true,
                action: "Su tüketimini sabit tut, karbonhidrat alımını dengele"
            ))
        }
        
        return insights
    }
    
    // MARK: - Cross-Metric Pattern Recognition
    
    private static func analyzeCrossMetricPatterns(
        recoveryScore: RecoveryScore,
        workoutTrends: WorkoutTrends,
        stepsHistory: [HealthDataPoint],
        weightHistory: [HealthDataPoint]
    ) -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        // Recovery vs. Workout Volume
        if workoutTrends.workoutsPerWeek > 5 && recoveryScore.overallScore < 50 {
            insights.append(HealthInsight(
                type: .recovery,
                title: "Toparlanma-antrenman dengesizliği",
                message: "Yoğun antrenman (\(String(format: "%.1f", workoutTrends.workoutsPerWeek))/hafta) ama düşük toparlanma (\(Int(recoveryScore.overallScore))/100). Burnout sinyali.",
                priority: .high,
                date: Date(),
                actionable: true,
                action: "Hemen deload week yap - antrenman yoğunluğunu %40 azalt"
            ))
        }
        
        // Sleep vs. Performance
        if recoveryScore.sleepScore > 85 && workoutTrends.trendsDirection == TrendDirection.increasing {
            insights.append(HealthInsight(
                type: .workout,
                title: "Uyku-performans sinerji",
                message: "Mükemmel uyku (\(Int(recoveryScore.sleepScore))/100) ve artan antrenman performansı. İdeal dönemdesin!",
                priority: .low,
                date: Date(),
                actionable: true,
                action: "Bu sinerjiyi koru - uyku rutinini değiştirme, performans hedeflerini zorla"
            ))
        }
        
        // Activity patterns
        let stepsTrend = HealthDataTrend(dataPoints: stepsHistory)
        if stepsTrend.average > 12000 && workoutTrends.workoutsPerWeek < 2 {
            insights.append(HealthInsight(
                type: .workout,
                title: "Aktif yaşam, eksik yapılandırılmış antrenman",
                message: "Günlük \(Int(stepsTrend.average)) adım - süper aktifsin! Ama yapılandırılmış antrenman ekleyerek daha da gelişebilirsin.",
                priority: .medium,
                date: Date(),
                actionable: true,
                action: "Haftada 2-3 güç antrenmanı ekle - mevcut aktivite seviyeni koru"
            ))
        }
        
        return insights
    }
    
    private enum RecoveryBottleneck {
        case heartRateVariability, sleep, trainingLoad, restingHeartRate
    }
    
    static func assessFitnessLevel(
        workoutTrends: WorkoutTrends,
        vo2Max: Double?,
        consistencyScore: Double
    ) -> FitnessLevelAssessment {
        
        // Cardio fitness assessment based on VO2 Max scientific standards
        let cardioLevel: FitnessLevelAssessment.FitnessLevel = {
            guard let vo2 = vo2Max, vo2 > 0 else { 
                // If no VO2 Max, estimate from workout patterns
                return estimateCardioFromWorkouts(workoutTrends)
            }
            
            // VO2 Max categories for adults (ml/kg/min)
            // Based on ACSM (American College of Sports Medicine) guidelines
            switch vo2 {
            case 0..<25: return .beginner      // Poor cardiovascular fitness
            case 25..<35: return .beginner     // Fair cardiovascular fitness  
            case 35..<45: return .intermediate // Good cardiovascular fitness
            case 45..<55: return .advanced     // Excellent cardiovascular fitness
            default: return .elite             // Superior/Athletic level (55+)
            }
        }()
        
        // Strength assessment based on scientific training principles
        let strengthLevel: FitnessLevelAssessment.FitnessLevel = {
            let avgDuration = workoutTrends.averageDuration / 60 // minutes
            let weeklyWorkouts = workoutTrends.workoutsPerWeek
            let totalWorkouts = workoutTrends.totalWorkouts
            
            // Multi-factor strength assessment
            var strengthPoints = 0
            
            // Workout frequency scoring (ACSM recommendations: 2-3x/week strength)
            switch weeklyWorkouts {
            case 0..<1: strengthPoints += 0   // Sedentary
            case 1..<2: strengthPoints += 1   // Minimal
            case 2..<3: strengthPoints += 2   // Beginner
            case 3..<4: strengthPoints += 3   // Intermediate  
            case 4..<5: strengthPoints += 4   // Advanced
            default: strengthPoints += 5      // Elite frequency
            }
            
            // Workout duration quality
            switch avgDuration {
            case 0..<15: strengthPoints += 0  // Too short
            case 15..<30: strengthPoints += 1 // Light session
            case 30..<45: strengthPoints += 2 // Good duration
            case 45..<75: strengthPoints += 3 // Optimal
            default: strengthPoints += 2      // May be too long
            }
            
            // Experience factor (total workouts)
            switch totalWorkouts {
            case 0..<10: strengthPoints += 0   // Novice
            case 10..<25: strengthPoints += 1  // Beginner
            case 25..<50: strengthPoints += 2  // Developing
            case 50..<100: strengthPoints += 3 // Experienced
            default: strengthPoints += 4       // Very experienced
            }
            
            // Consistency factor
            let consistencyMultiplier = consistencyScore / 100.0
            let adjustedPoints = Double(strengthPoints) * (0.5 + consistencyMultiplier * 0.5)
            
            // Convert points to level
            switch adjustedPoints {
            case 0..<3: return .beginner      // 0-2 points
            case 3..<6: return .intermediate  // 3-5 points  
            case 6..<9: return .advanced      // 6-8 points
            default: return .elite            // 9+ points
            }
        }()
        
        // Overall level calculation with scientific weighting
        let overallLevel: FitnessLevelAssessment.FitnessLevel = {
            // Weight cardio and strength equally, but consider consistency
            let cardioScore = levelToNumericScore(cardioLevel)
            let strengthScore = levelToNumericScore(strengthLevel)
            
            // Weighted average with consistency boost
            let baseScore = (cardioScore + strengthScore) / 2.0
            let consistencyBoost = (consistencyScore - 50) / 100.0 // -0.5 to +0.5 modifier
            let finalScore = baseScore + consistencyBoost
            
            return numericScoreToLevel(finalScore)
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
    
    // Helper function to estimate cardio fitness from workout patterns
    private static func estimateCardioFromWorkouts(_ trends: WorkoutTrends) -> FitnessLevelAssessment.FitnessLevel {
        let weeklyWorkouts = trends.workoutsPerWeek
        let avgDuration = trends.averageDuration / 60 // minutes
        
        // Estimate based on cardiovascular workout patterns
        if weeklyWorkouts >= 5 && avgDuration >= 45 {
            return .advanced
        } else if weeklyWorkouts >= 3 && avgDuration >= 30 {
            return .intermediate
        } else if weeklyWorkouts >= 1 && avgDuration >= 20 {
            return .beginner
        } else {
            return .beginner
        }
    }
    
    // Helper function to convert fitness level to numeric score
    private static func levelToNumericScore(_ level: FitnessLevelAssessment.FitnessLevel) -> Double {
        switch level {
        case .beginner: return 1.0
        case .intermediate: return 2.0
        case .advanced: return 3.0
        case .elite: return 4.0
        }
    }
    
    // Helper function to convert numeric score back to fitness level
    private static func numericScoreToLevel(_ score: Double) -> FitnessLevelAssessment.FitnessLevel {
        switch score {
        case ..<1.5: return .beginner
        case 1.5..<2.5: return .intermediate
        case 2.5..<3.5: return .advanced
        default: return .elite
        }
    }
}

struct HealthIntelligence {
    @MainActor
    static func generateComprehensiveHealthReport(
        healthKitService: HealthKitService,
        workoutTrends: WorkoutTrends
    ) -> HealthReport {
        
        // Calculate real workout intensity from recent workouts
        let workoutIntensity = calculateWorkoutIntensityLast7Days(workoutTrends: workoutTrends)
        
        let recoveryScore = calculateRecoveryScore(
            hrv: healthKitService.heartRateVariability,
            sleepHours: healthKitService.lastNightSleep,
            workoutIntensityLast7Days: workoutIntensity,
            restingHeartRate: healthKitService.restingHeartRate
        )
        
        let insights = generateHealthInsights(
            recoveryScore: recoveryScore,
            workoutTrends: workoutTrends,
            stepsHistory: healthKitService.stepsHistory,
            weightHistory: healthKitService.weightHistory
        )
        
        // Calculate real consistency score from workout data
        let consistencyScore = calculateConsistencyScore(workoutTrends: workoutTrends)
        
        let fitnessAssessment = assessFitnessLevel(
            workoutTrends: workoutTrends,
            vo2Max: healthKitService.vo2Max,
            consistencyScore: consistencyScore
        )
        
        return HealthReport(
            recoveryScore: recoveryScore,
            insights: insights,
            fitnessAssessment: fitnessAssessment,
            generatedDate: Date()
        )
    }
    
    // Calculate workout intensity based on recent training load
    private static func calculateWorkoutIntensityLast7Days(workoutTrends: WorkoutTrends) -> Double {
        // Get the last week's workout data
        let lastWeekWorkouts = workoutTrends.weeklyWorkouts.suffix(1).first
        
        guard let lastWeek = lastWeekWorkouts else { return 0.0 }
        
        // Calculate intensity based on frequency, duration, and calorie burn
        let frequencyScore = min(10.0, Double(lastWeek.workoutCount) * 1.5) // Max 10 for 7+ workouts
        
        let avgDurationMinutes = lastWeek.totalDuration / 60.0 / max(1, Double(lastWeek.workoutCount))
        let durationScore = min(5.0, avgDurationMinutes / 12.0) // Max 5 for 60+ minute workouts
        
        let caloriesPerWorkout = lastWeek.totalCalories / max(1, Double(lastWeek.workoutCount))
        let intensityScore = min(5.0, caloriesPerWorkout / 100.0) // Max 5 for 500+ calorie workouts
        
        let totalIntensity = (frequencyScore + durationScore + intensityScore) / 2.0 // Scale to 0-10
        
        return min(10.0, max(0.0, totalIntensity))
    }
    
    // Calculate consistency score based on workout patterns
    private static func calculateConsistencyScore(workoutTrends: WorkoutTrends) -> Double {
        let weeklyData = workoutTrends.weeklyWorkouts
        
        guard weeklyData.count >= 2 else { return 0.0 }
        
        // Calculate consistency based on workout frequency variance
        let workoutCounts = weeklyData.map { Double($0.workoutCount) }
        let average = workoutCounts.reduce(0, +) / Double(workoutCounts.count)
        
        // Calculate coefficient of variation (lower = more consistent)
        if average == 0 { return 0.0 }
        
        let variance = workoutCounts.map { pow($0 - average, 2) }.reduce(0, +) / Double(workoutCounts.count)
        let standardDeviation = sqrt(variance)
        let coefficientOfVariation = standardDeviation / average
        
        // Convert to consistency score (0-100)
        // Lower CV = higher consistency
        let consistencyScore = max(0, 100 - (coefficientOfVariation * 100))
        
        // Bonus for having workouts at all
        let activityBonus = min(20, average * 5) // Up to 20 points for having regular activity
        
        return min(100, consistencyScore + activityBonus)
    }
}

struct HealthReport {
    let recoveryScore: RecoveryScore
    let insights: [HealthInsight]
    let fitnessAssessment: FitnessLevelAssessment
    let generatedDate: Date
}