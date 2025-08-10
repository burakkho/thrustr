import SwiftUI
import SwiftData

// MARK: - Main Onboarding View
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
                
                if currentStep > 1 {
                    Button("Geri") { currentStep -= 1 }
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
            Text("Adım \(currentStep)/\(totalSteps)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Welcome Step
struct WelcomeStepView: View {
    let onNext: () -> Void
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            VStack(spacing: 16) {
                Text("Spor Hocam'a\nHoş Geldin! 💪")
                    .font(.largeTitle).fontWeight(.bold)
                    .multilineTextAlignment(.center)
                Text("Fitness yolculuğunda yanındayız.\nHadi başlayalım!")
                    .font(.title3).foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "dumbbell.fill", text: "Akıllı antrenman takibi", color: .blue)
                FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "İlerleme analizi", color: .green)
                FeatureRow(icon: "fork.knife", text: "Beslenme kontrolü", color: .orange)
                FeatureRow(icon: "target", text: "Kişisel hedefler", color: .red)
            }
            .padding().background(Color(.systemGray6)).cornerRadius(16)
            .padding(.horizontal)
            Spacer()
            Button(action: onNext) {
                Text("Başlayalım!")
                    .font(.headline).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.blue).cornerRadius(12)
            }
            .padding(.horizontal).padding(.bottom)
        }
    }
}

struct FeatureRow: View {
    let icon: String; let text: String; let color: Color
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(color).frame(width: 24)
            Text(text)
            Spacer()
        }
    }
}

// MARK: - Personal Info Step
struct PersonalInfoStepView: View {
    @Binding var data: OnboardingData
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Kişisel Bilgiler").font(.largeTitle).fontWeight(.bold)
                Text("Seni daha iyi tanıyalım").font(.subheadline).foregroundColor(.secondary)
            }
            .padding(.top)
            
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Adın").font(.headline)
                        TextField("Örn: Burak", text: $data.name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Yaş").font(.headline)
                        Stepper(value: $data.age, in: 15...80) {
                            Text("\(data.age) yaş").font(.title2).fontWeight(.semibold)
                        }
                        .padding().background(Color(.systemGray6)).cornerRadius(12)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cinsiyet").font(.headline)
                        HStack(spacing: 12) {
                            GenderButton(title: "Erkek", icon: "figure.stand",
                                         isSelected: data.gender == "male") { data.gender = "male" }
                            GenderButton(title: "Kadın", icon: "figure.stand.dress",
                                         isSelected: data.gender == "female") { data.gender = "female" }
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Boy").font(.headline)
                        HStack {
                            Text("\(Int(data.height)) cm").font(.title2).fontWeight(.semibold).frame(width: 80, alignment: .leading)
                            Slider(value: $data.height, in: 140...220, step: 1)
                        }
                        .padding().background(Color(.systemGray6)).cornerRadius(12)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Kilo").font(.headline)
                        HStack {
                            Text("\(Int(data.weight)) kg").font(.title2).fontWeight(.semibold).frame(width: 80, alignment: .leading)
                            Slider(value: $data.weight, in: 40...150, step: 0.5)
                        }
                        .padding().background(Color(.systemGray6)).cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
            Button(action: { if !data.name.isEmpty { onNext() } }) {
                Text("Devam Et")
                    .font(.headline).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding()
                    .background(data.name.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(12)
            }
            .disabled(data.name.isEmpty)
            .padding(.horizontal).padding(.bottom)
        }
    }
}

struct GenderButton: View {
    let title: String; let icon: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.title)
                Text(title).font(.headline)
            }
            .frame(maxWidth: .infinity).padding()
            .background(isSelected ? Color.blue.opacity(0.2) : Color(.systemGray6))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color.blue : .clear, lineWidth: 2))
            .cornerRadius(12)
        }
        .foregroundColor(isSelected ? .blue : .primary)
    }
}

// MARK: - Goals Step
struct GoalsStepView: View {
    @Binding var data: OnboardingData
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Hedeflerin").font(.largeTitle).fontWeight(.bold)
                Text("Hangi yönde ilerlemeyi planlıyorsun?")
                    .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
            }
            .padding(.top)
            
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ana Hedefin").font(.headline)
                        VStack(spacing: 8) {
                            GoalOptionButton(title: "Yağ Yakımı", subtitle: "Kilo vermek ve yağ oranını düşürmek",
                                             icon: "flame.fill", color: .red, isSelected: data.fitnessGoal == "cut") { data.fitnessGoal = "cut" }
                            GoalOptionButton(title: "Kas Kazanımı", subtitle: "Kas kütlesi artırmak ve güçlenmek",
                                             icon: "dumbbell.fill", color: .blue, isSelected: data.fitnessGoal == "bulk") { data.fitnessGoal = "bulk" }
                            GoalOptionButton(title: "Form Koruma", subtitle: "Mevcut kiloni koruyarak güçlenmek",
                                             icon: "target", color: .green, isSelected: data.fitnessGoal == "maintain") { data.fitnessGoal = "maintain" }
                        }
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Aktivite Seviyesi").font(.headline)
                        VStack(spacing: 8) {
                            ActivityLevelButton(title: "Hareketsiz", subtitle: "Masa başı iş, az hareket", isSelected: data.activityLevel == "sedentary") { data.activityLevel = "sedentary" }
                            ActivityLevelButton(title: "Hafif Aktif", subtitle: "Haftada 1-2 antrenman", isSelected: data.activityLevel == "light") { data.activityLevel = "light" }
                            ActivityLevelButton(title: "Orta Aktif", subtitle: "Haftada 3-4 antrenman", isSelected: data.activityLevel == "moderate") { data.activityLevel = "moderate" }
                            ActivityLevelButton(title: "Aktif", subtitle: "Haftada 5-6 antrenman", isSelected: data.activityLevel == "active") { data.activityLevel = "active" }
                            ActivityLevelButton(title: "Çok Aktif", subtitle: "Günlük antrenman, fiziksel iş", isSelected: data.activityLevel == "very_active") { data.activityLevel = "very_active" }
                        }
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Hedef Kilo (Opsiyonel)").font(.headline)
                        VStack(spacing: 8) {
                            Toggle("Hedef kilo belirle", isOn: Binding(
                                get: { data.targetWeight != nil },
                                set: { isOn in data.targetWeight = isOn ? data.weight : nil }
                            ))
                            .padding().background(Color(.systemGray6)).cornerRadius(12)
                            
                            if data.targetWeight != nil {
                                HStack {
                                    Text("\(Int(data.targetWeight ?? data.weight)) kg")
                                        .font(.title2).fontWeight(.semibold).frame(width: 80, alignment: .leading)
                                    Slider(value: Binding(get: { data.targetWeight ?? data.weight },
                                                          set: { data.targetWeight = $0 }),
                                           in: 40...150, step: 0.5)
                                }
                                .padding().background(Color(.systemGray6)).cornerRadius(12)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            Button(action: onNext) {
                Text("Devam Et").font(.headline).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding().background(Color.blue).cornerRadius(12)
            }
            .padding(.horizontal).padding(.bottom)
        }
    }
}

struct GoalOptionButton: View {
    let title: String, subtitle: String, icon: String, color: Color, isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.title2).foregroundColor(isSelected ? color : .secondary).frame(width: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                if isSelected { Image(systemName: "checkmark.circle.fill").foregroundColor(color).font(.title2) }
            }
            .padding()
            .background(isSelected ? color.opacity(0.1) : Color(.systemGray6))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? color : .clear, lineWidth: 2))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ActivityLevelButton: View {
    let title: String, subtitle: String, isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle().fill(isSelected ? Color.blue : Color.gray.opacity(0.3)).frame(width: 12, height: 12)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                if isSelected { Image(systemName: "checkmark.circle.fill").foregroundColor(.blue).font(.title2) }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? .blue : .clear, lineWidth: 2))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Measurements Step
struct MeasurementsStepView: View {
    @Binding var data: OnboardingData
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Vücut Ölçümleri").font(.largeTitle).fontWeight(.bold)
                Text("Daha doğru analiz için opsiyonel ölçümler")
                    .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
            }
            .padding(.top)
            
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "ruler").foregroundColor(.blue).font(.title2)
                            Text("Navy Method").font(.headline)
                        }
                        Text("Bu ölçümlerle vücut yağ oranını hesaplayabiliriz. İstersen atlayıp daha sonra Profil'den ekleyebilirsin.")
                            .font(.subheadline).foregroundColor(.secondary)
                    }
                    .padding().background(Color.blue.opacity(0.1)).cornerRadius(12)
                    
                    VStack(spacing: 16) {
                        MeasurementInput(title: "Boyun Çevresi (Gıdık altından)",
                                         value: $data.neckCircumference, range: 25...50, unit: "cm", placeholder: "Opsiyonel")
                        MeasurementInput(title: data.gender == "male" ? "Bel Çevresi (Navel hizasında)" : "Bel Çevresi (En dar yerden)",
                                         value: $data.waistCircumference, range: 50...150, unit: "cm", placeholder: "Opsiyonel")
                        if data.gender == "female" {
                            MeasurementInput(title: "Kalça Çevresi (En geniş yerden)",
                                             value: $data.hipCircumference, range: 70...150, unit: "cm", placeholder: "Opsiyonel")
                        }
                    }
                    
                    if canCalculateNavyMethod() {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "chart.pie.fill").foregroundColor(.green).font(.title2)
                                Text("Hesaplanan Vücut Yağ %").font(.headline)
                            }
                            let bodyFat = calculateNavyMethod()
                            HStack {
                                Text("Navy Method:").foregroundColor(.secondary)
                                Spacer()
                                Text("%\(String(format: "%.1f", bodyFat))")
                                    .font(.title2).fontWeight(.bold).foregroundColor(.green)
                            }
                        }
                        .padding().background(Color.green.opacity(0.1)).cornerRadius(12)
                    }
                    
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill").foregroundColor(.gray)
                            Text("Bu ölçümler tamamen opsiyonel").font(.subheadline).fontWeight(.medium)
                            Spacer()
                        }
                        Text("Atlayıp daha sonra Profil ayarlarından da ekleyebilirsin.")
                            .font(.caption).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding().background(Color(.systemGray6)).cornerRadius(12)
                }
                .padding(.horizontal)
            }
            
            VStack(spacing: 12) {
                Button(action: onNext) {
                    Text("Devam Et").font(.headline).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding().background(Color.blue).cornerRadius(12)
                }
                Button("Bu Adımı Atla") {
                    data.neckCircumference = nil; data.waistCircumference = nil; data.hipCircumference = nil
                    onNext()
                }
                .font(.subheadline).foregroundColor(.blue)
            }
            .padding(.horizontal).padding(.bottom)
        }
    }
    
    private func canCalculateNavyMethod() -> Bool {
        if data.gender == "male" {
            return data.neckCircumference != nil && data.waistCircumference != nil
        } else {
            return data.neckCircumference != nil && data.waistCircumference != nil && data.hipCircumference != nil
        }
    }
    
    private func calculateNavyMethod() -> Double {
        guard let neck = data.neckCircumference, let waist = data.waistCircumference else { return 0 }
        let height = data.height
        if data.gender == "male" {
            let denom = 1.0324 - 0.19077 * log10(waist - neck) + 0.15456 * log10(height)
            return max(0, min(50, 495 / denom - 450))
        } else {
            guard let hip = data.hipCircumference else { return 0 }
            let denom = 1.29579 - 0.35004 * log10(waist + hip - neck) + 0.22100 * log10(height)
            return max(0, min(50, 495 / denom - 450))
        }
    }
}

// MARK: - Measurement Input
struct MeasurementInput: View {
    let title: String
    @Binding var value: Double?
    let range: ClosedRange<Double>
    let unit: String
    let placeholder: String
    
    @State private var textValue: String = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            HStack {
                TextField(placeholder, text: $textValue)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: textValue) { _, newValue in
                        if let v = Double(newValue), range.contains(v) { value = v }
                        else if newValue.isEmpty { value = nil }
                    }
                    .onAppear {
                        if let v = value { textValue = String(format: "%.0f", v) }
                    }
                Text(unit).foregroundColor(.secondary).padding(.trailing, 8)
            }
        }
    }
}

// MARK: - Summary Step
struct SummaryStepView: View {
    let data: OnboardingData
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Planın Hazır! 🎉").font(.largeTitle).fontWeight(.bold)
                Text("Bilgilerine göre hesapladığımız değerler")
                    .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
            }
            .padding(.top)
            
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Profil Özeti").font(.headline); Spacer()
                            Image(systemName: "person.crop.circle.fill").foregroundColor(.blue).font(.title2)
                        }
                        VStack(spacing: 8) {
                            SummaryRow(label: "İsim", value: data.name)
                            SummaryRow(label: "Yaş", value: "\(data.age) yaş")
                            SummaryRow(label: "Cinsiyet", value: data.gender == "male" ? "Erkek" : "Kadın")
                            SummaryRow(label: "Boy", value: "\(Int(data.height)) cm")
                            SummaryRow(label: "Kilo", value: "\(Int(data.weight)) kg")
                            if let targetWeight = data.targetWeight {
                                SummaryRow(label: "Hedef Kilo", value: "\(Int(targetWeight)) kg")
                            }
                        }
                    }
                    .padding().background(Color(.systemGray6)).cornerRadius(16)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Hedefler").font(.headline); Spacer()
                            Image(systemName: "target").foregroundColor(.green).font(.title2)
                        }
                        VStack(spacing: 8) {
                            SummaryRow(label: "Ana Hedef", value: goalDisplayName(data.fitnessGoal))
                            SummaryRow(label: "Aktivite", value: activityDisplayName(data.activityLevel))
                        }
                    }
                    .padding().background(Color(.systemGray6)).cornerRadius(16)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Hesaplanan Değerler").font(.headline); Spacer()
                            Image(systemName: "chart.line.uptrend.xyaxis").foregroundColor(.orange).font(.title2)
                        }
                        VStack(spacing: 8) {
                            let bmr = calculateBMR()
                            let usesNavy = canCalculateNavyMethod()
                            SummaryRow(label: usesNavy ? "BMR (Katch-McArdle)" : "BMR (Mifflin-St Jeor)", value: "\(Int(bmr)) kcal")
                            if usesNavy {
                                let bf = calculateNavyMethod()
                                let lbm = data.weight * (1 - bf / 100.0)
                                SummaryRow(label: "Yağsız Kütle (LBM)", value: "\(String(format: "%.1f", lbm)) kg")
                                SummaryRow(label: "Vücut Yağ % (Navy)", value: "%\(String(format: "%.1f", bf))")
                            }
                            SummaryRow(label: "TDEE (Günlük Harcama)", value: "\(Int(calculateTDEE())) kcal")
                            SummaryRow(label: "Günlük Hedef Kalori", value: "\(Int(calculateCalorieGoal())) kcal")
                        }
                        Divider()
                        Text("Makro Hedefleri").font(.subheadline).fontWeight(.semibold)
                        let m = calculateMacros()
                        VStack(spacing: 8) {
                            SummaryRow(label: "Protein", value: "\(Int(m.protein))g")
                            SummaryRow(label: "Karbonhidrat", value: "\(Int(m.carbs))g")
                            SummaryRow(label: "Yağ", value: "\(Int(m.fat))g")
                        }
                    }
                    .padding().background(Color(.systemGray6)).cornerRadius(16)
                    
                    VStack(spacing: 8) {
                        HStack { Image(systemName: "info.circle.fill").foregroundColor(.blue); Text("Bilgi").font(.headline); Spacer() }
                        Text(canCalculateNavyMethod()
                             ? "Vücut yağ oranın Navy Method ile hesaplandığı için daha doğru Katch-McArdle formülü kullanıldı. İstediğin zaman profil ayarlarından değiştirebilirsin."
                             : "Vücut ölçümleri olmadığı için Mifflin-St Jeor formülü kullanıldı. Daha doğru hesaplama için profil ayarlarından ölçümlerini ekleyebilirsin.")
                        .font(.caption).foregroundColor(.secondary).multilineTextAlignment(.leading)
                    }
                    .padding().background(Color.blue.opacity(0.1)).cornerRadius(12)
                }
                .padding(.horizontal)
            }
            
            Button(action: onComplete) {
                HStack { Text("Uygulamayı Başlat").font(.headline); Image(systemName: "arrow.right").font(.headline) }
                    .foregroundColor(.white).frame(maxWidth: .infinity).padding()
                    .background(LinearGradient(colors: [Color.green, Color.blue], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(12)
            }
            .padding(.horizontal).padding(.bottom)
        }
    }
    
    // MARK: Calculations
    private func calculateBMR() -> Double {
        if canCalculateNavyMethod() {
            let bf = calculateNavyMethod() / 100.0
            let lbm = data.weight * (1 - bf)
            return 370 + 21.6 * lbm
        } else {
            let w = 10 * data.weight
            let h = 6.25 * data.height
            let a = 5 * Double(data.age)
            return data.gender == "male" ? (w + h - a + 5) : (w + h - a - 161)
        }
    }
    
    private func calculateTDEE() -> Double {
        let bmr = calculateBMR()
        switch data.activityLevel {
        case "sedentary": return bmr * 1.2
        case "light": return bmr * 1.375
        case "moderate": return bmr * 1.55
        case "active": return bmr * 1.725
        case "very_active": return bmr * 1.9
        default: return bmr * 1.55
        }
    }
    
    private func calculateCalorieGoal() -> Double {
        let t = calculateTDEE()
        switch data.fitnessGoal {
        case "cut": return t * 0.8
        case "bulk": return t * 1.1
        case "maintain": return t
        default: return t
        }
    }
    
    private func calculateMacros() -> (protein: Double, carbs: Double, fat: Double) {
        let cals = calculateCalorieGoal()
        let protein = data.weight * 2.0
        let fat = (cals * 0.25) / 9
        let carbs = (cals - protein * 4 - fat * 9) / 4
        return (protein, carbs, fat)
    }
    
    private func canCalculateNavyMethod() -> Bool {
        if data.gender == "male" {
            return data.neckCircumference != nil && data.waistCircumference != nil
        } else {
            return data.neckCircumference != nil && data.waistCircumference != nil && data.hipCircumference != nil
        }
    }
    
    private func calculateNavyMethod() -> Double {
        guard let neck = data.neckCircumference, let waist = data.waistCircumference else { return 0 }
        let h = data.height
        if data.gender == "male" {
            let d = 1.0324 - 0.19077 * log10(waist - neck) + 0.15456 * log10(h)
            return max(0, min(50, 495 / d - 450))
        } else {
            guard let hip = data.hipCircumference else { return 0 }
            let d = 1.29579 - 0.35004 * log10(waist + hip - neck) + 0.22100 * log10(h)
            return max(0, min(50, 495 / d - 450))
        }
    }
    
    private func goalDisplayName(_ g: String) -> String {
        switch g {
        case "cut": return "Yağ Yakımı"
        case "bulk": return "Kas Kazanımı"
        case "maintain": return "Form Koruma"
        default: return "Bilinmiyor"
        }
    }
    
    private func activityDisplayName(_ a: String) -> String {
        switch a {
        case "sedentary": return "Hareketsiz"
        case "light": return "Hafif Aktif"
        case "moderate": return "Orta Aktif"
        case "active": return "Aktif"
        case "very_active": return "Çok Aktif"
        default: return "Bilinmiyor"
        }
    }
}

// MARK: - Summary Row
struct SummaryRow: View {
    let label: String; let value: String
    var body: some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: [User.self], inMemory: true)
}
