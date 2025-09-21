import SwiftUI
import SwiftData

struct FoodSelectionView: View {
    let foods: [Food]
    let onFoodSelected: (Food) -> Void
    var startWithScanner: Bool = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: FoodSelectionViewModel?

    // All state management delegated to ViewModel - no computed properties needed
    
    var body: some View {
        VStack(spacing: 0) {
            // Native iOS Sheet Header
            HStack {
                Button(NutritionKeys.FoodSelection.cancel.localized) {
                    dismiss()
                }
                .font(.body)
                .foregroundColor(.blue)
                
                Spacer()
                
                Text(NutritionKeys.FoodSelection.title.localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button {
                        viewModel?.startScanning()
                    } label: {
                        Image(systemName: "barcode.viewfinder")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }

                    Button(NutritionKeys.FoodSelection.addNew.localized) {
                        viewModel?.showCustomFoodEntry()
                    }
                    .font(.body)
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Color(.systemBackground)
                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
            )
            
            // Content
            VStack(spacing: 0) {
                // Arama çubuğu
                FoodSearchBar(
                    searchText: Binding(
                        get: { viewModel?.searchText ?? "" },
                        set: { viewModel?.updateSearchText($0, foods: foods) }
                    ),
                    recentSearches: Binding(
                        get: { viewModel?.recentSearches ?? [] },
                        set: { viewModel?.recentSearches = $0 }
                    )
                )
                .padding(.horizontal)
                .padding(.top, 8)
                .onChange(of: viewModel?.searchText ?? "") { _, newValue in
                    viewModel?.updateSearchText(newValue, foods: foods)
                }

                // Kategori filtreleri
                FoodCategoryFilter(selectedCategory: Binding(
                    get: { viewModel?.selectedCategory },
                    set: { viewModel?.updateSelectedCategory($0, foods: foods) }
                ))
                
                // Progressive food list - enhanced with alias support
                let hasLocalResults = !(viewModel?.filteredFoods.isEmpty ?? true)
                let hasAliasResults = !(viewModel?.aliasMatches.isEmpty ?? true)
                let hasOffResults = !(viewModel?.offResults.isEmpty ?? true)
                let isSearching = !(viewModel?.debouncedSearchText.isEmpty ?? true)
                let hasAnyResults = viewModel?.hasAnyResults ?? false
                let shouldShowLoading = viewModel?.shouldShowLoading ?? false

                if !hasAnyResults && !isSearching {
                    // Empty state when not searching
                    FoodSelectionEmptyStateView(
                        searchText: viewModel?.searchText ?? "",
                        onAddNew: { viewModel?.showCustomFoodEntry() }
                    )
                } else if !hasAnyResults && isSearching && !shouldShowLoading {
                    // No results for search
                    FoodSelectionEmptyStateView(
                        searchText: viewModel?.searchText ?? "",
                        onAddNew: { viewModel?.showCustomFoodEntry() }
                    )
                } else {
                    // Progressive results - show what we have
                    List {
                        // Enhanced local results (immediate)
                        if hasLocalResults {
                            Section(header: Text(NutritionKeys.Search.localResults.localized)) {
                                ForEach(viewModel?.filteredFoods ?? [], id: \.id) { food in
                                    FoodRowView(food: food) {
                                        onFoodSelected(food)
                                        HapticManager.shared.impact(.light)
                                    }
                                }
                            }
                        }

                        // Alias-enhanced results (via FoodSearchService)
                        if hasAliasResults {
                            Section(header: Text(NutritionKeys.Search.aliasResults.localized)) {
                                ForEach(viewModel?.aliasMatches ?? [], id: \.id) { food in
                                    FoodRowView(food: food, showAliasIndicator: true) {
                                        onFoodSelected(food)
                                        HapticManager.shared.impact(.light)
                                    }
                                }
                            }
                        }
                        
                        // Show OFF results as they load
                        if hasOffResults {
                            Section(header: Text(NutritionKeys.OpenFoodFacts.section.localized)) {
                                ForEach(viewModel?.offResults ?? [], id: \.id) { food in
                                    FoodRowView(food: food) {
                                        Task {
                                            await viewModel?.handleOFFResultSelection(food)
                                            onFoodSelected(food)
                                        }
                                    }
                                }
                            }
                        }

                        // Show loading skeleton while OFF search is in progress
                        if (viewModel?.isLoadingOFF ?? false) && isSearching {
                            Section(header: Text(NutritionKeys.OpenFoodFacts.section.localized)) {
                                ForEach(0..<3, id: \.self) { _ in
                                    FoodSkeletonRow()
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }
        }
        .overlay(alignment: .center) {
            if (viewModel?.isLoadingOFF ?? false) {
                LoadingOverlay()
            }
        }
        .alert(CommonKeys.Onboarding.Common.error.localized, isPresented: .constant((viewModel?.offErrorMessage) != nil)) {
            Button(CommonKeys.Onboarding.Common.ok.localized) { viewModel?.offErrorMessage = nil }
        } message: {
            Text(viewModel?.offErrorMessage ?? "")
        }
        .onChange(of: viewModel?.debouncedSearchText ?? "") { _, newValue in
            viewModel?.handleDebouncedSearchChange(newValue)
        }
        .sheet(isPresented: Binding(
            get: { viewModel?.showingCustomFoodEntry ?? false },
            set: { viewModel?.showingCustomFoodEntry = $0 }
        )) {
            CustomFoodEntryView(onFoodCreated: { newFood in
                viewModel?.showingCustomFoodEntry = false
                onFoodSelected(newFood)
            }, prefillBarcode: (viewModel?.debouncedSearchText.isEmpty ?? true) ? nil : viewModel?.debouncedSearchText)
        }
        .sheet(isPresented: Binding(
            get: { viewModel?.showingScanner ?? false },
            set: { viewModel?.showingScanner = $0 }
        )) {
            BarcodeScanView { code in
                Task {
                    await viewModel?.handleScannedBarcode(code)
                    // Handle food selection if needed through callback
                }
            }
            .ignoresSafeArea()
        }
        .background(ToastPresenter(message: Binding(
            get: { viewModel?.toastMessage },
            set: { viewModel?.toastMessage = $0 }
        ), icon: "checkmark.circle.fill", type: .success) { EmptyView() })
        .onAppear {
            if viewModel == nil {
                viewModel = FoodSelectionViewModel()
                viewModel?.setModelContext(modelContext)
            }

            if startWithScanner && !showingScanner {
                viewModel?.startScanning()
            }
        }
        .onDisappear {
            // Performance optimization - cancel ongoing tasks to prevent memory leaks
            viewModel?.clearSearchState()
        }
        .animation(.easeInOut(duration: 0.3), value: isLoadingOFF)
        .animation(.easeInOut(duration: 0.3), value: offResults.count)
    }
}

// MARK: - Supporting Views
private struct FoodSelectionEmptyStateView: View {
    let searchText: String
    let onAddNew: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text(searchText.isEmpty ?
                 NutritionKeys.FoodSelection.noResults.localized :
                 NutritionKeys.FoodSelection.noResultsForSearch.localized(with: searchText))
                .font(.headline)
                .foregroundColor(.gray)
            
            if !searchText.isEmpty {
                Text(NutritionKeys.FoodSelection.tryDifferentTerms.localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button(NutritionKeys.FoodSelection.addNew.localized) {
                onAddNew()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                Text(NutritionKeys.OpenFoodFacts.loadingProduct.localized)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(16)
            .background(Color.black.opacity(0.6))
            .cornerRadius(12)
        }
    }
}


#Preview {
    FoodSelectionView(foods: [
        Food(nameEN: "Chicken Breast", nameTR: "Tavuk Göğsü", calories: 165, protein: 31, carbs: 0, fat: 3.6, category: .meat),
        Food(nameEN: "Brown Rice", nameTR: "Esmer Pirinç", calories: 111, protein: 2.6, carbs: 23, fat: 0.9, category: .grains)
    ]) { _ in }
        .modelContainer(for: [Food.self, NutritionEntry.self], inMemory: true)
}
