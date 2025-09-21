import SwiftUI
import SwiftData
import Foundation

struct MealEntryView: View {
    let food: Food
    let onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(UnitSettings.self) var unitSettings
    @Environment(HealthKitService.self) var healthKitService
    @State private var viewModel: MealEntryViewModel?

    private var mealTypes: [(String, String)] {
        [
            ("breakfast", NutritionKeys.MealEntry.MealTypes.breakfast.localized),
            ("lunch", NutritionKeys.MealEntry.MealTypes.lunch.localized),
            ("dinner", NutritionKeys.MealEntry.MealTypes.dinner.localized),
            ("snack", NutritionKeys.MealEntry.MealTypes.snack.localized)
        ]
    }

    private var selectedMealTypes: Set<String> {
        return viewModel?.selectedMealTypes ?? []
    }

    private var effectiveGrams: Double {
        return viewModel?.effectiveGrams ?? 0
    }

    private var inputMode: PortionInputMode {
        get { viewModel?.inputMode ?? .grams }
        set { viewModel?.setInputMode(newValue) }
    }

    private var gramsConsumed: Double {
        get { viewModel?.gramsConsumed ?? 100 }
        set { viewModel?.updateGramsConsumed(newValue) }
    }

    private var servingCount: Double {
        get { viewModel?.servingCount ?? 1 }
        set { viewModel?.updateServingCount(newValue) }
    }

    private var saveErrorMessage: String? {
        get { viewModel?.saveErrorMessage }
        set { viewModel?.saveErrorMessage = newValue }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Native iOS Sheet Header
            HStack {
                Button(NutritionKeys.MealEntry.cancel.localized) {
                    onDismiss()
                }
                .font(.body)
                .foregroundColor(.blue)
                
                Spacer()
                
                Text(NutritionKeys.MealEntry.title.localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Invisible button for balance
                Text(NutritionKeys.MealEntry.cancel.localized)
                    .font(.body)
                    .opacity(0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Color(.systemBackground)
                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
            )
            
            // Content
            VStack(spacing: 20) {
                // Food bilgisi
                foodInfoSection
                
                // Porsiyon girişi (gram veya porsiyon)
                portionInputSection
                
                // Öğün seçimi (çoklu seçim)
                mealSelectionSection
                
                // Hesaplanan değerler
                nutritionCalculationSection
                
                Spacer()
                
                // Ekle butonu
                addButton
            }
            .padding()
        }
        .alert(isPresented: errorAlertBinding) {
            Alert(
                title: Text(CommonKeys.Onboarding.Common.error.localized),
                message: Text(viewModel?.saveErrorMessage ?? ""),
                dismissButton: .default(Text(CommonKeys.Onboarding.Common.ok.localized))
            )
        }
        .onAppear {
            if viewModel == nil {
                viewModel = MealEntryViewModel(
                    unitSettings: unitSettings,
                    healthKitService: healthKitService,
                    activityLoggerService: ActivityLoggerService.shared
                )
                viewModel?.setFood(food, modelContext: modelContext)
            }
        }
    }
    
    private var foodInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(food.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Favori butonu
                Button {
                    viewModel?.toggleFoodFavorite()
                } label: {
                    Image(systemName: food.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(food.isFavorite ? .red : .gray)
                        .font(.title3)
                }
            }
            
            Text(NutritionKeys.MealEntry.per100gCalories.localized(with: Int(food.calories)))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var mealSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NutritionKeys.MealEntry.meal.localized)
                .font(.headline)
            
            HStack(spacing: 8) {
                ForEach(mealTypes, id: \.0) { type, name in
                    let isOn = viewModel?.selectedMealTypes.contains(type) ?? false
                    Button {
                        guard let viewModel = viewModel else { return }
                        var newMealTypes = viewModel.selectedMealTypes
                        if isOn {
                            newMealTypes.remove(type)
                        } else {
                            newMealTypes.insert(type)
                        }
                        viewModel.updateSelectedMealTypes(newMealTypes)
                    } label: {
                        Text(name)
                            .font(.subheadline)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(isOn ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.12))
                            .foregroundColor(isOn ? .accentColor : .primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var nutritionCalculationSection: some View {
        Group {
            if let nutrition = viewModel?.calculatedNutrition {
                VStack(spacing: 4) {
                    Text(NutritionKeys.MealEntry.total.localized(with: Int(nutrition.calories)))
                        .font(.headline)
                    Text(viewModel?.getFormattedNutrition() ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    private var addButton: some View {
        Button(NutritionKeys.MealEntry.addToMeal.localized) { addMealEntry() }
            .buttonStyle(.borderedProminent)
            .disabled(!(viewModel?.isValidEntry ?? false))
    }
    
    private var errorAlertBinding: Binding<Bool> {
        Binding<Bool>(
            get: { viewModel?.saveErrorMessage != nil },
            set: { if !$0 { viewModel?.saveErrorMessage = nil } }
        )
    }
    
    private func addMealEntry() {
        guard let viewModel = viewModel else { return }

        Task {
            let result = await viewModel.saveMealEntry()
            switch result {
            case .success:
                onDismiss()
            case .failure(_):
                // Error is handled by ViewModel's saveErrorMessage
                break
            }
        }
    }

    private func suggestedQuickAmounts() -> [Int] {
        return viewModel?.getSuggestedQuickAmounts() ?? []
    }
}

// MARK: - Portion Input Helpers
extension MealEntryView {
    // Unit-aware binding for TextField display
    private var displayBinding: Binding<Double> {
        return viewModel?.displayBinding ?? Binding.constant(0)
    }
    
    @ViewBuilder
    private var portionInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Mode toggle
            Picker("", selection: Binding(
                get: { inputMode },
                set: { viewModel?.setInputMode($0) }
            )) {
                Text(NutritionKeys.PortionInput.grams.localized).tag(PortionInputMode.grams)
                Text(NutritionKeys.PortionInput.serving.localized).tag(PortionInputMode.serving)
            }
            .pickerStyle(.segmented)
            
            if inputMode == .grams {
                PortionQuickSelect(quantity: Binding(
                    get: { gramsConsumed },
                    set: { viewModel?.updateGramsConsumed($0) }
                ), suggested: suggestedQuickAmounts())
                VStack(alignment: .leading, spacing: 8) {
                    Text(NutritionKeys.MealEntry.portion.localized)
                        .font(.headline)
                    TextField(
                        unitSettings.unitSystem == .metric ? 
                        NutritionKeys.MealEntry.portionGrams.localized :
                        NutritionKeys.MealEntry.portionOunces.localized, 
                        value: displayBinding,
                        format: .number
                    )
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(food.servingDisplayText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack(spacing: 8) {
                        Text("nutrition.portion_input.count".localized)
                        TextField("1", value: Binding(
                            get: { servingCount },
                            set: { viewModel?.updateServingCount($0) }
                        ), format: .number)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                    }
                }
            }
        }
    }
}

#Preview {
    MealEntryView(
        food: Food(
            nameEN: "Chicken Breast",
            nameTR: "Tavuk Göğsü",
            calories: 165,
            protein: 31,
            carbs: 0,
            fat: 3.6,
            category: .meat
        )
    ) {
        // Preview için boş closure
    }
    .modelContainer(for: [Food.self, NutritionEntry.self], inMemory: true)
}
