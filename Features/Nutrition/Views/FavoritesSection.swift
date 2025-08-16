import SwiftUI
import SwiftData

struct FavoritesSection: View {
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
                Text(LocalizationKeys.Nutrition.Favorites.favorites.localized).tag(ListType.favorites)
                Text(LocalizationKeys.Nutrition.Favorites.recent.localized).tag(ListType.recent)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // İçerik: Favoriler veya Son Kullanılanlar
            if selectedList == .favorites, !favoriteFoods.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text(LocalizationKeys.Nutrition.Favorites.favorites.localized)
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
            }
            
            if selectedList == .recent, !recentFoods.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                        Text(LocalizationKeys.Nutrition.Favorites.recent.localized)
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
            }
            
            // Popüler yiyecekler
            if !popularFoods.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text(LocalizationKeys.Nutrition.Favorites.popular.localized)
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
    let food: Food
    let type: QuickFoodType
    let action: () -> Void
    
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
                
                Text(servingLine(for: food))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if type == .popular {
                    Text(LocalizationKeys.Nutrition.Favorites.timesUsed.localized(with: food.usageCount))
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

private func servingLine(for food: Food) -> String {
    let grams = Int(food.servingSizeGramsOrDefault.rounded())
    let base = "\(Int(food.calories)) \(LocalizationKeys.Nutrition.Units.kcal.localized)"
    if let name = food.servingName, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        return base + " / 1 \(name) (\(grams)g)"
    }
    return base + " / 1 porsiyon (\(grams)g)"
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
