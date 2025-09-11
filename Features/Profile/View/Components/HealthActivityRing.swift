import SwiftUI

// MARK: - Health Activity Ring Component
// Apple Watch-inspired activity ring for profile photo
struct HealthActivityRing: View {
    let progress: Double // 0.0 - 1.0
    let color: Color
    let strokeWidth: CGFloat
    let ringRadius: CGFloat
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    color.opacity(0.2),
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .frame(width: ringRadius * 2, height: ringRadius * 2)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .frame(width: ringRadius * 2, height: ringRadius * 2)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: progress)
        }
    }
}

// MARK: - Health Activity Profile Photo
// Profile photo with activity rings (Apple Watch style)
struct HealthActivityProfilePhoto: View {
    let user: User?
    @State private var healthKitService = HealthKitService.shared
    
    // Ring configuration - Apple Watch sizing ratios
    private let baseRingRadius: CGFloat = 42 // Base photo radius + ring spacing
    private let ringSpacing: CGFloat = 4
    private let strokeWidth: CGFloat = 3
    
    private var strengthProgress: Double {
        guard let user = user else { return 0 }
        let (_, strengthLevel) = getOverallStrengthLevel(user: user)
        guard let level = strengthLevel else { return 0 }
        return Double(level.rawValue) / 5.0 // 5 levels max
    }
    
    private var stepsProgress: Double {
        let stepsGoal: Double = 10000 // Standard daily steps goal
        return min(healthKitService.todaySteps / stepsGoal, 1.0)
    }
    
    private var caloriesProgress: Double {
        let caloriesGoal: Double = 400 // Standard active calories goal
        return min(healthKitService.todayActiveCalories / caloriesGoal, 1.0)
    }
    
    var body: some View {
        ZStack {
            // Outermost ring - Strength Level (Green)
            if strengthProgress > 0 {
                HealthActivityRing(
                    progress: strengthProgress,
                    color: .green,
                    strokeWidth: strokeWidth,
                    ringRadius: baseRingRadius + (ringSpacing * 2)
                )
            }
            
            // Middle ring - Steps (Blue)
            if healthKitService.isAuthorized && stepsProgress > 0 {
                HealthActivityRing(
                    progress: stepsProgress,
                    color: .blue,
                    strokeWidth: strokeWidth,
                    ringRadius: baseRingRadius + ringSpacing
                )
            }
            
            // Inner ring - Active Calories (Red)
            if healthKitService.isAuthorized && caloriesProgress > 0 {
                HealthActivityRing(
                    progress: caloriesProgress,
                    color: .red,
                    strokeWidth: strokeWidth,
                    ringRadius: baseRingRadius
                )
            }
            
            // Profile photo (center)
            ProfilePhotoCore(user: user)
        }
        .onAppear {
            if healthKitService.isAuthorized {
                Task {
                    await healthKitService.readTodaysData()
                }
            }
        }
    }
    
    private func getOverallStrengthLevel(user: User) -> (level: String, strengthLevel: StrengthLevel?) {
        guard user.hasCompleteOneRMData else { return ("--", nil) }
        guard user.age > 0, user.currentWeight > 0 else { return ("--", nil) }
        
        let exercises: [StrengthExerciseType] = [.benchPress, .backSquat, .deadlift, .overheadPress, .pullUp]
        var strengthLevels: [StrengthLevel] = []
        
        for exercise in exercises {
            guard let oneRM = user.getCurrentOneRM(for: exercise), oneRM > 0 else { continue }
            
            let (level, _) = StrengthStandardsConfig.strengthLevel(
                for: oneRM,
                exerciseType: exercise,
                userGender: user.genderEnum,
                userAge: user.age,
                userWeight: user.currentWeight
            )
            
            strengthLevels.append(level)
        }
        
        guard !strengthLevels.isEmpty else { return ("--", nil) }
        
        let averageRawValue = strengthLevels.map { $0.rawValue }.reduce(0, +) / strengthLevels.count
        let clampedValue = max(0, min(5, averageRawValue))
        let overallLevel = StrengthLevel(rawValue: clampedValue) ?? .beginner
        
        return ("", overallLevel)
    }
}

// MARK: - Profile Photo Core
// The actual profile photo without rings
struct ProfilePhotoCore: View {
    let user: User?
    
    var body: some View {
        Circle()
            .fill(LinearGradient(
                gradient: Gradient(colors: [.blue, .purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .frame(width: 70, height: 70)
            .overlay(
                ZStack {
                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 35, height: 35)
                        .opacity(0.3)
                    
                    Text(user?.name.prefix(1).uppercased() ?? "U")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            )
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    VStack(spacing: 40) {
        // With activity rings
        HealthActivityProfilePhoto(user: nil)
        
        // Ring components individually
        HStack(spacing: 20) {
            HealthActivityRing(progress: 0.7, color: .red, strokeWidth: 3, ringRadius: 30)
            HealthActivityRing(progress: 0.4, color: .blue, strokeWidth: 3, ringRadius: 30)
            HealthActivityRing(progress: 0.9, color: .green, strokeWidth: 3, ringRadius: 30)
        }
    }
    .padding()
}