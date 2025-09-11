import SwiftUI

struct WeightEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(UnitSettings.self) var unitSettings
    
    let user: User
    @State private var weight: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                WeightInputSection(
                    weight: $weight,
                    unitSymbol: unitSettings.unitSystem == .metric ? "kg" : "lb"
                )
                
                Spacer()
                
                SaveButton(
                    isLoading: isLoading,
                    isDisabled: weight.isEmpty,
                    action: saveWeight
                )
            }
            .padding()
            .navigationTitle(DashboardKeys.Actions.logWeight.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(CommonKeys.Onboarding.Common.cancel.localized) {
                        dismiss()
                    }
                }
            }
            .alert(
                CommonKeys.Onboarding.Common.error.localized,
                isPresented: Binding<Bool>(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button(CommonKeys.Onboarding.Common.ok.localized) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    private func saveWeight() {
        guard let weightValue = Double(weight) else { return }
        
        isLoading = true
        
        Task {
            do {
                // Convert to metric if needed
                let weightInKg = unitSettings.unitSystem == .metric ? 
                    weightValue : weightValue * 0.453592 // lb to kg
                
                user.currentWeight = weightInKg
                user.calculateMetrics()
                
                try modelContext.save()
                
                // Log activity for dashboard
                ActivityLoggerService.shared.setModelContext(modelContext)
                ActivityLoggerService.shared.logMeasurementUpdate(
                    measurementType: "Kilo",
                    value: weightInKg,
                    previousValue: user.currentWeight,
                    unit: "kg",
                    user: user
                )
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Weight Input Section
private struct WeightInputSection: View {
    @Binding var weight: String
    let unitSymbol: String
    
    var body: some View {
        VStack(spacing: 16) {
            Text(DashboardKeys.Actions.logWeightDesc.localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack {
                TextField("0.0", text: $weight)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .font(.title2)
                
                Text(unitSymbol)
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Save Button
private struct SaveButton: View {
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Text(CommonKeys.Onboarding.Common.save.localized)
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(isDisabled ? Color.gray : Color.blue)
        .foregroundColor(.white)
        .cornerRadius(12)
        .disabled(isDisabled || isLoading)
    }
}

#Preview {
    let user = User()
    WeightEntrySheet(user: user)
        .environment(UnitSettings.shared)
}