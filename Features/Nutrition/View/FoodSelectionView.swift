import SwiftUI
import SwiftData

struct FoodSelectionView: View {
    let foods: [Food]
    let onFoodSelected: (Food) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: FoodCategory? = nil
    @State private var showingCustomFoodEntry = false
    
    private var filteredFoods: [Food] {
        var filtered = foods
        
        // Kategori filtresi
        if let category = selectedCategory {
            filtered = filtered.filter { $0.categoryEnum == category }
        }
        
        // Arama filtresi
        if !searchText.isEmpty {
            filtered = filtered.filter { food in
                food.displayName.localizedCaseInsensitiveContains(searchText) ||
                food.nameEN.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered.sorted { $0.displayName < $1.displayName }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Arama çubuğu
                FoodSearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Kategori filtreleri
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FoodCategoryChip(
                            title: "Tümü",
                            isSelected: selectedCategory == nil,
                            color: .gray
                        ) {
                            selectedCategory = nil
                        }
                        
                        ForEach(FoodCategory.allCases, id: \.self) { category in
                            FoodCategoryChip(
                                title: category.displayName,
                                isSelected: selectedCategory == category,
                                color: category.color
                            ) {
                                selectedCategory = selectedCategory == category ? nil : category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
                
                // Yiyecek listesi
                if filteredFoods.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text(searchText.isEmpty ? "Yiyecek bulunamadı" : "'\(searchText)' için sonuç yok")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        if !searchText.isEmpty {
                            Text("Farklı arama terimlerini deneyin")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredFoods) { food in
                        FoodRowView(food: food) {
                            onFoodSelected(food)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Yiyecek Seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Yeni Ekle") {
                        showingCustomFoodEntry = true
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showingCustomFoodEntry) {
            CustomFoodEntryView { newFood in
                showingCustomFoodEntry = false
                onFoodSelected(newFood)
            }
        }
    }
}

struct FoodSearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Yiyecek ara...", text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button("Temizle") {
                    text = ""
                }
                .foregroundColor(.secondary)
                .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct FoodCategoryChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : color.opacity(0.2))
                .cornerRadius(16)
        }
    }
}

struct FoodRowView: View {
    let food: Food
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Kategori ikonu
                Image(systemName: food.categoryEnum.icon)
                    .foregroundColor(food.categoryEnum.color)
                    .font(.title3)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(food.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(Int(food.calories)) kcal • P: \(Int(food.protein))g • C: \(Int(food.carbs))g • F: \(Int(food.fat))g")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let brand = food.brand {
                        Text(brand)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
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
}

#Preview {
    FoodSelectionView(foods: [
        Food(nameEN: "Chicken Breast", nameTR: "Tavuk Göğsü", calories: 165, protein: 31, carbs: 0, fat: 3.6, category: .meat),
        Food(nameEN: "Brown Rice", nameTR: "Esmer Pirinç", calories: 111, protein: 2.6, carbs: 23, fat: 0.9, category: .grains)
    ]) { _ in }
        .modelContainer(for: [Food.self, NutritionEntry.self], inMemory: true)
}
