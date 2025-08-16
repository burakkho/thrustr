import SwiftUI
import SwiftData

// File-scope constants for #Predicate usage
fileprivate let NV_TODAY_START: Date = Calendar.current.startOfDay(for: Date())
fileprivate let NV_TODAY_END: Date = Calendar.current.date(byAdding: .day, value: 1, to: NV_TODAY_START) ?? NV_TODAY_START
fileprivate let NV_7D_START: Date = {
    let date = Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date()
    return Calendar.current.startOfDay(for: date)
}()

struct NutritionView: View {
    @Environment(\.modelContext) private var modelContext
    
    // PERFORMANCE: Single consolidated query for foods
    @Query(
        sort: [
            SortDescriptor(\Food.usageCount, order: .reverse),
            SortDescriptor(\Food.nameTR)
        ]
    ) private var foods: [Food]
    
    // PERFORMANCE: Single query for all nutrition entries (last 7 days)
    @Query(
        filter: #Predicate<NutritionEntry> { entry in
            entry.date >= NV_7D_START
        },
        sort: \NutritionEntry.date,
        order: .reverse
    ) private var allEntries: [NutritionEntry]
    
    // PERFORMANCE: Computed properties for filtered data
    private var todayEntries: [NutritionEntry] {
        allEntries.filter { entry in
            entry.date >= NV_TODAY_START && entry.date < NV_TODAY_END
        }
    }
    
    private var weekEntries: [NutritionEntry] {
        allEntries // Already filtered by query
    }
    // State properties
    @State private var selectedFood: Food?
    @State private var showingMealEntry = false
    @State private var showingFoodSelection = false
    @State private var showingCustomFoodEntry = false
    @State private var forceStartWithScanner = false
    @State private var saveErrorMessage: String? = nil

    init() {}
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Test butonlarÄ± (geÃ§ici)
                        if foods.isEmpty {
                            VStack(spacing: 12) {
                                Button(LocalizationKeys.Nutrition.Test.addTestFood.localized) {
                                    addTestFoods()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding()
                        }
                        
                        // BoÅŸ durumlar
                        if foods.isEmpty && todayEntries.isEmpty && weekEntries.isEmpty {
                            EmptyStateView(
                                systemImage: "fork.knife.circle.fill",
                                title: LocalizationKeys.Nutrition.Empty.firstTitle.localized,
                                message: LocalizationKeys.Nutrition.Empty.firstMessage.localized,
                                primaryTitle: LocalizationKeys.Nutrition.Empty.addMeal.localized,
                                primaryAction: {
                                    forceStartWithScanner = false
                                    showingFoodSelection = true
                                },
                                secondaryTitle: LocalizationKeys.Nutrition.Empty.addCustomFood.localized,
                                secondaryAction: { showingCustomFoodEntry = true }
                            )
                            .padding(.top, 40)
                        }

                        // GÃ¼nlÃ¼k Ã¶zet
                        DailyNutritionSummary(nutritionEntries: todayEntries)
                        
                        // Daily Goals (sadece veri varsa gÃ¶ster)
                        if !todayEntries.isEmpty {
                            DailyGoalsCard(nutritionEntries: todayEntries)
                        }
                        
                        // Favorites & Recent Foods (sadece food varsa gÃ¶ster)
                        if !foods.isEmpty {
                            FavoritesSection(foods: foods) { food in
                                selectedFood = food
                                showingMealEntry = true
                            }
                        }
                        
                        // HaftalÄ±k analytics (sadece veri varsa gÃ¶ster)
                        if !weekEntries.isEmpty {
                            NutritionAnalyticsView(nutritionEntries: weekEntries)
                        }
                        
                        // Alt boÅŸluk (gerekirse)
                        Spacer(minLength: 0)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle(LocalizationKeys.Nutrition.title.localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: {
                            forceStartWithScanner = true
                            showingFoodSelection = true
                        }) {
                            Image(systemName: "barcode.viewfinder")
                                .font(.headline)
                                .accessibilityLabel(LocalizationKeys.Nutrition.scanBarcode.localized)
                        }

                        Button(action: {
                            forceStartWithScanner = false
                            showingFoodSelection = true
                        }) {
                            Image(systemName: "plus")
                                .font(.headline)
                                .accessibilityLabel(LocalizationKeys.Common.add.localized)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingFoodSelection) {
            FoodSelectionView(foods: foods, onFoodSelected: { food in
                selectedFood = food
                showingFoodSelection = false
                // Add a small delay to ensure proper sheet transition
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showingMealEntry = true
                }
            }, startWithScanner: forceStartWithScanner)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingMealEntry) {
            if let food = selectedFood {
                MealEntryView(food: food) {
                    selectedFood = nil
                    showingMealEntry = false
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            } else {
                // Fallback view if selectedFood is nil
                VStack {
                    Text("Hata: Yiyecek seçilmedi")
                        .font(.headline)
                    Button("Kapat") {
                        showingMealEntry = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showingCustomFoodEntry) {
            CustomFoodEntryView { newFood in
                selectedFood = newFood
                showingCustomFoodEntry = false
                showingMealEntry = true
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .alert(isPresented: Binding<Bool>(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Alert(
                title: Text(LocalizationKeys.Common.error.localized),
                message: Text(saveErrorMessage ?? ""),
                dismissButton: .default(Text(LocalizationKeys.Common.ok.localized))
            )
        }
    }
    
    private func addTestFoods() {
        let testFoods = [
            Food(nameEN: "Chicken Breast", nameTR: "Tavuk GÃ¶ÄŸsÃ¼", calories: 165, protein: 31, carbs: 0, fat: 3.6, category: .meat),
            Food(nameEN: "Brown Rice", nameTR: "Esmer PirinÃ§", calories: 111, protein: 2.6, carbs: 23, fat: 0.9, category: .grains),
            Food(nameEN: "Banana", nameTR: "Muz", calories: 89, protein: 1.1, carbs: 23, fat: 0.3, category: .fruits)
        ]
        
        for food in testFoods {
            modelContext.insert(food)
        }
        do { try modelContext.save() } catch { saveErrorMessage = error.localizedDescription }
    }
    
    private func clearAllFoods() {
        for food in foods {
            modelContext.delete(food)
        }
        for entry in todayEntries {
            modelContext.delete(entry)
        }
        do { try modelContext.save() } catch { saveErrorMessage = error.localizedDescription }
    }
}

#Preview {
    NutritionView()
        .modelContainer(for: [Food.self, NutritionEntry.self], inMemory: true)
}
