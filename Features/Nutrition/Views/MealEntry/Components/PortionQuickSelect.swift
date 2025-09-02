import SwiftUI

struct PortionQuickSelect: View {
    @EnvironmentObject private var unitSettings: UnitSettings
    @Binding var quantity: Double
    var suggested: [Int] = []
    @State private var showingCustomInput = false
    @State private var customText = ""
    
    // Unit-aware quick amounts
    private var defaultQuickAmounts: [Double] {
        switch unitSettings.unitSystem {
        case .metric:
            return [25, 50, 100, 150, 200, 250] // grams
        case .imperial:
            return [1, 2, 3, 4, 6, 8].map { UnitsConverter.ozToGram($0) } // ounces converted to grams for storage
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NutritionKeys.PortionInput.title.localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    let amounts = suggested.isEmpty ? defaultQuickAmounts : suggested.map(Double.init)
                    ForEach(Array(amounts.enumerated()), id: \.offset) { _, amount in
                        Button {
                            quantity = amount
                            HapticManager.shared.impact(.light)
                        } label: {
                            VStack(spacing: 4) {
                                Text(formatAmountDisplay(amount))
                                    .font(.headline)
                                Text(unitSettings.unitSystem == .metric ? "g" : "oz")
                                    .font(.caption2)
                            }
                            .foregroundColor(quantity == amount ? .white : .primary)
                            .frame(width: 60, height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(quantity == amount ? Color.blue : Color(.systemGray6))
                            )
                        }
                    }
                    
                    Button {
                        showingCustomInput = true
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "plus.circle")
                                .font(.headline)
                            Text(NutritionKeys.PortionInput.custom.localized)
                                .font(.caption2)
                        }
                        .foregroundColor(.blue)
                        .frame(width: 60, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                    }
                    .sheet(isPresented: $showingCustomInput) {
                        NavigationStack {
                            VStack(spacing: 16) {
                                Text(NutritionKeys.PortionInput.customAmount.localized)
                                    .font(.headline)
                                TextField("0", text: $customText)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.numberPad)
                                Spacer()
                            }
                            .padding()
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button(NutritionKeys.PortionInput.set.localized) {
                                        if let value = Double(customText), value > 0 {
                                            // Convert input to grams for storage
                                            let grams = unitSettings.unitSystem == .metric ? value : UnitsConverter.ozToGram(value)
                                            quantity = grams
                                            #if canImport(UIKit)
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            #endif
                                            showingCustomInput = false
                                        }
                                    }
                                }
                                ToolbarItem(placement: .cancellationAction) {
                                    Button(CommonKeys.Onboarding.Common.cancel.localized) {
                                        showingCustomInput = false
                                    }
                                }
                            }
                        }
                        .presentationDetents([.medium])
                    }
                }
                .padding(.horizontal, 2)
            }
            
            HStack {
                Text(UnitsFormatter.formatFoodWeight(grams: quantity, system: unitSettings.unitSystem))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .frame(width: 80)
                
                Slider(value: $quantity, in: 1...500, step: unitSettings.unitSystem == .metric ? 5 : UnitsConverter.ozToGram(0.25))
                    .tint(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
    
    // Helper to format amount display based on unit system
    private func formatAmountDisplay(_ grams: Double) -> String {
        switch unitSettings.unitSystem {
        case .metric:
            return String(format: "%.0f", grams)
        case .imperial:
            let oz = UnitsConverter.gramToOz(grams)
            return String(format: "%.0f", oz)
        }
    }
}

#Preview {
    PortionQuickSelect(
        quantity: .constant(100),
        suggested: [80, 100, 120, 150, 200]
    )
    .padding()
}
