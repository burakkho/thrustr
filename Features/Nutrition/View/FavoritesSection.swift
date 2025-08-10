import SwiftUI
import SwiftData

struct FavoritesSection: View {
    let foods: [Food]
    let onFoodSelected: (Food) -> Void
    
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
            // Favoriler
            if !favoriteFoods.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("Favoriler")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(favoriteFoods) { food in
                                QuickFoodCard(food: food, type: .favorite) {
                                    onFoodSelected(food)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            // Son kullanılanlar
            if !recentFoods.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                        Text("Son Kullanılanlar")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(recentFoods) { food in
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
                        Text("Popüler")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(popularFoods) { food in
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

struct QuickFoodCard: View {
    let food: Food
    let type: QuickFoodType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: food.categoryEnum.icon)
                        .foregroundColor(food.categoryEnum.color)
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
                
                Text("\(Int(food.calories)) kcal")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if type == .popular {
                    Text("\(food.usageCount) kez kullanıldı")
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
