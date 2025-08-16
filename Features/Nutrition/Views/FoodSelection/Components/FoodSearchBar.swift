import SwiftUI

struct FoodSearchBar: View {
    @Binding var searchText: String
    @Binding var recentSearches: [String]
    
    var body: some View {
        VStack(spacing: 8) {
            // Ana arama çubuğu
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField(LocalizationKeys.Nutrition.FoodSelection.searchPlaceholder.localized, text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(LocalizationKeys.Nutrition.FoodSelection.clear.localized) {
                        searchText = ""
                    }
                    .foregroundColor(.secondary)
                    .font(.caption)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .onSubmit {
                let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                if let existingIndex = recentSearches.firstIndex(of: trimmed) {
                    recentSearches.remove(at: existingIndex)
                }
                recentSearches.insert(trimmed, at: 0)
                if recentSearches.count > 5 { recentSearches.removeLast(recentSearches.count - 5) }
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
            }
        }
    }
}

#Preview {
    FoodSearchBar(
        searchText: .constant(""),
        recentSearches: .constant(["tavuk", "pirinç", "yoğurt"])
    )
}
