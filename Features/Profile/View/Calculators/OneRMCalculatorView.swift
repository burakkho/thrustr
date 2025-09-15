import SwiftUI
import Foundation

struct OneRMCalculatorView: View {
    @Environment(UnitSettings.self) var unitSettings
    @State private var viewModel = OneRMCalculatorViewModel()

    let onCalculated: ((Double) -> Void)?

    init(onCalculated: ((Double) -> Void)? = nil) {
        self.onCalculated = onCalculated
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                OneRMHeaderSection()

                // Input Section
                OneRMInputSection(
                    unitSystem: unitSettings.unitSystem,
                    weight: $viewModel.weight,
                    reps: $viewModel.reps,
                    selectedFormula: $viewModel.selectedFormula
                )

                // Calculate Button
                Button {
                    viewModel.calculateOneRM()

                    // Handle callback for OneRMSetupView
                    if let result = viewModel.getCurrentResultValue() {
                        onCalculated?(result)
                    }
                } label: {
                    HStack {
                        if viewModel.isCalculating {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(ProfileKeys.OneRMCalculator.calculate.localized)
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isFormValid ? Color.blue : Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!viewModel.isFormValid || viewModel.isCalculating)
                .padding(.horizontal)

                // Results Section
                if let result = viewModel.calculatedRM {
                    OneRMResultsSection(result: result, unitSystem: unitSettings.unitSystem)
                }

                if let errorMessage = viewModel.errorMessage {
                    ErrorMessageSection(message: errorMessage)
                }

                // Formula Info Section
                FormulaInfoSection()

                // Tips Section
                OneRMTipsSection()
            }
            .padding()
        }
        .navigationTitle(ProfileKeys.OneRMCalculator.title.localized)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            // Update ViewModel's unit settings reference with modern NVVM pattern
            viewModel.updateUnitSettings(unitSettings)
        }
        .onChange(of: unitSettings.unitSystem) { _, _ in
            viewModel.updateUnitSettings(unitSettings)
        }
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
                Text(ProfileKeys.OneRMCalculator.title.localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(ProfileKeys.OneRMCalculator.subtitle.localized)
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
    let unitSystem: UnitSystem
    @Binding var weight: String
    @Binding var reps: String
    @Binding var selectedFormula: RMFormula
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(ProfileKeys.OneRMCalculator.trainingInfo.localized)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // Weight Input
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "scalemass.fill")
                            .foregroundColor(.blue)
                        Text(ProfileKeys.OneRMCalculator.weightLifted.localized)
                            .fontWeight(.medium)
                    }
                    
                    TextField(unitSystem == .metric ? "70" : "155", text: $weight)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title3)
                }
                
                // Reps Input
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "repeat")
                            .foregroundColor(.green)
                        Text(ProfileKeys.OneRMCalculator.repCount.localized)
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
                        Text(ProfileKeys.OneRMCalculator.calculationFormula.localized)
                            .fontWeight(.medium)
                    }
                    
                    Picker("Formula", selection: $selectedFormula) {
                        ForEach(RMFormula.allCases.filter { ![.custom, .repetitionBased].contains($0) }, id: \.self) { formula in
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
    let result: OneRMResult
    let unitSystem: UnitSystem

    private var percentageTable: [(percentage: Int, weight: Double)] {
        result.trainingPercentages
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(ProfileKeys.OneRMCalculator.results.localized)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // Main Result
                VStack(spacing: 8) {
                    Text(ProfileKeys.OneRMCalculator.oneRMValue.localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(result.formattedValue)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)

                    Text("\(result.formula.displayName) formülü")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Percentage Table
                VStack(alignment: .leading, spacing: 12) {
                    Text(ProfileKeys.OneRMCalculator.percentageTable.localized)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(percentageTable, id: \.percentage) { item in
                            PercentageRow(
                                percentage: item.percentage,
                                weight: item.weight,
                                unitSystem: unitSystem
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
    let unitSystem: UnitSystem
    
    var body: some View {
        HStack {
            Text("%\(percentage)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)
            
            Spacer()
            
            Text(UnitsFormatter.formatWeight(kg: weight, system: unitSystem))
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
            Text("formula_info.title".localized)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                FormulaInfoRow(
                    formula: .brzycki,
                    description: "formula_info.brzycki_desc".localized
                )
                
                FormulaInfoRow(
                    formula: .epley,
                    description: "formula_info.epley_desc".localized
                )
                
                FormulaInfoRow(
                    formula: .lander,
                    description: "formula_info.lander_desc".localized
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
            Text(ProfileKeys.OneRMCalculator.about.localized)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                TipRow(
                    icon: "exclamationmark.triangle.fill",
                    title: ProfileKeys.OneRMCalculator.safety.localized,
                    description: ProfileKeys.OneRMCalculator.safetyDesc.localized
                )
                
                TipRow(
                    icon: "clock.fill",
                    title: ProfileKeys.OneRMCalculator.accuracy.localized,
                    description: ProfileKeys.OneRMCalculator.accuracyDesc.localized
                )
                
                TipRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: ProfileKeys.OneRMCalculator.howToUse.localized,
                    description: ProfileKeys.OneRMCalculator.howToUseDesc.localized
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

// MARK: - Error Message Section
struct ErrorMessageSection: View {
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Error")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                Spacer()
            }

            Text(message)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

// Note: RMFormula enum is now located in Core/Models/Tests/StrengthExerciseType.swift

#Preview {
    NavigationStack {
        OneRMCalculatorView()
    }
}
