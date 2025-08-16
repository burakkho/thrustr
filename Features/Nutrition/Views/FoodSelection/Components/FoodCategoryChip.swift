import SwiftUI

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

struct FoodCategoryFilter: View {
    @Binding var selectedCategory: FoodCategory?
    
    var body: some View {
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
    }
}

#Preview {
    VStack(spacing: 20) {
        FoodCategoryChip(
            title: "Tümü",
            isSelected: true,
            color: .blue
        ) {}
        
        FoodCategoryChip(
            title: "Et",
            isSelected: false,
            color: .red
        ) {}
        
        FoodCategoryFilter(selectedCategory: .constant(nil))
    }
}
