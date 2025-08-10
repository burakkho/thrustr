import SwiftUI

struct NavyMethodCalculatorView: View {
    @State private var gender: NavyGender = .male
    @State private var age = ""
    @State private var height = ""
    @State private var waist = ""
    @State private var neck = ""
    @State private var hips = ""
    @State private var calculatedBodyFat: Double?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                NavyMethodHeaderSection()
                
                // Gender Selection
                NavyGenderSection(selectedGender: $gender)
                
                // Input Section
                NavyInputSection(
                    gender: gender,
                    age: $age,
                    height: $height,
                    waist: $waist,
                    neck: $neck,
                    hips: $hips
                )
                
                // Calculate Button
                Button {
                    calculateBodyFat()
                } label: {
                    Text("Hesapla")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.orange : Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!isFormValid)
                .padding(.horizontal)
                
                // Results Section
                if let bodyFat = calculatedBodyFat {
                    NavyResultsSection(bodyFat: bodyFat, gender: gender)
                }
                
                // Body Fat Scale Section
                BodyFatScaleSection(gender: gender)
                
                
                // Info Section
                NavyInfoSection()
            }
            .padding()
        }
        .navigationTitle("Navy Method")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
    
    private var isFormValid: Bool {
        guard let ageValue = Int(age),
              let heightValue = Double(height.replacingOccurrences(of: ",", with: ".")),
              let waistValue = Double(waist.replacingOccurrences(of: ",", with: ".")),
              let neckValue = Double(neck.replacingOccurrences(of: ",", with: ".")) else { return false }
        
        let basicValid = ageValue > 0 && heightValue > 0 && waistValue > 0 && neckValue > 0
        
        if gender == .female {
            guard let hipsValue = Double(hips.replacingOccurrences(of: ",", with: ".")) else { return false }
            return basicValid && hipsValue > 0
        }
        
        return basicValid
    }
    
    private func calculateBodyFat() {
        guard let _ = Int(age),
              let heightValue = Double(height.replacingOccurrences(of: ",", with: ".")),
              let waistValue = Double(waist.replacingOccurrences(of: ",", with: ".")),
              let neckValue = Double(neck.replacingOccurrences(of: ",", with: ".")) else { return }
        
        if gender == .male {
            // Male formula: 495 / (1.0324 - 0.19077 * log10(waist - neck) + 0.15456 * log10(height)) - 450
            let logWaistNeck = log10(waistValue - neckValue)
            let logHeight = log10(heightValue)
            let bodyFatPercentage = 495 / (1.0324 - 0.19077 * logWaistNeck + 0.15456 * logHeight) - 450
            calculatedBodyFat = max(0, bodyFatPercentage)
        } else {
            // Female formula: 495 / (1.29579 - 0.35004 * log10(waist + hip - neck) + 0.22100 * log10(height)) - 450
            guard let hipsValue = Double(hips.replacingOccurrences(of: ",", with: ".")) else { return }
            let logWaistHipNeck = log10(waistValue + hipsValue - neckValue)
            let logHeight = log10(heightValue)
            let bodyFatPercentage = 495 / (1.29579 - 0.35004 * logWaistHipNeck + 0.22100 * logHeight) - 450
            calculatedBodyFat = max(0, bodyFatPercentage)
        }
    }
}

// MARK: - Header Section
struct NavyMethodHeaderSection: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "percent")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("Navy Method")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Vücut yağ oranınızı ölçümlerle hesaplayın")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Gender Selection Section
struct NavyGenderSection: View {
    @Binding var selectedGender: NavyGender
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cinsiyet")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                ForEach(NavyGender.allCases, id: \.self) { gender in
                    Button {
                        selectedGender = gender
                    } label: {
                        HStack {
                            Image(systemName: gender.icon)
                                .font(.title2)
                                .foregroundColor(selectedGender == gender ? .white : gender.color)
                            
                            Text(gender.displayName)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(selectedGender == gender ? .white : .primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedGender == gender ? gender.color : Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - Input Section
struct NavyInputSection: View {
    let gender: NavyGender
    @Binding var age: String
    @Binding var height: String
    @Binding var waist: String
    @Binding var neck: String
    @Binding var hips: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Ölçümler")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // Age Input
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        Text("Yaş")
                            .fontWeight(.medium)
                    }
                    
                    TextField("25", text: $age)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title3)
                }
                
                // Height Input
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "ruler.fill")
                            .foregroundColor(.green)
                        Text("Boy (cm)")
                            .fontWeight(.medium)
                    }
                    
                    TextField("175", text: $height)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title3)
                }
                
                // Waist Input
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "oval.fill")
                            .foregroundColor(.orange)
                        Text("Bel Çevresi (cm)")
                            .fontWeight(.medium)
                    }
                    
                    TextField("85", text: $waist)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title3)
                }
                
                // Neck Input
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "person.crop.circle")
                            .foregroundColor(.purple)
                        Text("Boyun Çevresi (cm)")
                            .fontWeight(.medium)
                    }
                    
                    TextField("38", text: $neck)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title3)
                }
                
                // Hips Input (only for females)
                if gender == .female {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "circle.fill")
                                .foregroundColor(.pink)
                            Text("Kalça Çevresi (cm)")
                                .fontWeight(.medium)
                        }
                        
                        TextField("95", text: $hips)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.title3)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - Results Section
struct NavyResultsSection: View {
    let bodyFat: Double
    let gender: NavyGender
    
    private var bodyFatCategory: BodyFatCategory {
        BodyFatCategory.category(for: bodyFat, gender: gender)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Sonuçlar")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // Body Fat Result
                VStack(spacing: 8) {
                    Text("Vücut Yağ Oranınız")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(String(format: "%.1f", bodyFat))%")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(bodyFatCategory.color)
                    
                    Text(bodyFatCategory.description)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(bodyFatCategory.color)
                    
                    Text(bodyFatCategory.interpretation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(bodyFatCategory.color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - Body Fat Scale Section
struct BodyFatScaleSection: View {
    let gender: NavyGender
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(gender.displayName) Vücut Yağ Skalası")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(BodyFatCategory.allCases, id: \.self) { category in
                    BodyFatScaleRow(category: category, gender: gender)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

struct BodyFatScaleRow: View {
    let category: BodyFatCategory
    let gender: NavyGender
    
    var body: some View {
        HStack {
            Circle()
                .fill(category.color)
                .frame(width: 12, height: 12)
            
            Text(category.description)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(category.range(for: gender))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Info Section
struct NavyInfoSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Navy Method Hakkında")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                NavyInfoRow(
                    icon: "info.circle.fill",
                    title: "Güvenilirlik",
                    description: "ABD Donanması tarafından geliştirilen, bilimsel olarak kanıtlanmış yöntem"
                )
                
                NavyInfoRow(
                    icon: "ruler.fill",
                    title: "Doğruluk",
                    description: "±3-4% hata payı ile oldukça doğru sonuçlar verir"
                )
                
                NavyInfoRow(
                    icon: "exclamationmark.triangle.fill",
                    title: "Önemli Not",
                    description: "Ölçüm hassasiyeti sonucu doğrudan etkiler, dikkatli ölçün"
                )
                
                NavyInfoRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Takip",
                    description: "Düzenli ölçümlerle ilerlemenizi takip edebilirsiniz"
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

struct NavyInfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.orange)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Navy Gender Enum
enum NavyGender: CaseIterable {
    case male
    case female
    
    var displayName: String {
        switch self {
        case .male: return "Erkek"
        case .female: return "Kadın"
        }
    }
    
    var icon: String {
        switch self {
        case .male: return "person.fill"
        case .female: return "person.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .male: return .blue
        case .female: return .pink
        }
    }
}

// MARK: - Body Fat Category Enum
enum BodyFatCategory: CaseIterable {
    case essential
    case athlete
    case fitness
    case average
    case obese
    
    var description: String {
        switch self {
        case .essential: return "Temel Yağ"
        case .athlete: return "Atlet"
        case .fitness: return "Fitness"
        case .average: return "Ortalama"
        case .obese: return "Obez"
        }
    }
    
    func range(for gender: NavyGender) -> String {
        switch (self, gender) {
        case (.essential, .male): return "2-5%"
        case (.essential, .female): return "10-13%"
        case (.athlete, .male): return "6-13%"
        case (.athlete, .female): return "14-20%"
        case (.fitness, .male): return "14-17%"
        case (.fitness, .female): return "21-24%"
        case (.average, .male): return "18-24%"
        case (.average, .female): return "25-31%"
        case (.obese, .male): return "25%+"
        case (.obese, .female): return "32%+"
        }
    }
    
    var interpretation: String {
        switch self {
        case .essential: return "Vücudun temel işlevleri için gerekli minimum yağ"
        case .athlete: return "Profesyonel sporcular için ideal seviye"
        case .fitness: return "Aktif ve sağlıklı bireyler için ideal"
        case .average: return "Sağlıklı kabul edilen normal seviye"
        case .obese: return "Sağlık riskleri olabilir, kilo vermeyi düşünün"
        }
    }
    
    var color: Color {
        switch self {
        case .essential: return .blue
        case .athlete: return .green
        case .fitness: return .yellow
        case .average: return .orange
        case .obese: return .red
        }
    }
    
    static func category(for bodyFat: Double, gender: NavyGender) -> BodyFatCategory {
        switch gender {
        case .male:
            switch bodyFat {
            case 0..<6: return .essential
            case 6..<14: return .athlete
            case 14..<18: return .fitness
            case 18..<25: return .average
            default: return .obese
            }
        case .female:
            switch bodyFat {
            case 0..<14: return .essential
            case 14..<21: return .athlete
            case 21..<25: return .fitness
            case 25..<32: return .average
            default: return .obese
            }
        }
    }
}

#Preview {
    NavigationStack {
        NavyMethodCalculatorView()
    }
}
