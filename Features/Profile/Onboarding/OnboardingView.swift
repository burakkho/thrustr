//
//  OnboardingView.swift
//  SporHocam
//
//  Main Onboarding Coordinator - Localized
//

import SwiftUI
import SwiftData

// MARK: - Main Onboarding Coordinator
struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false
    @State private var currentStep = 0
    @State private var onboardingData = OnboardingData()
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                if currentStep > 0 {
                    OnboardingProgressView(currentStep: currentStep, totalSteps: 5)
                        .padding(.top)
                }
                
                switch currentStep {
                case 0: WelcomeStepView(onNext: { currentStep = 1 })
                case 1: PersonalInfoStepView(data: $onboardingData, onNext: { currentStep = 2 })
                case 2: GoalsStepView(data: $onboardingData, onNext: { currentStep = 3 })
                case 3: MeasurementsStepView(data: $onboardingData, onNext: { currentStep = 4 })
                case 4: SummaryStepView(data: onboardingData, onComplete: completeOnboarding)
                default: EmptyView()
                }
                
                Spacer()
                
                // Back button - Düzeltildi
                if currentStep > 0 {
                    Button("onboarding.back".localized) {
                        currentStep -= 1
                    }
                    .foregroundColor(.blue)
                    .padding(.bottom)
                }
            }
        }
    }
    
    private func completeOnboarding() {
        print("🚀 Onboarding başlatılıyor...")
        
        let genderEnum = Gender(rawValue: onboardingData.gender) ?? .male
        
        let newUser = User(
            name: onboardingData.name,
            age: onboardingData.age,
            gender: genderEnum,
            height: onboardingData.height,
            currentWeight: onboardingData.weight
        )
        
        print("✅ User oluşturuldu: \(newUser.name)")
        
        newUser.fitnessGoal = onboardingData.fitnessGoal
        newUser.activityLevel = onboardingData.activityLevel
        newUser.onboardingCompleted = true
        
        print("✅ User properties set edildi")
        
        modelContext.insert(newUser)
        
        do {
            try modelContext.save()
            print("✅ User kaydedildi")
            
            Task {
                let healthKit = HealthKitService()
                let authorized = await healthKit.requestPermissions()
                if authorized {
                    print("✅ HealthKit authorized")
                } else {
                    print("⚠️ HealthKit authorization reddedildi")
                }
            }
            
            onboardingCompleted = true
            print("✅ Onboarding tamamlandı")
        } catch {
            print("❌ Save error: \(error)")
        }
    }
}

// MARK: - Onboarding Data Model
@Observable
class OnboardingData {
    var name = ""
    var age = 25
    var gender = "male"
    var height = 175.0
    var weight = 70.0
    var targetWeight: Double? = nil
    var fitnessGoal = "maintain"
    var activityLevel = "moderate"
    var neckCircumference: Double? = nil
    var waistCircumference: Double? = nil
    var hipCircumference: Double? = nil
}

// MARK: - Progress Indicator
struct OnboardingProgressView: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(1...totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                    if step < totalSteps {
                        Rectangle()
                            .fill(step < currentStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }
            .padding(.horizontal)
            Text("onboarding.progress.step".localized(with: currentStep, totalSteps))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview
#Preview {
    OnboardingView()
        .modelContainer(for: [User.self], inMemory: true)
}
