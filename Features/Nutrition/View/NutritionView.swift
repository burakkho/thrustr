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
    // Foods - usageCount desc, then nameTR
    // Precomputed dates moved to file scope (see top of file)
    @Query(
        sort: [
            SortDescriptor(\Food.usageCount, order: .reverse),
            SortDescriptor(\Food.nameTR)
        ]
    ) private var foods: [Food]
    
    // Today entries only
    @Query(
        filter: #Predicate<NutritionEntry> { entry in
            entry.date >= NV_TODAY_START && entry.date < NV_TODAY_END
        },
        sort: \NutritionEntry.date
    ) private var todayEntries: [NutritionEntry]
    
    // Last 7 days entries
    @Query(
        filter: #Predicate<NutritionEntry> { entry in
            entry.date >= NV_7D_START
        },
        sort: \NutritionEntry.date,
        order: .reverse
    ) private var weekEntries: [NutritionEntry]
    @State private var selectedFood: Food?
    @State private var showingMealEntry = false
    @State private var showingFoodSelection = false
    @State private var showingCustomFoodEntry = false
    @State private var forceStartWithScanner = false
    @State private var saveErrorMessage: String? = nil

    init() {}
    
    var body: some View {
        NavigationStack {
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
                        
                        // Boş durumlar
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

                        // Günlük özet
                        DailyNutritionSummary(nutritionEntries: todayEntries)
                        
                        // Daily Goals (sadece veri varsa göster)
                        if !todayEntries.isEmpty {
                            DailyGoalsCard(nutritionEntries: todayEntries)
                        }
                        
                        // Favorites & Recent Foods (sadece food varsa göster)
                        if !foods.isEmpty {
                            FavoritesSection(foods: foods) { food in
                                selectedFood = food
                                showingMealEntry = true
                            }
                        }
                        
                        // Haftalık analytics (sadece veri varsa göster)
                        if !weekEntries.isEmpty {
                            NutritionAnalyticsView(nutritionEntries: weekEntries)
                        }
                        
                        // Alt boşluk (gerekirse)
                        Spacer(minLength: 0)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle(LocalizationKeys.Nutrition.title.localized)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
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

                #if DEBUG
                ToolbarItem(placement: .navigationBarLeading) {
                    if !foods.isEmpty {
                        Button(LocalizationKeys.Nutrition.Test.clear.localized) {
                            clearAllFoods()
                        }
                        .foregroundColor(.red)
                    }
                }
                #endif
            }
        }
        .sheet(isPresented: $showingFoodSelection) {
            FoodSelectionView(foods: foods, onFoodSelected: { food in
                selectedFood = food
                showingFoodSelection = false
                showingMealEntry = true
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
            Food(nameEN: "Chicken Breast", nameTR: "Tavuk Göğsü", calories: 165, protein: 31, carbs: 0, fat: 3.6, category: .meat),
            Food(nameEN: "Brown Rice", nameTR: "Esmer Pirinç", calories: 111, protein: 2.6, carbs: 23, fat: 0.9, category: .grains),
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
