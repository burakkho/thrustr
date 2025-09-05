import SwiftUI
import SwiftData

struct FoodSelectionView: View {
    let foods: [Food]
    let onFoodSelected: (Food) -> Void
    var startWithScanner: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var debouncedSearchText = ""
    @State private var searchTask: Task<Void, Never>? = nil
    @State private var offSearchTask: Task<Void, Never>? = nil
    @State private var selectedCategory: FoodCategory? = nil
    @State private var showingCustomFoodEntry = false
    @State private var showingScanner = false
    @State private var isLoadingOFF = false
    @State private var offErrorMessage: String? = nil
    @State private var offResults: [Food] = []
    @State private var recentSearches: [String] = []
    @State private var toastMessage: String? = nil
    
    // Enhanced search with service integration
    @StateObject private var searchService = FoodSearchService()
    @State private var aliasSearchTask: Task<Void, Never>? = nil
    
    // Enhanced search results via FoodSearchService
    private var filteredFoods: [Food] {
        return searchService.searchResults
    }
    
    private var aliasMatches: [Food] {
        return searchService.aliasResults
    }
    
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
                        showingScanner = true
                    } label: {
                        Image(systemName: "barcode.viewfinder")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    
                    Button(NutritionKeys.FoodSelection.addNew.localized) {
                        showingCustomFoodEntry = true
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
                    searchText: $searchText,
                    recentSearches: $recentSearches
                )
                .padding(.horizontal)
                .padding(.top, 8)
                .onChange(of: searchText) { _, newValue in
                    searchTask?.cancel()
                    searchTask = Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 250_000_000)
                        if Task.isCancelled { return }
                        debouncedSearchText = newValue
                        
                        // Trigger enhanced search via service
                        searchService.search(
                            query: newValue,
                            foods: foods,
                            selectedCategory: selectedCategory,
                            modelContext: modelContext
                        )
                    }
                }
                .onChange(of: selectedCategory) { _, _ in
                    // Re-trigger search when category changes
                    if !searchText.isEmpty {
                        searchService.search(
                            query: searchText,
                            foods: foods,
                            selectedCategory: selectedCategory,
                            modelContext: modelContext
                        )
                    }
                }
                
                // Kategori filtreleri
                FoodCategoryFilter(selectedCategory: $selectedCategory)
                
                // Progressive food list - enhanced with alias support
                let hasLocalResults = !filteredFoods.isEmpty
                let hasAliasResults = !aliasMatches.isEmpty
                let hasOffResults = !offResults.isEmpty
                let isSearching = !debouncedSearchText.isEmpty
                let hasAnyResults = hasLocalResults || hasAliasResults || hasOffResults
                let shouldShowLoading = (isLoadingOFF || searchService.isSearching) && !hasAnyResults
                
                if !hasAnyResults && !isSearching {
                    // Empty state when not searching
                    FoodSelectionEmptyStateView(
                        searchText: searchText,
                        onAddNew: { showingCustomFoodEntry = true }
                    )
                } else if !hasAnyResults && isSearching && !shouldShowLoading {
                    // No results for search
                    FoodSelectionEmptyStateView(
                        searchText: searchText,
                        onAddNew: { showingCustomFoodEntry = true }
                    )
                } else {
                    // Progressive results - show what we have
                    List {
                        // Enhanced local results (immediate)
                        if hasLocalResults {
                            Section(header: Text(NutritionKeys.Search.localResults.localized)) {
                                ForEach(filteredFoods, id: \.id) { food in
                                    FoodRowView(food: food) {
                                        onFoodSelected(food)
                                        HapticManager.shared.impact(.light)
                                    }
                                }
                            }
                        }
                        
                        // Alias-enhanced results (via FoodSearchService)
                        if !aliasMatches.isEmpty {
                            Section(header: Text(NutritionKeys.Search.aliasResults.localized)) {
                                ForEach(aliasMatches, id: \.id) { food in
                                    FoodRowView(food: food, showAliasIndicator: true) {
                                        onFoodSelected(food)
                                        HapticManager.shared.impact(.light)
                                    }
                                }
                            }
                        }
                        
                        // Show OFF results as they load
                        if hasOffResults {
                            Section(header: Text("nutrition.openfoodfacts_section".localized)) {
                                ForEach(offResults, id: \.id) { food in
                                    FoodRowView(food: food) {
                                        handleOFFResultSelection(food)
                                    }
                                }
                            }
                        }
                        
                        // Show loading skeleton while OFF search is in progress
                        if isLoadingOFF && isSearching {
                            Section(header: Text("nutrition.openfoodfacts_section".localized)) {
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
            if isLoadingOFF {
                LoadingOverlay()
            }
        }
        .alert(CommonKeys.Onboarding.Common.error.localized, isPresented: .constant(offErrorMessage != nil)) {
            Button(CommonKeys.Onboarding.Common.ok.localized) { offErrorMessage = nil }
        } message: {
            Text(offErrorMessage ?? "")
        }
        .onChange(of: debouncedSearchText) { _, newValue in
            offSearchTask?.cancel()
            let query = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !query.isEmpty else { 
                offResults = []
                searchService.clearSearch()
                return 
            }
            
            offSearchTask = Task { @MainActor in
                await performOFFSearch(query: query)
            }
        }
        .sheet(isPresented: $showingCustomFoodEntry) {
            CustomFoodEntryView(onFoodCreated: { newFood in
                showingCustomFoodEntry = false
                onFoodSelected(newFood)
            }, prefillBarcode: debouncedSearchText.isEmpty ? nil : debouncedSearchText)
        }
        .sheet(isPresented: $showingScanner) {
            BarcodeScanView { code in
                Task { await handleScannedBarcode(code) }
            }
            .ignoresSafeArea()
        }
        .background(ToastPresenter(message: $toastMessage, icon: "checkmark.circle.fill", type: .success) { EmptyView() })
        .onAppear {
            if startWithScanner && !showingScanner {
                showingScanner = true
            }
        }
        .onDisappear {
            // Performance optimization - cancel ongoing tasks to prevent memory leaks
            searchTask?.cancel()
            offSearchTask?.cancel()
            searchService.clearSearch()
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
                Text("nutrition.loading_product".localized)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(16)
            .background(Color.black.opacity(0.6))
            .cornerRadius(12)
        }
    }
}

// MARK: - OFF Integration
extension FoodSelectionView {
    @MainActor
    private func performOFFSearch(query: String) async {
        isLoadingOFF = true
        defer { isLoadingOFF = false }
        
        let service = OpenFoodFactsService()
        do {
            let results = try await service.searchProducts(query: query, lc: "tr", limit: 20)
            // Map to transient Food objects (not yet in DB). Avoid simple duplicates by display/name/brand/barcode
            let existingNames = Set(filteredFoods.map { $0.displayName.lowercased() })
            let mapped: [Food] = results.map { $0.food }.map { f in
                let nf = f
                if nf.nameTR.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    nf.nameTR = nf.nameEN
                }
                return nf
            }.filter { !existingNames.contains($0.displayName.lowercased()) }

            var seen: Set<String> = []
            let unique = mapped.filter { food in
                let key = "\(food.barcode?.lowercased() ?? "")|\(SearchUtilities.normalizeForSearch(food.nameEN))|\(SearchUtilities.normalizeForSearch(food.brand ?? ""))"
                if seen.contains(key) { return false }
                seen.insert(key)
                return true
            }
            offResults = unique
        } catch {
            offResults = []
            if let offError = error as? OpenFoodFactsError {
                switch offError {
                case .rateLimited:
                    offErrorMessage = NutritionKeys.Scan.rateLimited.localized
                case .networkUnavailable:
                    offErrorMessage = NutritionKeys.Scan.networkError.localized
                case .productNotFound:
                    offErrorMessage = OpenFoodFactsError.productNotFound.localizedDescription
                default:
                    offErrorMessage = offError.localizedDescription
                }
            } else {
                offErrorMessage = error.localizedDescription
            }
        }
    }
    
    @MainActor
    private func handleScannedBarcode(_ code: String) async {
        guard let normalized = BarcodeValidator.normalizeAndValidate(code) else {
            offErrorMessage = NutritionKeys.Scan.invalidBarcode.localized
            return
        }
        isLoadingOFF = true
        defer { isLoadingOFF = false }

        let service = OpenFoodFactsService()
        do {
            // Check existing by barcode
            if let existing = try? fetchFood(byBarcode: normalized) {
                HapticManager.shared.notification(.success)
                toastMessage = NutritionKeys.Scan.existing.localized
                onFoodSelected(existing)
                showingScanner = false
                return
            }

            // Cache lookup (LRU) before network
            if let cached = await BarcodeCache.shared.get(barcode: normalized) {
                let food = cached.toFood()
                modelContext.insert(food)
                do { try modelContext.save() } catch {
                    offErrorMessage = error.localizedDescription
                    return
                }
                HapticManager.shared.notification(.success)
                toastMessage = NutritionKeys.Scan.cached.localized
                onFoodSelected(food)
                showingScanner = false
                return
            }

            let result = try await service.fetchProduct(barcode: normalized, modelContext: modelContext)
            // Persist new food; ensure TR name is present for TR searches
            if result.food.nameTR.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                result.food.nameTR = result.food.nameEN
            }
            modelContext.insert(result.food)
            do { try modelContext.save() } catch {
                offErrorMessage = error.localizedDescription
                return
            }

            // Update cache
            let dto = CachedFoodDTO(barcode: normalized, from: result.food)
            await BarcodeCache.shared.set(dto)

            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
            toastMessage = NutritionKeys.Scan.scanned.localized
            onFoodSelected(result.food)
            showingScanner = false
        } catch {
            HapticManager.shared.notification(.error)
            if let offError = error as? OpenFoodFactsError {
                offErrorMessage = offError.localizedDescription
                // Product not found -> offer manual creation flow
                if offError == .productNotFound {
                    showingScanner = false
                    // Show custom food entry prefilled with barcode
                    showingCustomFoodEntry = true
                    toastMessage = NutritionKeys.Scan.notFound.localized
                } else if offError == .rateLimited {
                    toastMessage = NutritionKeys.Scan.rateLimited.localized
                }
            } else {
                offErrorMessage = error.localizedDescription
                toastMessage = NutritionKeys.Scan.networkError.localized
            }
        }
    }

    private func handleOFFResultSelection(_ food: Food) {
        // Prevent duplicates by barcode if exists
        if let code = food.barcode {
            do {
                if let existing = try fetchFood(byBarcode: code) {
                    #if canImport(UIKit)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    #endif
                    toastMessage = NutritionKeys.Scan.existing.localized
                    onFoodSelected(existing)
                    return
                }
            } catch {
                offErrorMessage = error.localizedDescription
            }
        }

        if food.nameTR.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            food.nameTR = food.nameEN
        }
        modelContext.insert(food)
        do { try modelContext.save() } catch {
            offErrorMessage = error.localizedDescription
            return
        }
        HapticManager.shared.notification(.success)
        toastMessage = NutritionKeys.Scan.scanned.localized
        onFoodSelected(food)
    }

    private func fetchFood(byBarcode code: String) throws -> Food? {
        let descriptor = FetchDescriptor<Food>(
            predicate: #Predicate { $0.barcode == code }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    // MARK: - Service Integration Helpers
    
    private func triggerInitialSearch() {
        guard !searchText.isEmpty else { return }
        searchService.search(
            query: searchText,
            foods: foods,
            selectedCategory: selectedCategory,
            modelContext: modelContext
        )
    }
}

#Preview {
    FoodSelectionView(foods: [
        Food(nameEN: "Chicken Breast", nameTR: "Tavuk Göğsü", calories: 165, protein: 31, carbs: 0, fat: 3.6, category: .meat),
        Food(nameEN: "Brown Rice", nameTR: "Esmer Pirinç", calories: 111, protein: 2.6, carbs: 23, fat: 0.9, category: .grains)
    ]) { _ in }
        .modelContainer(for: [Food.self, NutritionEntry.self], inMemory: true)
}
