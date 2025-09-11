//
//  OnboardingView.swift
//  Thrustr
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
    @State private var toastMessage: String? = nil
    
    // Eşitlenebilir anlık görüntü: herhangi bir alan değiştiğinde değişir
    private var dataSnapshot: DataSnapshot {
        DataSnapshot(
            name: onboardingData.name,
            age: onboardingData.age,
            gender: onboardingData.gender,
            height: onboardingData.height,
            weight: onboardingData.weight,
            targetWeight: onboardingData.targetWeight,
            fitnessGoal: onboardingData.fitnessGoal,
            activityLevel: onboardingData.activityLevel,
            unitSystem: onboardingData.unitSystem,
            neckCircumference: onboardingData.neckCircumference,
            waistCircumference: onboardingData.waistCircumference,
            hipCircumference: onboardingData.hipCircumference
        )
    }
    
    var body: some View {
        ZStack {
            // Onboarding arka planını sade beyaza çekiyoruz
            Color(.systemBackground)
                .ignoresSafeArea()
            
            ToastPresenter(message: $toastMessage, icon: "exclamationmark.triangle.fill", type: .error) {
            VStack {
                if currentStep > 0 {
                    InteractiveProgressBar(currentStep: currentStep, totalSteps: 6, style: .compact)
                        .padding(.top, 8)
                }
                
                switch currentStep {
                case 0: WelcomeStepView(onNext: { currentStep = 1 })
                case 1: ConsentStepView(data: $onboardingData, onNext: { currentStep = 2 })
                case 2: PersonalInfoStepView(data: $onboardingData, onNext: { currentStep = 3 })
                case 3: GoalsStepView(data: $onboardingData, onNext: { currentStep = 4 })
                case 4: MeasurementsStepView(data: $onboardingData, onNext: { currentStep = 5 })
                case 5: SummaryStepView(data: onboardingData, onComplete: completeOnboarding)
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
                    .accessibilityHint(Text("accessibility.back_step".localized))
                    .padding(.bottom)
                }
            }
            // ✅ Klavye constraint sorununu çözmek için bu satırı kaldırıyoruz
            // .scrollDismissesKeyboard(.interactively)
            }
            .onAppear(perform: restoreProgressIfNeeded)
            .onChange(of: currentStep) { _, _ in
                persistProgress()
            }
            // Form alanı değişiminde anında kaydet
            .onChange(of: dataSnapshot) { _, _ in
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
            currentWeight: onboardingData.weight,
            fitnessGoal: FitnessGoal(rawValue: onboardingData.fitnessGoal) ?? .maintain,
            activityLevel: ActivityLevel(rawValue: onboardingData.activityLevel) ?? .moderate,
            selectedLanguage: LanguageManager.shared.currentLanguage.rawValue,
            consentAccepted: onboardingData.consentAccepted,
            marketingOptIn: onboardingData.marketingOptIn,
            consentTimestamp: onboardingData.consentTimestamp
        )
        
        print("✅ User oluşturuldu: \(newUser.name)")
        
        newUser.onboardingCompleted = true

        // Navy ölçülerini kullanıcı modeline aktar ve metrikleri güncelle
        newUser.neck = onboardingData.neckCircumference
        newUser.waist = onboardingData.waistCircumference
        newUser.hips = onboardingData.hipCircumference
        newUser.calculateMetrics()
        
        print("✅ User properties set edildi")
        
        modelContext.insert(newUser)
        
        do {
            try modelContext.save()
            print("✅ User kaydedildi")
            
            Task { @MainActor in
                let healthKit = HealthKitService()
                let authorized = await healthKit.requestPermissions()
                if authorized {
                    print("✅ HealthKit authorized")
                } else {
                    print("⚠️ HealthKit authorization reddedildi")
                    await MainActor.run {
                        toastMessage = "healthkit.permission_denied".localized
                    }
                }
            }
            
            onboardingCompleted = true
            // Başlangıç ölçümleri (isteğe bağlı kayıtlar)
            createInitialEntries(for: newUser)
            // Temizle
            savedStep = 0
            savedDataJSON = ""
            print("✅ Onboarding tamamlandı")
        } catch {
            print("❌ Save error: \(error)")
            toastMessage = "error.save_failed".localized + ": \(error.localizedDescription)"
        }
    }
    
    private func createInitialEntries(for user: User) {
        // Başlangıç ağırlığı
        let weightEntry = WeightEntry(weight: user.currentWeight, date: Date())
        weightEntry.user = user
        modelContext.insert(weightEntry)
        
        // Opsiyonel Navy ölçümlerini BodyMeasurement olarak kaydet
        if let neck = onboardingData.neckCircumference {
            let m = BodyMeasurement(type: MeasurementType.neck.rawValue, value: neck, date: Date())
            m.user = user
            modelContext.insert(m)
        }
        if let waist = onboardingData.waistCircumference {
            let m = BodyMeasurement(type: MeasurementType.waist.rawValue, value: waist, date: Date())
            m.user = user
            modelContext.insert(m)
        }
        if let hip = onboardingData.hipCircumference {
            let m = BodyMeasurement(type: MeasurementType.hips.rawValue, value: hip, date: Date())
            m.user = user
            modelContext.insert(m)
        }
        do { try modelContext.save() } catch { print("❌ Initial entries save error: \(error)") }
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
    var unitSystem: String // "metric" | "imperial"
    var neckCircumference: Double?
    var waistCircumference: Double?
    var hipCircumference: Double?
    // Consent
    var consentAccepted: Bool
    var marketingOptIn: Bool
    var consentTimestamp: Date?

    enum CodingKeys: String, CodingKey {
        case name, age, gender, height, weight, targetWeight, fitnessGoal, activityLevel, unitSystem, neckCircumference, waistCircumference, hipCircumference, consentAccepted, marketingOptIn, consentTimestamp
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
        unitSystem: String = "metric",
        neckCircumference: Double? = nil,
        waistCircumference: Double? = nil,
        hipCircumference: Double? = nil,
        consentAccepted: Bool = false,
        marketingOptIn: Bool = false,
        consentTimestamp: Date? = nil,
    ) {
        self.name = name
        self.age = age
        self.gender = gender
        self.height = height
        self.weight = weight
        self.targetWeight = targetWeight
        self.fitnessGoal = fitnessGoal
        self.activityLevel = activityLevel
        self.unitSystem = unitSystem
        self.neckCircumference = neckCircumference
        self.waistCircumference = waistCircumference
        self.hipCircumference = hipCircumference
        self.consentAccepted = consentAccepted
        self.marketingOptIn = marketingOptIn
        self.consentTimestamp = consentTimestamp
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
        self.unitSystem = try container.decodeIfPresent(String.self, forKey: .unitSystem) ?? "metric"
        self.neckCircumference = try container.decodeIfPresent(Double.self, forKey: .neckCircumference)
        self.waistCircumference = try container.decodeIfPresent(Double.self, forKey: .waistCircumference)
        self.hipCircumference = try container.decodeIfPresent(Double.self, forKey: .hipCircumference)
        self.consentAccepted = try container.decodeIfPresent(Bool.self, forKey: .consentAccepted) ?? false
        self.marketingOptIn = try container.decodeIfPresent(Bool.self, forKey: .marketingOptIn) ?? false
        self.consentTimestamp = try container.decodeIfPresent(Date.self, forKey: .consentTimestamp)
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
        try container.encode(unitSystem, forKey: .unitSystem)
        try container.encodeIfPresent(neckCircumference, forKey: .neckCircumference)
        try container.encodeIfPresent(waistCircumference, forKey: .waistCircumference)
        try container.encodeIfPresent(hipCircumference, forKey: .hipCircumference)
        try container.encode(consentAccepted, forKey: .consentAccepted)
        try container.encode(marketingOptIn, forKey: .marketingOptIn)
        try container.encodeIfPresent(consentTimestamp, forKey: .consentTimestamp)
    }
}

// MARK: - Snapshot Model (Equatable)
private struct DataSnapshot: Equatable {
    let name: String
    let age: Int
    let gender: String
    let height: Double
    let weight: Double
    let targetWeight: Double?
    let fitnessGoal: String
    let activityLevel: String
    let unitSystem: String
    let neckCircumference: Double?
    let waistCircumference: Double?
    let hipCircumference: Double?
}

// (Legacy OnboardingProgressView replaced by InteractiveProgressBar)

// MARK: - Preview
#Preview {
    OnboardingView()
        .modelContainer(for: [User.self], inMemory: true)
}
