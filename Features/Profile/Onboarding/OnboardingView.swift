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
    @AppStorage("onboardingStep") private var savedStep: Int = 0
    @AppStorage("onboardingData") private var savedDataJSON: String = ""
    @State private var currentStep = 0
    @State private var onboardingData = OnboardingData()
    
    var body: some View {
        ZStack {
            // Onboarding arka planını sade beyaza çekiyoruz
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack {
                if currentStep > 0 {
                    InteractiveProgressBar(currentStep: currentStep, totalSteps: 5, style: .compact)
                        .padding(.top, 8)
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
                    .accessibilityLabel(Text("onboarding.back".localized))
                    .accessibilityHint(Text("Bir önceki adıma döner"))
                    .padding(.bottom)
                }
            }
            .onAppear(perform: restoreProgressIfNeeded)
            .onChange(of: currentStep) { _, _ in
                persistProgress()
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
            // Temizle
            savedStep = 0
            savedDataJSON = ""
            print("✅ Onboarding tamamlandı")
        } catch {
            print("❌ Save error: \(error)")
        }
    }

    // MARK: - Persistence
    private func persistProgress() {
        savedStep = currentStep
        if let encoded = try? JSONEncoder().encode(onboardingData),
           let json = String(data: encoded, encoding: .utf8) {
            savedDataJSON = json
        }
    }
    
    private func restoreProgressIfNeeded() {
        guard !onboardingCompleted else { return }
        currentStep = savedStep
        if !savedDataJSON.isEmpty, let data = savedDataJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(OnboardingData.self, from: data) {
            onboardingData = decoded
        }
    }
}

// MARK: - Onboarding Data Model
@Observable
class OnboardingData: Codable {
    var name: String
    var age: Int
    var gender: String
    var height: Double
    var weight: Double
    var targetWeight: Double?
    var fitnessGoal: String
    var activityLevel: String
    var neckCircumference: Double?
    var waistCircumference: Double?
    var hipCircumference: Double?

    enum CodingKeys: String, CodingKey {
        case name, age, gender, height, weight, targetWeight, fitnessGoal, activityLevel, neckCircumference, waistCircumference, hipCircumference
    }

    init(
        name: String = "",
        age: Int = 25,
        gender: String = "male",
        height: Double = 175.0,
        weight: Double = 70.0,
        targetWeight: Double? = nil,
        fitnessGoal: String = "maintain",
        activityLevel: String = "moderate",
        neckCircumference: Double? = nil,
        waistCircumference: Double? = nil,
        hipCircumference: Double? = nil
    ) {
        self.name = name
        self.age = age
        self.gender = gender
        self.height = height
        self.weight = weight
        self.targetWeight = targetWeight
        self.fitnessGoal = fitnessGoal
        self.activityLevel = activityLevel
        self.neckCircumference = neckCircumference
        self.waistCircumference = waistCircumference
        self.hipCircumference = hipCircumference
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.age = try container.decodeIfPresent(Int.self, forKey: .age) ?? 25
        self.gender = try container.decodeIfPresent(String.self, forKey: .gender) ?? "male"
        self.height = try container.decodeIfPresent(Double.self, forKey: .height) ?? 175.0
        self.weight = try container.decodeIfPresent(Double.self, forKey: .weight) ?? 70.0
        self.targetWeight = try container.decodeIfPresent(Double.self, forKey: .targetWeight)
        self.fitnessGoal = try container.decodeIfPresent(String.self, forKey: .fitnessGoal) ?? "maintain"
        self.activityLevel = try container.decodeIfPresent(String.self, forKey: .activityLevel) ?? "moderate"
        self.neckCircumference = try container.decodeIfPresent(Double.self, forKey: .neckCircumference)
        self.waistCircumference = try container.decodeIfPresent(Double.self, forKey: .waistCircumference)
        self.hipCircumference = try container.decodeIfPresent(Double.self, forKey: .hipCircumference)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(age, forKey: .age)
        try container.encode(gender, forKey: .gender)
        try container.encode(height, forKey: .height)
        try container.encode(weight, forKey: .weight)
        try container.encodeIfPresent(targetWeight, forKey: .targetWeight)
        try container.encode(fitnessGoal, forKey: .fitnessGoal)
        try container.encode(activityLevel, forKey: .activityLevel)
        try container.encodeIfPresent(neckCircumference, forKey: .neckCircumference)
        try container.encodeIfPresent(waistCircumference, forKey: .waistCircumference)
        try container.encodeIfPresent(hipCircumference, forKey: .hipCircumference)
    }
}

// (Legacy OnboardingProgressView replaced by InteractiveProgressBar)

// MARK: - Preview
#Preview {
    OnboardingView()
        .modelContainer(for: [User.self], inMemory: true)
}
