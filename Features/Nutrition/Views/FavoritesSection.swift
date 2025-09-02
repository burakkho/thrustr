import SwiftUI
import SwiftData

struct FavoritesSection: View {
    @EnvironmentObject private var unitSettings: UnitSettings
    let foods: [Food]
    let onFoodSelected: (Food) -> Void
    
    @State private var selectedList: ListType = .favorites
    
    private var favoriteFoods: [Food] {
        foods.filter { $0.isFavorite }
            .sorted { $0.displayName < $1.displayName }
    }
    
    private var recentFoods: [Food] {
        foods.filter { $0.isRecentlyUsed && !$0.isFavorite }
            .sorted {
                guard let date1 = $0.lastUsed, let date2 = $1.lastUsed else { return false }
                return date1 > date2
            }
            .prefix(5)
            .map { $0 }
    }
    
    private var popularFoods: [Food] {
        foods.filter { $0.isPopular && !$0.isFavorite && !$0.isRecentlyUsed }
            .sorted { $0.usageCount > $1.usageCount }
            .prefix(3)
            .map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Segment kontrol
            Picker("", selection: $selectedList) {
                Text(NutritionKeys.Favorites.favorites.localized).tag(ListType.favorites)
                Text(NutritionKeys.Favorites.recent.localized).tag(ListType.recent)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // İçerik: Favoriler veya Son Kullanılanlar
            if selectedList == .favorites {
                if !favoriteFoods.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                            Text(NutritionKeys.Favorites.favorites.localized)
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(favoriteFoods, id: \.id) { food in
                                    QuickFoodCard(food: food, type: .favorite) {
                                        onFoodSelected(food)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                } else {
                    // Favori boş state
                    VStack(spacing: 8) {
                        Image(systemName: "heart")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text(NutritionKeys.Favorites.emptyFavorites.localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
            
            if selectedList == .recent {
                if !recentFoods.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.blue)
                            Text(NutritionKeys.Favorites.recent.localized)
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(recentFoods, id: \.id) { food in
                                    QuickFoodCard(food: food, type: .recent) {
                                        onFoodSelected(food)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                } else {
                    // Son kullanılan boş state
                    VStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text(NutritionKeys.Favorites.emptyRecent.localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
            
            // Popüler yiyecekler
            if !popularFoods.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text(NutritionKeys.Favorites.popular.localized)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(popularFoods, id: \.id) { food in
                                QuickFoodCard(food: food, type: .popular) {
                                    onFoodSelected(food)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
}

private enum ListType: Hashable {
    case favorites
    case recent
}

struct QuickFoodCard: View {
    @EnvironmentObject private var unitSettings: UnitSettings
    let food: Food
    let type: QuickFoodType
    let action: () -> Void
    
    private var servingLineText: String {
        let grams = Int(food.servingSizeGramsOrDefault.rounded())
        let base = "\(Int(food.calories)) \(NutritionKeys.Units.kcal.localized)"
        let weightDisplay = UnitsFormatter.formatFoodWeight(grams: Double(grams), system: unitSettings.unitSystem)
        if let name = food.servingName, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return base + " / 1 \(name) (\(weightDisplay))"
        }
        return base + " / 1 \(NutritionKeys.Labels.serving.localized) (\(weightDisplay))"
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: food.categoryEnum.systemIcon)
                        .foregroundColor(food.categoryEnum.categoryColor)
                        .font(.caption)
                    
                    Spacer()
                    
                    Image(systemName: type.icon)
                        .foregroundColor(type.color)
                        .font(.caption2)
                }
                
                Text(food.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(servingLineText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if type == .popular {
                    Text(NutritionKeys.Favorites.timesUsed.localized(with: food.usageCount))
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            .padding(12)
            .frame(width: 120, height: 80)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

enum QuickFoodType {
    case favorite, recent, popular
    
    var icon: String {
        switch self {
        case .favorite: return "heart.fill"
        case .recent: return "clock.fill"
        case .popular: return "flame.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .favorite: return .red
        case .recent: return .blue
        case .popular: return .orange
        }
    }
}

#Preview {
    FavoritesSection(foods: [
        Food(nameEN: "Chicken Breast", nameTR: "Tavuk Göğsü", calories: 165, protein: 31, carbs: 0, fat: 3.6, category: .meat)
    ]) { _ in }
        .modelContainer(for: [Food.self, NutritionEntry.self], inMemory: true)
}
