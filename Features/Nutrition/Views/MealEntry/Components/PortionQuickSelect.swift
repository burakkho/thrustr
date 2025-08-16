import SwiftUI

struct PortionQuickSelect: View {
    @Binding var quantity: Double
    var suggested: [Int] = []
    private let defaultQuickAmounts: [Int] = [25, 50, 100, 150, 200, 250]
    @State private var showingCustomInput = false
    @State private var customText = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Portions")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    let amounts = suggested.isEmpty ? defaultQuickAmounts : suggested
                    ForEach(amounts, id: \.self) { amount in
                        Button {
                            quantity = Double(amount)
                            #if canImport(UIKit)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            #endif
                        } label: {
                            VStack(spacing: 4) {
                                Text("\(amount)")
                                    .font(.headline)
                                Text("g")
                                    .font(.caption2)
                            }
                            .foregroundColor(quantity == Double(amount) ? .white : .primary)
                            .frame(width: 60, height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(quantity == Double(amount) ? Color.blue : Color(.systemGray6))
                            )
                        }
                    }
                    
                    Button {
                        showingCustomInput = true
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "plus.circle")
                                .font(.headline)
                            Text("Custom")
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
                                Text("Custom Amount (g)")
                                    .font(.headline)
                                TextField("0", text: $customText)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.numberPad)
                                Spacer()
                            }
                            .padding()
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("Set") {
                                        if let value = Double(customText), value > 0 {
                                            quantity = value
                                            #if canImport(UIKit)
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            #endif
                                            showingCustomInput = false
                                        }
                                    }
                                }
                                ToolbarItem(placement: .cancellationAction) {
                                    Button(LocalizationKeys.Common.cancel.localized) {
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
                Text("\(Int(quantity))g")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .frame(width: 60)
                
                Slider(value: $quantity, in: 1...500, step: 5)
                    .tint(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
}

#Preview {
    PortionQuickSelect(
        quantity: .constant(100),
        suggested: [80, 100, 120, 150, 200]
    )
    .padding()
}
