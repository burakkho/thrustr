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
    @State private var aliasMatches: [Food] = []
    @State private var aliasSearchTask: Task<Void, Never>? = nil
    
    // OPTIMIZED: Improved filtering with better performance
    private var filteredFoods: [Food] {
        var filtered = foods
        
        // Kategori filtresi - OPTIMIZED: Early return if no category filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.categoryEnum == category }
        }
        
        // Arama filtresi - OPTIMIZED: Only filter if search text exists
        if !debouncedSearchText.isEmpty {
            let q = SearchUtilities.normalizeForSearch(debouncedSearchText)
            let enFallbackTerms = LanguageSearchMap.translateTurkishToEnglishKeywords(query: debouncedSearchText)
            
            // OPTIMIZED: Use more efficient filtering
            filtered = filtered.filter { food in
                // OPTIMIZED: Pre-compute normalized strings
                let nameTR = SearchUtilities.normalizeForSearch(food.nameTR)
                let nameEN = SearchUtilities.normalizeForSearch(food.nameEN)
                let brand = SearchUtilities.normalizeForSearch(food.brand ?? "")
                let display = SearchUtilities.normalizeForSearch(food.displayName)
                
                // Primary match: TR/EN/display/brand
                if display.contains(q) || nameTR.contains(q) || nameEN.contains(q) || (!brand.isEmpty && brand.contains(q)) {
                    return true
                }
                
                // Fallback: TR→EN keyword mapping - OPTIMIZED: Only if terms exist
                if !enFallbackTerms.isEmpty {
                    for term in enFallbackTerms {
                        let tq = SearchUtilities.normalizeForSearch(term)
                        if !tq.isEmpty && (nameEN.contains(tq) || display.contains(tq)) { 
                            return true 
                        }
                    }
                }
                return false
            }
        }
        
        // OPTIMIZED: Sort only if needed and limit results for better performance
        let sorted = filtered.sorted { $0.displayName < $1.displayName }
        
        // OPTIMIZED: Limit results to prevent UI lag with large datasets
        return Array(sorted.prefix(100))
    }
    
    var body: some View {
        NavigationStack {
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
                    }
                }
                
                // Kategori filtreleri
                FoodCategoryFilter(selectedCategory: $selectedCategory)
                
                // Yiyecek listesi
                let hasLocalResults = !filteredFoods.isEmpty
                let hasOffResults = !offResults.isEmpty
                if !hasLocalResults && !hasOffResults {
                    FoodSelectionEmptyStateView(
                        searchText: searchText,
                        onAddNew: { showingCustomFoodEntry = true }
                    )
                } else {
                    resultsList(hasLocalResults: hasLocalResults, hasOffResults: hasOffResults)
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
                    HStack(spacing: 12) {
                        Button {
                            showingScanner = true
                        } label: {
                            Image(systemName: "barcode.viewfinder")
                                .font(.title3)
                        }
                        
                        Button(LocalizationKeys.Nutrition.FoodSelection.addNew.localized) {
                            showingCustomFoodEntry = true
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .overlay(alignment: .center) {
            if isLoadingOFF {
                LoadingOverlay()
            }
        }
        .alert(LocalizationKeys.Common.error.localized, isPresented: .constant(offErrorMessage != nil)) {
            Button(LocalizationKeys.Common.ok.localized) { offErrorMessage = nil }
        } message: {
            Text(offErrorMessage ?? "")
        }
        .onChange(of: debouncedSearchText) { _, newValue in
            offSearchTask?.cancel()
            aliasSearchTask?.cancel()
            let query = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !query.isEmpty else { offResults = []; aliasMatches = []; return }
            
            offSearchTask = Task { @MainActor in
                await performOFFSearch(query: query)
            }
            
            aliasSearchTask = Task { @MainActor in
                await updateAliasMatches(query: query)
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
        .background(ToastPresenter(message: $toastMessage, icon: "checkmark.circle.fill") { EmptyView() })
        .onAppear {
            if startWithScanner && !showingScanner {
                showingScanner = true
            }
        }
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
                 LocalizationKeys.Nutrition.FoodSelection.noResults.localized :
                 LocalizationKeys.Nutrition.FoodSelection.noResultsForSearch.localized(with: searchText))
                .font(.headline)
                .foregroundColor(.gray)
            
            if !searchText.isEmpty {
                Text(LocalizationKeys.Nutrition.FoodSelection.tryDifferentTerms.localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button(LocalizationKeys.Nutrition.FoodSelection.addNew.localized) {
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
                Text("Ürün getiriliyor…")
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
                    offErrorMessage = LocalizationKeys.Nutrition.Scan.rateLimited.localized
                case .networkUnavailable:
                    offErrorMessage = LocalizationKeys.Nutrition.Scan.networkError.localized
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
            offErrorMessage = LocalizationKeys.Common.error.localized + ": Geçersiz barkod"
            return
        }
        isLoadingOFF = true
        defer { isLoadingOFF = false }

        let service = OpenFoodFactsService()
        do {
            // Check existing by barcode
            if let existing = try? fetchFood(byBarcode: normalized) {
                #if canImport(UIKit)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                #endif
                toastMessage = LocalizationKeys.Nutrition.Scan.existing.localized
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
                #if canImport(UIKit)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                #endif
                toastMessage = LocalizationKeys.Nutrition.Scan.cached.localized
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
            toastMessage = LocalizationKeys.Nutrition.Scan.scanned.localized
            onFoodSelected(result.food)
            showingScanner = false
        } catch {
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            #endif
            if let offError = error as? OpenFoodFactsError {
                offErrorMessage = offError.localizedDescription
                // Product not found -> offer manual creation flow
                if offError == .productNotFound {
                    showingScanner = false
                    // Show custom food entry prefilled with barcode
                    showingCustomFoodEntry = true
                    toastMessage = LocalizationKeys.Nutrition.Scan.notFound.localized
                } else if offError == .rateLimited {
                    toastMessage = LocalizationKeys.Nutrition.Scan.rateLimited.localized
                }
            } else {
                offErrorMessage = error.localizedDescription
                toastMessage = LocalizationKeys.Nutrition.Scan.networkError.localized
            }
        }
    }

    @ViewBuilder
    private func resultsList(hasLocalResults: Bool, hasOffResults: Bool) -> some View {
        List {
            if hasLocalResults {
                Section(header: Text(LocalizationKeys.Nutrition.FoodSelection.localResults.localized)) {
                    ForEach(mergedLocalFoods(), id: \.id) { food in
                        FoodRowView(food: food) {
                            onFoodSelected(food)
                            #if canImport(UIKit)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            #endif
                        }
                    }
                }
            }
            if hasOffResults {
                Section(header: Text("OpenFoodFacts")) {
                    ForEach(offResults, id: \.id) { food in
                        FoodRowView(food: food) {
                            // Prevent duplicates by barcode if exists
                            if let code = food.barcode {
                                do {
                                    if let existing = try fetchFood(byBarcode: code) {
                                        #if canImport(UIKit)
                                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                                        #endif
                                        toastMessage = LocalizationKeys.Nutrition.Scan.existing.localized
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
                            #if canImport(UIKit)
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            #endif
                            toastMessage = LocalizationKeys.Nutrition.Scan.scanned.localized
                            onFoodSelected(food)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private func fetchFood(byBarcode code: String) throws -> Food? {
        let descriptor = FetchDescriptor<Food>(
            predicate: #Predicate { $0.barcode == code }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    private func mergedLocalFoods() -> [Food] {
        // Merge aliasMatches into filteredFoods (unique by id)
        var map: [UUID: Food] = [:]
        for f in filteredFoods { map[f.id] = f }
        for f in aliasMatches { map[f.id] = f }
        return map.values.sorted { $0.displayName < $1.displayName }
    }

    @MainActor
    private func updateAliasMatches(query: String) async {
        let q = SearchUtilities.normalizeForSearch(query)
        guard !q.isEmpty else { aliasMatches = []; return }
        let descriptor = FetchDescriptor<FoodAlias>()
        let aliases = (try? modelContext.fetch(descriptor)) ?? []
        let matchedFoods: [Food] = aliases.compactMap { alias in
            let term = SearchUtilities.normalizeForSearch(alias.term)
            guard !term.isEmpty, term.contains(q) else { return nil }
            return alias.food
        }
        // Remove foods already present in filteredFoods to reduce duplicates visually
        let existingIds = Set(filteredFoods.map { $0.id })
        aliasMatches = matchedFoods.filter { !existingIds.contains($0.id) }
    }
}

#Preview {
    FoodSelectionView(foods: [
        Food(nameEN: "Chicken Breast", nameTR: "Tavuk Göğsü", calories: 165, protein: 31, carbs: 0, fat: 3.6, category: .meat),
        Food(nameEN: "Brown Rice", nameTR: "Esmer Pirinç", calories: 111, protein: 2.6, carbs: 23, fat: 0.9, category: .grains)
    ]) { _ in }
        .modelContainer(for: [Food.self, NutritionEntry.self], inMemory: true)
}
