import SwiftUI

struct FFMICalculatorView: View {
    @EnvironmentObject private var unitSettings: UnitSettings
    @State private var weight = ""
    @State private var height = ""
    @State private var bodyFat = ""
    @State private var calculatedFFMI: Double?
    @State private var leanMass: Double?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                FFMIHeaderSection()
                
                // Input Section
                FFMIInputSection(
                    unitSystem: unitSettings.unitSystem,
                    weight: $weight,
                    height: $height,
                    bodyFat: $bodyFat
                )
                
                // Calculate Button
                Button {
                    calculateFFMI()
                } label: {
                    Text("Hesapla")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.green : Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!isFormValid)
                .padding(.horizontal)
                
                // Results Section
                if let ffmi = calculatedFFMI, let leanMass = leanMass {
                    FFMIResultsSection(ffmi: ffmi, leanMass: leanMass)
                }
                
                // FFMI Scale Section
                FFMIScaleSection()
                
                // Info Section
                FFMIInfoSection()
            }
            .padding()
        }
        .navigationTitle("FFMI Hesaplayıcı")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
    
    private var isFormValid: Bool {
        guard let weightValue = Double(weight.replacingOccurrences(of: ",", with: ".")),
              let heightValue = Double(height.replacingOccurrences(of: ",", with: ".")),
              let bodyFatValue = Double(bodyFat.replacingOccurrences(of: ",", with: ".")) else { return false }
        return weightValue > 0 && heightValue > 0 && bodyFatValue >= 3 && bodyFatValue <= 50
    }
    
    private func calculateFFMI() {
        guard let weightValue = Double(weight.replacingOccurrences(of: ",", with: ".")),
              let heightValue = Double(height.replacingOccurrences(of: ",", with: ".")),
              let bodyFatValue = Double(bodyFat.replacingOccurrences(of: ",", with: ".")) else { return }
        
        // Normalize inputs to metric if needed
        let weightKg = unitSettings.unitSystem == .imperial ? UnitsConverter.lbsToKg(weightValue) : weightValue
        let heightCm = heightValue // keep cm input for now

        // Calculate lean mass
        let fatMass = weightKg * (bodyFatValue / 100)
        let leanMassValue = weightKg - fatMass
        
        // Calculate FFMI
        let heightInMeters = heightCm / 100
        let ffmiValue = leanMassValue / (heightInMeters * heightInMeters)
        
        // Normalized FFMI (adjust for height)
        let normalizedFFMI = ffmiValue + 6.1 * (1.8 - heightInMeters)
        
        leanMass = leanMassValue
        calculatedFFMI = normalizedFFMI
    }
}

// MARK: - Header Section
struct FFMIHeaderSection: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            VStack(spacing: 8) {
                Text("FFMI Hesaplayıcı")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Yağsız Kas Kütlesi İndeksinizi hesaplayın")
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

// MARK: - Input Section
struct FFMIInputSection: View {
    let unitSystem: UnitSystem
    @Binding var weight: String
    @Binding var height: String
    @Binding var bodyFat: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Vücut Ölçümleri")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // Weight Input
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "scalemass.fill")
                            .foregroundColor(.green)
                        Text(unitSystem == .metric ? "Vücut Ağırlığı (kg)" : "Vücut Ağırlığı (lb)")
                            .fontWeight(.medium)
                    }
                    
                    TextField(unitSystem == .metric ? "75" : "165", text: $weight)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title3)
                }
                
                // Height Input
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "ruler.fill")
                            .foregroundColor(.blue)
                        Text("Boy (cm)")
                            .fontWeight(.medium)
                    }
                    
                    TextField("175", text: $height)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title3)
                }
                
                // Body Fat Input
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "percent")
                            .foregroundColor(.orange)
                        Text("Vücut Yağ Oranı (%)")
                            .fontWeight(.medium)
                    }
                    
                    TextField("15", text: $bodyFat)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title3)
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
struct FFMIResultsSection: View {
    let ffmi: Double
    let leanMass: Double
    
    private var ffmiCategory: FFMICategory {
        FFMICategory.category(for: ffmi)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Sonuçlar")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // FFMI Result
                VStack(spacing: 8) {
                    Text("FFMI Değeriniz")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.1f", ffmi))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(ffmiCategory.color)
                    
                    Text(ffmiCategory.description)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(ffmiCategory.color)
                    
                    Text(ffmiCategory.interpretation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(ffmiCategory.color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Lean Mass
                VStack(spacing: 8) {
                    Text("Yağsız Kas Kütlesi")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(String(format: "%.1f", leanMass)) kg")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - FFMI Scale Section
struct FFMIScaleSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("FFMI Skalası")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(FFMICategory.allCases, id: \.self) { category in
                    FFMIScaleRow(category: category)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

struct FFMIScaleRow: View {
    let category: FFMICategory
    
    var body: some View {
        HStack {
            Circle()
                .fill(category.color)
                .frame(width: 12, height: 12)
            
            Text(category.description)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(category.range)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Info Section
struct FFMIInfoSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("FFMI Hakkında")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                InfoRowFFMI(
                    icon: "info.circle.fill",
                    title: "FFMI Nedir?",
                    description: "Yağsız Kas Kütlesi İndeksi, vücut kompozisyonunuzu değerlendiren bir ölçüttür"
                )
                
                InfoRowFFMI(
                    icon: "chart.bar.fill",
                    title: "Doğal Sınır",
                    description: "25 üzeri değerler genellikle steroid kullanımını işaret eder"
                )
                
                InfoRowFFMI(
                    icon: "target",
                    title: "Hedefler",
                    description: "Erkekler için 18-22, kadınlar için 14-17 ideal kabul edilir"
                )
                
                InfoRowFFMI(
                    icon: "exclamationmark.triangle.fill",
                    title: "Not",
                    description: "Vücut yağ oranı doğruluğu sonucu önemli ölçüde etkiler"
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

struct InfoRowFFMI: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
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

// MARK: - FFMI Category Enum
enum FFMICategory: CaseIterable {
    case belowAverage
    case average
    case aboveAverage
    case excellent
    case superior
    case suspicious
    
    var description: String {
        switch self {
        case .belowAverage: return "Ortalamanın Altı"
        case .average: return "Ortalama"
        case .aboveAverage: return "Ortalamanın Üstü"
        case .excellent: return "Mükemmel"
        case .superior: return "Üstün"
        case .suspicious: return "Şüpheli"
        }
    }
    
    var range: String {
        switch self {
        case .belowAverage: return "< 16"
        case .average: return "16-17"
        case .aboveAverage: return "18-20"
        case .excellent: return "21-23"
        case .superior: return "24-25"
        case .suspicious: return "> 25"
        }
    }
    
    var interpretation: String {
        switch self {
        case .belowAverage: return "Kas kütlesi geliştirmek için çalışın"
        case .average: return "Normal kas kütlesi"
        case .aboveAverage: return "İyi kas gelişimi"
        case .excellent: return "Çok iyi kas kütlesi"
        case .superior: return "Doğal maksimuma yakın"
        case .suspicious: return "Doğal sınırları aşıyor olabilir"
        }
    }
    
    var color: Color {
        switch self {
        case .belowAverage: return .red
        case .average: return .orange
        case .aboveAverage: return .yellow
        case .excellent: return .green
        case .superior: return .blue
        case .suspicious: return .purple
        }
    }
    
    static func category(for ffmi: Double) -> FFMICategory {
        switch ffmi {
        case ..<16: return .belowAverage
        case 16..<18: return .average
        case 18..<21: return .aboveAverage
        case 21..<24: return .excellent
        case 24...25: return .superior
        default: return .suspicious
        }
    }
}

#Preview {
    NavigationStack {
        FFMICalculatorView()
    }
}
