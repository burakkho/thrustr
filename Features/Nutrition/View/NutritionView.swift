import SwiftUI
import SwiftData

struct NutritionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var foods: [Food]
    @Query private var nutritionEntries: [NutritionEntry]
    @State private var selectedFood: Food?
    @State private var showingMealEntry = false
    @State private var showingFoodSelection = false
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Test butonları (geçici)
                        if foods.isEmpty {
                            VStack(spacing: 12) {
                                Button(LocalizationKeys.Nutrition.Test.addTestFood.localized) {
                                    addTestFoods()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding()
                        }
                        
                        // Günlük özet
                        DailyNutritionSummary(nutritionEntries: nutritionEntries)
                        
                        // Daily Goals (sadece veri varsa göster)
                        if !nutritionEntries.isEmpty {
                            DailyGoalsCard(nutritionEntries: nutritionEntries)
                        }
                        
                        // Favorites & Recent Foods (sadece food varsa göster)
                        if !foods.isEmpty {
                            FavoritesSection(foods: foods) { food in
                                selectedFood = food
                                showingMealEntry = true
                            }
                        }
                        
                        // Haftalık analytics (sadece veri varsa göster)
                        if !nutritionEntries.isEmpty {
                            NutritionAnalyticsView(nutritionEntries: nutritionEntries)
                        }
                        
                        // Boşluk floating button için
                        Spacer()
                            .frame(height: 80)
                    }
                    .padding(.top)
                }
                
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showingFoodSelection = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle(LocalizationKeys.Nutrition.title.localized)
            .toolbar {
                if !foods.isEmpty {
                    Button(LocalizationKeys.Nutrition.Test.clear.localized) {
                        clearAllFoods()
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .sheet(isPresented: $showingFoodSelection) {
            FoodSelectionView(foods: foods) { food in
                selectedFood = food
                showingFoodSelection = false
                showingMealEntry = true
            }
        }
        .sheet(isPresented: $showingMealEntry) {
            if let food = selectedFood {
                MealEntryView(food: food) {
                    selectedFood = nil
                    showingMealEntry = false
                }
            }
        }
    }
    
    private func addTestFoods() {
        let testFoods = [
            Food(nameEN: "Chicken Breast", nameTR: "Tavuk Göğsü", calories: 165, protein: 31, carbs: 0, fat: 3.6, category: .meat),
            Food(nameEN: "Brown Rice", nameTR: "Esmer Pirinç", calories: 111, protein: 2.6, carbs: 23, fat: 0.9, category: .grains),
            Food(nameEN: "Banana", nameTR: "Muz", calories: 89, protein: 1.1, carbs: 23, fat: 0.3, category: .fruits)
        ]
        
        for food in testFoods {
            modelContext.insert(food)
        }
    }
    
    private func clearAllFoods() {
        for food in foods {
            modelContext.delete(food)
        }
        for entry in nutritionEntries {
            modelContext.delete(entry)
        }
    }
}

#Preview {
    NutritionView()
        .modelContainer(for: [Food.self, NutritionEntry.self], inMemory: true)
}
