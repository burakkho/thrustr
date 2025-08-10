import SwiftUI

struct OneRMCalculatorView: View {
    @State private var weight = ""
    @State private var reps = ""
    @State private var selectedFormula: RMFormula = .brzycki
    @State private var calculatedRM: Double?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                OneRMHeaderSection()
                
                // Input Section
                OneRMInputSection(
                    weight: $weight,
                    reps: $reps,
                    selectedFormula: $selectedFormula
                )
                
                // Calculate Button
                Button {
                    calculateOneRM()
                } label: {
                    Text("Hesapla")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!isFormValid)
                .padding(.horizontal)
                
                // Results Section
                if let oneRM = calculatedRM {
                    OneRMResultsSection(oneRM: oneRM, selectedFormula: selectedFormula)
                }
                
                // Formula Info Section
                FormulaInfoSection()
                
                // Tips Section
                OneRMTipsSection()
            }
            .padding()
        }
        .navigationTitle("1RM Hesaplayıcı")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
    
    private var isFormValid: Bool {
        guard let weightValue = Double(weight.replacingOccurrences(of: ",", with: ".")),
              let repsValue = Int(reps) else { return false }
        return weightValue > 0 && repsValue >= 1 && repsValue <= 15
    }
    
    private func calculateOneRM() {
        guard let weightValue = Double(weight.replacingOccurrences(of: ",", with: ".")),
              let repsValue = Int(reps) else { return }
        
        calculatedRM = selectedFormula.calculate(weight: weightValue, reps: repsValue)
    }
}

// MARK: - Header Section
struct OneRMHeaderSection: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("1RM Hesaplayıcı")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Maksimum tek tekrar kaldırabileceğiniz ağırlığı hesaplayın")
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
struct OneRMInputSection: View {
    @Binding var weight: String
    @Binding var reps: String
    @Binding var selectedFormula: RMFormula
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Antrenman Bilgileri")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // Weight Input
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "scalemass.fill")
                            .foregroundColor(.blue)
                        Text("Kaldırdığınız Ağırlık (kg)")
                            .fontWeight(.medium)
                    }
                    
                    TextField("70", text: $weight)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title3)
                }
                
                // Reps Input
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "repeat")
                            .foregroundColor(.green)
                        Text("Tekrar Sayısı (1-15)")
                            .fontWeight(.medium)
                    }
                    
                    TextField("8", text: $reps)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title3)
                }
                
                // Formula Selection
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "function")
                            .foregroundColor(.orange)
                        Text("Hesaplama Formülü")
                            .fontWeight(.medium)
                    }
                    
                    Picker("Formula", selection: $selectedFormula) {
                        ForEach(RMFormula.allCases, id: \.self) { formula in
                            Text(formula.displayName).tag(formula)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
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
struct OneRMResultsSection: View {
    let oneRM: Double
    let selectedFormula: RMFormula
    
    private var percentageTable: [(percentage: Int, weight: Double)] {
        [
            (95, oneRM * 0.95),
            (90, oneRM * 0.90),
            (85, oneRM * 0.85),
            (80, oneRM * 0.80),
            (75, oneRM * 0.75),
            (70, oneRM * 0.70),
            (65, oneRM * 0.65),
            (60, oneRM * 0.60)
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Sonuçlar")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // Main Result
                VStack(spacing: 8) {
                    Text("1RM Tahmininiz")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(String(format: "%.1f", oneRM)) kg")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("\(selectedFormula.displayName) formülü")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Percentage Table
                VStack(alignment: .leading, spacing: 12) {
                    Text("Antrenman Yoğunlukları")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(percentageTable, id: \.percentage) { item in
                            PercentageRow(
                                percentage: item.percentage,
                                weight: item.weight
                            )
                        }
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

struct PercentageRow: View {
    let percentage: Int
    let weight: Double
    
    var body: some View {
        HStack {
            Text("%\(percentage)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)
            
            Spacer()
            
            Text("\(String(format: "%.1f", weight)) kg")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Formula Info Section
struct FormulaInfoSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Formül Bilgileri")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                FormulaInfoRow(
                    formula: .brzycki,
                    description: "En yaygın kullanılan, 1-10 tekrar için ideal"
                )
                
                FormulaInfoRow(
                    formula: .epley,
                    description: "Powerlifting'de tercih edilen, daha muhafazakar"
                )
                
                FormulaInfoRow(
                    formula: .lander,
                    description: "Yüksek tekrarlarda daha doğru sonuçlar"
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

struct FormulaInfoRow: View {
    let formula: RMFormula
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "function")
                .font(.title3)
                .foregroundColor(.orange)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(formula.displayName)
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

// MARK: - Tips Section
struct OneRMTipsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Önemli Notlar")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                TipRow(
                    icon: "exclamationmark.triangle.fill",
                    title: "Güvenlik",
                    description: "Gerçek 1RM denemelerinde mutlaka yardımcı bulundurun"
                )
                
                TipRow(
                    icon: "clock.fill",
                    title: "Doğruluk",
                    description: "Son setinizin failure'a yakın olması daha doğru sonuç verir"
                )
                
                TipRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Kullanım",
                    description: "Antrenman yoğunluğu planlamak için yüzdelik değerleri kullanın"
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

struct TipRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.red)
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

// MARK: - 1RM Formula Enum
enum RMFormula: String, CaseIterable {
    case brzycki = "brzycki"
    case epley = "epley"
    case lander = "lander"
    
    var displayName: String {
        switch self {
        case .brzycki: return "Brzycki"
        case .epley: return "Epley"
        case .lander: return "Lander"
        }
    }
    
    func calculate(weight: Double, reps: Int) -> Double {
        switch self {
        case .brzycki:
            // Brzycki: Weight × (36 / (37 - Reps))
            return weight * (36.0 / (37.0 - Double(reps)))
        case .epley:
            // Epley: Weight × (1 + 0.0333 × Reps)
            return weight * (1.0 + 0.0333 * Double(reps))
        case .lander:
            // Lander: Weight × (100 / (101.3 - 2.67123 × Reps))
            return weight * (100.0 / (101.3 - 2.67123 * Double(reps)))
        }
    }
}

#Preview {
    NavigationStack {
        OneRMCalculatorView()
    }
}
