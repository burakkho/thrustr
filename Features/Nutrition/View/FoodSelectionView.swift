import SwiftUI
import SwiftData

struct FoodSelectionView: View {
    let foods: [Food]
    let onFoodSelected: (Food) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var debouncedSearchText = ""
    @State private var searchTask: Task<Void, Never>? = nil
    @State private var selectedCategory: FoodCategory? = nil
    @State private var showingCustomFoodEntry = false
    @State private var recentSearches: [String] = []
    
    private var filteredFoods: [Food] {
        var filtered = foods
        
        // Kategori filtresi
        if let category = selectedCategory {
            filtered = filtered.filter { $0.categoryEnum == category }
        }
        
        // Arama filtresi
        if !debouncedSearchText.isEmpty {
            filtered = filtered.filter { food in
                food.displayName.localizedCaseInsensitiveContains(debouncedSearchText) ||
                food.nameEN.localizedCaseInsensitiveContains(debouncedSearchText)
            }
        }
        
        return filtered.sorted { $0.displayName < $1.displayName }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Arama çubuğu
                FoodSearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .onSubmit {
                        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        if let existingIndex = recentSearches.firstIndex(of: trimmed) {
                            recentSearches.remove(at: existingIndex)
                        }
                        recentSearches.insert(trimmed, at: 0)
                        if recentSearches.count > 5 { recentSearches.removeLast(recentSearches.count - 5) }
                    }
                    .onChange(of: searchText) { newValue in
                        searchTask?.cancel()
                        searchTask = Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 250_000_000)
                            if Task.isCancelled { return }
                            debouncedSearchText = newValue
                        }
                    }
                
                // Son aramalar çipleri
                if !recentSearches.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(recentSearches, id: \.self) { term in
                                FoodCategoryChip(
                                    title: term,
                                    isSelected: searchText == term,
                                    color: .gray
                                ) {
                                    searchText = term
                                    debouncedSearchText = term
                                }
                            }
                            Button(LocalizationKeys.Nutrition.FoodSelection.clear.localized) {
                                recentSearches.removeAll()
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 8)
                }

                // Kategori filtreleri
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FoodCategoryChip(
                            title: LocalizationKeys.Nutrition.FoodSelection.all.localized,
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
                        
                        Text(searchText.isEmpty ?
                             LocalizationKeys.Nutrition.FoodSelection.noResults.localized :
                             LocalizationKeys.Nutrition.FoodSelection.noResultsForSearch.localized(with: searchText))
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        if !searchText.isEmpty {
                            Text(LocalizationKeys.Nutrition.FoodSelection.tryDifferentTerms.localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredFoods) { food in
                        FoodRowView(food: food) {
                            onFoodSelected(food)
                            #if canImport(UIKit)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            #endif
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(LocalizationKeys.Nutrition.FoodSelection.title.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationKeys.Nutrition.FoodSelection.cancel.localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationKeys.Nutrition.FoodSelection.addNew.localized) {
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
            
            TextField(LocalizationKeys.Nutrition.FoodSelection.searchPlaceholder.localized, text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button(LocalizationKeys.Nutrition.FoodSelection.clear.localized) {
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
                // Kategori ikonu (SF Symbol)
                Image(systemName: food.categoryEnum.systemIcon)
                    .foregroundColor(food.categoryEnum.categoryColor)
                    .font(.title3)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(food.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(Int(food.calories)) \(LocalizationKeys.Nutrition.Units.kcal.localized) • P: \(Int(food.protein))\(LocalizationKeys.Nutrition.Units.g.localized) • C: \(Int(food.carbs))\(LocalizationKeys.Nutrition.Units.g.localized) • F: \(Int(food.fat))\(LocalizationKeys.Nutrition.Units.g.localized)")
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
