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
    @State private var showRealEmptyState = false
    @StateObject private var errorHandler = ErrorHandlingService.shared

    init() {}
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Loading state during initial app launch
                        if foods.isEmpty && todayEntries.isEmpty && weekEntries.isEmpty {
                            // Show loading state for first few seconds, then show empty state
                            VStack(spacing: 16) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(1.2)
                                
                                Text(NutritionKeys.Empty.loadingFoods.localized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                            .onAppear {
                                // After 3 seconds, if still empty, show the real empty state
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                    if foods.isEmpty && todayEntries.isEmpty && weekEntries.isEmpty {
                                        showRealEmptyState = true
                                    }
                                }
                            }
                        }
                        
                        // Test butonları (geçici)
                        if foods.isEmpty && showRealEmptyState {
                            VStack(spacing: 12) {
                                Button(NutritionKeys.Test.addTestFood.localized) {
                                    addTestFoods()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding()
                        }
                        
                        // Boş durumlar - gerçek empty state
                        if foods.isEmpty && todayEntries.isEmpty && weekEntries.isEmpty && showRealEmptyState {
                            EmptyStateView(
                                systemImage: "fork.knife.circle.fill",
                                title: NutritionKeys.Empty.firstTitle.localized,
                                message: NutritionKeys.Empty.firstMessage.localized,
                                primaryTitle: NutritionKeys.Empty.addMeal.localized,
                                primaryAction: {
                                    forceStartWithScanner = false
                                    showingFoodSelection = true
                                },
                                secondaryTitle: NutritionKeys.Empty.addCustomFood.localized,
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
                                // Small delay to ensure state is properly set
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    showingMealEntry = true
                                }
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
            .navigationTitle(NutritionKeys.title.localized)
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
                                .accessibilityLabel(NutritionKeys.scanBarcode.localized)
                        }

                        Button(action: {
                            forceStartWithScanner = false
                            showingFoodSelection = true
                        }) {
                            Image(systemName: "plus")
                                .font(.headline)
                                .accessibilityLabel(CommonKeys.Onboarding.Common.add.localized)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingFoodSelection) {
            FoodSelectionView(foods: foods, onFoodSelected: { food in
                selectedFood = food
                // Don't immediately dismiss - let delay handle it
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingFoodSelection = false  // Dismiss first sheet
                    if selectedFood != nil {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showingMealEntry = true  // Then open second sheet
                        }
                    }
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
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text(NutritionKeys.Errors.noFoodSelected.localized)
                        .font(.headline)
                    Text(NutritionKeys.Errors.noFoodSelectedDesc.localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button(NutritionKeys.Actions.close.localized) {
                        showingMealEntry = false
                    }
                    .buttonStyle(.borderedProminent)
                    Button(NutritionKeys.Actions.tryAgain.localized) {
                        showingMealEntry = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showingFoodSelection = true
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
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
        .toast($errorHandler.toastMessage, type: errorHandler.toastType)
        .alert(isPresented: Binding<Bool>(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Alert(
                title: Text(CommonKeys.Onboarding.Common.error.localized),
                message: Text(saveErrorMessage ?? ""),
                dismissButton: .default(Text(CommonKeys.Onboarding.Common.ok.localized))
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
        do { 
            try modelContext.save() 
            errorHandler.showSuccessToast(NutritionKeys.Test.addedSuccessfully.localized)
        } catch { 
            errorHandler.handle(error, severity: .medium, source: "NutritionView.addTestFoods")
        }
    }
    
    private func clearAllFoods() {
        for food in foods {
            modelContext.delete(food)
        }
        for entry in todayEntries {
            modelContext.delete(entry)
        }
        do { 
            try modelContext.save() 
            errorHandler.showSuccessToast(NutritionKeys.Test.clearedSuccessfully.localized)
        } catch { 
            errorHandler.handle(error, severity: .medium, source: "NutritionView.clearAllFoods")
        }
    }
}

#Preview {
    NutritionView()
        .modelContainer(for: [Food.self, NutritionEntry.self], inMemory: true)
}
