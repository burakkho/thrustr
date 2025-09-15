import SwiftUI
import SwiftData


struct NutritionView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = NutritionViewModel()
    
    // PERFORMANCE: Single consolidated query for foods
    @Query(
        sort: [
            SortDescriptor(\Food.usageCount, order: .reverse),
            SortDescriptor(\Food.nameTR)
        ]
    ) private var foods: [Food]
    
    // PERFORMANCE: Query for all nutrition entries (filtering done in computed properties)
    @Query(
        sort: \NutritionEntry.date,
        order: .reverse
    ) private var allEntries: [NutritionEntry]
    
    // PERFORMANCE: Computed properties using ViewModel for filtering
    private var todayEntries: [NutritionEntry] {
        return viewModel.getTodayEntries(from: allEntries)
    }

    private var weekEntries: [NutritionEntry] {
        return viewModel.getWeekEntries(from: allEntries)
    }

    init() {}
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Loading state during initial app launch - only check foods array
                        if foods.isEmpty {
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
                                // After 3 seconds, if foods still empty, show the real empty state
                                viewModel.triggerEmptyStateCheck()
                            }
                        }
                        
                        
                        // Boş durumlar - gerçek empty state (only check foods, not entries)
                        if foods.isEmpty && viewModel.showRealEmptyState {
                            EmptyStateView(
                                systemImage: "fork.knife.circle.fill",
                                title: NutritionKeys.Empty.firstTitle.localized,
                                message: NutritionKeys.Empty.firstMessage.localized,
                                primaryTitle: NutritionKeys.Empty.addMeal.localized,
                                primaryAction: {
                                    viewModel.showFoodSelection()
                                },
                                secondaryTitle: NutritionKeys.Empty.addCustomFood.localized,
                                secondaryAction: { viewModel.showCustomFoodEntry() }
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
                                viewModel.showMealEntryForm(with: food)
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
                            viewModel.startWithScanner()
                        }) {
                            Image(systemName: "barcode.viewfinder")
                                .font(.headline)
                                .accessibilityLabel(NutritionKeys.scanBarcode.localized)
                        }

                        Button(action: {
                            viewModel.showFoodSelection()
                        }) {
                            Image(systemName: "plus")
                                .font(.headline)
                                .accessibilityLabel(CommonKeys.Onboarding.Common.add.localized)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showingFoodSelection) {
            FoodSelectionView(foods: foods, onFoodSelected: { food in
                viewModel.showMealEntryForm(with: food)
            }, startWithScanner: viewModel.forceStartWithScanner)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showingMealEntry) {
            if let food = viewModel.selectedFood {
                MealEntryView(food: food) {
                    viewModel.dismissAllModals()
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
                        viewModel.dismissAllModals()
                    }
                    .buttonStyle(.borderedProminent)
                    Button(NutritionKeys.Actions.tryAgain.localized) {
                        viewModel.dismissAllModals()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            viewModel.showFoodSelection()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
        .sheet(isPresented: $viewModel.showingCustomFoodEntry) {
            CustomFoodEntryView { newFood in
                viewModel.showMealEntryForm(with: newFood)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .toast($viewModel.errorHandler.toastMessage, type: viewModel.errorHandler.toastType)
        .alert(isPresented: Binding<Bool>(
            get: { viewModel.saveErrorMessage != nil },
            set: { if !$0 { viewModel.clearErrors() } }
        )) {
            Alert(
                title: Text(CommonKeys.Onboarding.Common.error.localized),
                message: Text(viewModel.saveErrorMessage ?? ""),
                dismissButton: .default(Text(CommonKeys.Onboarding.Common.ok.localized))
            )
        }
    }
    
    
}

#Preview {
    NutritionView()
        .modelContainer(for: [Food.self, NutritionEntry.self], inMemory: true)
}
