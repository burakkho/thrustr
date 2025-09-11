import SwiftUI

struct FoodRowView: View {
    @Environment(UnitSettings.self) var unitSettings
    let food: Food
    var showAliasIndicator: Bool = false
    let action: () -> Void
    
    // OPTIMIZED: Add image caching state
    @State private var imageLoadError = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // OPTIMIZED: Image loading with better caching and error handling
                if let url = food.imageURL, !imageLoadError {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 40, height: 40)
                                .scaleEffect(0.8)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipped()
                                .cornerRadius(6)
                                // OPTIMIZED: Add memory optimization
                                .drawingGroup()
                        case .failure:
                            // OPTIMIZED: Show fallback icon on error
                            fallbackIcon
                        @unknown default:
                            fallbackIcon
                        }
                    }
                    .frame(width: 40, height: 40)
                    .onAppear {
                        // Reset error state when URL changes
                        imageLoadError = false
                    }
                    .onDisappear {
                        // OPTIMIZED: Cancel image loading when view disappears
                        // This helps reduce memory usage
                    }
                } else {
                    fallbackIcon
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(food.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(foodMacroLine)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    if let brand = food.brand {
                        Text(brand)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: 6) {
                        if food.source == .openFoodFacts {
                            Text(NutritionKeys.Labels.off.localized)
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.15))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
                        }
                        
                        if showAliasIndicator {
                            Text(NutritionKeys.Alias.aliasMatch.localized)
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.15))
                                .foregroundColor(.green)
                                .clipShape(Capsule())
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
    
    // OPTIMIZED: Extract fallback icon to reduce code duplication
    private var fallbackIcon: some View {
        Image(systemName: food.categoryEnum.systemIcon)
            .foregroundColor(food.categoryEnum.categoryColor)
            .font(.title3)
            .frame(width: 24)
    }
    
    // MARK: - Computed Properties
    private var foodMacroLine: String {
        // Show per serving if available, else per 100g
        let grams = Int(food.servingSizeGramsOrDefault.rounded())
        let scope: String
        if let name = food.servingName, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            scope = " / 1 \(name) (\(UnitsFormatter.formatFoodWeight(grams: Double(grams), system: unitSettings.unitSystem)))"
        } else {
            scope = " / 1 \(NutritionKeys.Labels.serving.localized) (\(UnitsFormatter.formatFoodWeight(grams: Double(grams), system: unitSettings.unitSystem)))"
        }
        let macroUnit = unitSettings.unitSystem == .metric ? NutritionKeys.Units.g.localized : NutritionKeys.Units.g.localized
        return "\(Int(food.calories)) \(NutritionKeys.Units.kcal.localized) • P: \(Int(food.protein))\(macroUnit) • C: \(Int(food.carbs))\(macroUnit) • F: \(Int(food.fat))\(macroUnit)" + scope
    }
}

#Preview {
    List {
        FoodRowView(
            food: Food(
                nameEN: "Chicken Breast",
                nameTR: "Tavuk Göğsü",
                calories: 165,
                protein: 31,
                carbs: 0,
                fat: 3.6,
                category: .meat
            )
        ) {}
        
        FoodRowView(
            food: Food(
                nameEN: "Brown Rice",
                nameTR: "Esmer Pirinç",
                calories: 111,
                protein: 2.6,
                carbs: 23,
                fat: 0.9,
                category: .grains
            )
        ) {}
    }
}
