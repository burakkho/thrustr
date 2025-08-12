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
    
    private var filteredFoods: [Food] {
        var filtered = foods
        
        // Kategori filtresi
        if let category = selectedCategory {
            filtered = filtered.filter { $0.categoryEnum == category }
        }
        
        // Arama filtresi (normalize + TR→EN fallback)
        if !debouncedSearchText.isEmpty {
            let q = normalizeForSearch(debouncedSearchText)
            let enFallbackTerms = LanguageSearchMap.translateTurkishToEnglishKeywords(query: debouncedSearchText)
            filtered = filtered.filter { food in
                let nameTR = normalizeForSearch(food.nameTR)
                let nameEN = normalizeForSearch(food.nameEN)
                let brand = normalizeForSearch(food.brand ?? "")
                let display = normalizeForSearch(food.displayName)
                // Primary match: TR/EN/display/brand
                if display.contains(q) || nameTR.contains(q) || nameEN.contains(q) || (!brand.isEmpty && brand.contains(q)) {
                    return true
                }
                // Fallback: TR→EN keyword mapping
                if !enFallbackTerms.isEmpty {
                    for term in enFallbackTerms {
                        let tq = normalizeForSearch(term)
                        if !tq.isEmpty && (nameEN.contains(tq) || display.contains(tq)) { return true }
                    }
                }
                return false
            }
        }
        
        return filtered.sorted { $0.displayName < $1.displayName }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Arama çubuğu
                FoodSearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .onSubmit {
                        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        if let existingIndex = recentSearches.firstIndex(of: trimmed) {
                            recentSearches.remove(at: existingIndex)
                        }
                        recentSearches.insert(trimmed, at: 0)
                        if recentSearches.count > 5 { recentSearches.removeLast(recentSearches.count - 5) }
                    }
                    .onChange(of: searchText) { _, newValue in
                        searchTask?.cancel()
                        searchTask = Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 250_000_000)
                            if Task.isCancelled { return }
                            debouncedSearchText = newValue
                        }
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
                                    debouncedSearchText = term
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
                    .padding(.top, 8)
                }

                // Kategori filtreleri
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
                
                // Yiyecek listesi
                let hasLocalResults = !filteredFoods.isEmpty
                let hasOffResults = !offResults.isEmpty
                if !hasLocalResults && !hasOffResults {
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
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                isLoadingOFF = true
                defer { isLoadingOFF = false }
                let service = OpenFoodFactsService()
                do {
                    let results = try await service.searchProducts(query: query, lc: "tr", limit: 20)
                    // Map to transient Food objects (not yet in DB). Avoid simple duplicates by display name
                    let existingNames = Set(filteredFoods.map { $0.displayName.lowercased() })
                    let foods = results.map { $0.food }.map { f in
                        var nf = f
                        if nf.nameTR.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            nf.nameTR = nf.nameEN
                        }
                        return nf
                    }.filter { !existingNames.contains($0.displayName.lowercased()) }
                    offResults = foods
                } catch {
                    offResults = []
                    offErrorMessage = error.localizedDescription
                }
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

struct FoodSearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(LocalizationKeys.Nutrition.FoodSelection.searchPlaceholder.localized, text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button(LocalizationKeys.Nutrition.FoodSelection.clear.localized) {
                    text = ""
                }
                .foregroundColor(.secondary)
                .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - OFF Integration
extension FoodSelectionView {
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
                try? modelContext.save()
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
            try? modelContext.save()

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
                    ForEach(mergedLocalFoods()) { food in
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
                    ForEach(offResults) { food in
                        FoodRowView(food: food) {
                            if food.nameTR.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                food.nameTR = food.nameEN
                            }
                            modelContext.insert(food)
                            try? modelContext.save()
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
}

// MARK: - Search normalization & language mapping
extension FoodSelectionView {
    fileprivate func mergedLocalFoods() -> [Food] {
        // Merge aliasMatches into filteredFoods (unique by id)
        var map: [UUID: Food] = [:]
        for f in filteredFoods { map[f.id] = f }
        for f in aliasMatches { map[f.id] = f }
        return map.values.sorted { $0.displayName < $1.displayName }
    }

    @MainActor
    fileprivate func updateAliasMatches(query: String) async {
        let q = normalizeForSearch(query)
        guard !q.isEmpty else { aliasMatches = []; return }
        let descriptor = FetchDescriptor<FoodAlias>()
        let aliases = (try? modelContext.fetch(descriptor)) ?? []
        let matchedFoods: [Food] = aliases.compactMap { alias in
            let term = normalizeForSearch(alias.term)
            guard !term.isEmpty, term.contains(q) else { return nil }
            return alias.food
        }
        // Remove foods already present in filteredFoods to reduce duplicates visually
        let existingIds = Set(filteredFoods.map { $0.id })
        aliasMatches = matchedFoods.filter { !existingIds.contains($0.id) }
    }
}

fileprivate func normalizeForSearch(_ text: String) -> String {
    let lower = text.lowercased(with: Locale(identifier: "tr_TR"))
    let decomposed = lower.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
    let mapping: [Character: Character] = [
        "ı": "i", "ğ": "g", "ü": "u", "ş": "s", "ö": "o", "ç": "c",
        "İ": "i", "Ğ": "g", "Ü": "u", "Ş": "s", "Ö": "o", "Ç": "c"
    ]
    let replaced = String(decomposed.map { mapping[$0] ?? $0 })
    let collapsed = replaced.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    return collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
}

fileprivate enum LanguageSearchMap {
    private static let map: [(pattern: NSRegularExpression, replacements: [String])] = {
        let dict: [String: [String]] = [
            "tavuk göğsü": ["chicken breast"],
            "tavuk": ["chicken"],
            "göğsü": ["breast"],
            "pirinç": ["rice"],
            "esmer pirinç": ["brown rice"],
            "bulgur": ["bulgur"],
            "yulaf": ["oat", "oats"],
            "ekmek": ["bread"],
            "makarna": ["pasta"],
            "şehriye": ["vermicelli", "noodle"],
            "ton balığı": ["tuna"],
            "somon": ["salmon"],
            "yoğurt": ["yogurt", "yoghurt"],
            "süt": ["milk"],
            "peynir": ["cheese"],
            "kefir": ["kefir"],
            "badem": ["almond", "almonds"],
            "fındık": ["hazelnut", "hazelnuts"],
            "ceviz": ["walnut", "walnuts"],
            "muz": ["banana", "bananas"],
            "çilek": ["strawberry", "strawberries"],
            "domates": ["tomato", "tomatoes"],
            "elma": ["apple", "apples"],
        ]
        return dict.map { key, vals in
            let pattern = try! NSRegularExpression(pattern: "(^|\\s)" + NSRegularExpression.escapedPattern(for: key) + "(\\s|$)", options: [.caseInsensitive])
            return (pattern, vals)
        }
    }()
    
    static func translateTurkishToEnglishKeywords(query: String) -> [String] {
        let q = normalizeForSearch(query)
        var results: Set<String> = []
        for (rx, repls) in map {
            let range = NSRange(location: 0, length: q.utf16.count)
            if rx.firstMatch(in: q, options: [], range: range) != nil {
                repls.forEach { results.insert($0) }
            }
        }
        // Token fallback
        let tokens = q.split(separator: " ").map(String.init)
        for t in tokens {
            switch t {
            case "tavuk": results.insert("chicken")
            case "gogsu", "göğsü": results.insert("breast")
            case "pirinc", "pirinç": results.insert("rice")
            case "ton", "tonbaligi": results.insert("tuna")
            default: break
            }
        }
        return Array(results)
    }
}

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

struct FoodRowView: View {
    let food: Food
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Kategori ikonu (SF Symbol)
                Image(systemName: food.categoryEnum.systemIcon)
                    .foregroundColor(food.categoryEnum.categoryColor)
                    .font(.title3)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(food.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(Int(food.calories)) \(LocalizationKeys.Nutrition.Units.kcal.localized) • P: \(Int(food.protein))\(LocalizationKeys.Nutrition.Units.g.localized) • C: \(Int(food.carbs))\(LocalizationKeys.Nutrition.Units.g.localized) • F: \(Int(food.fat))\(LocalizationKeys.Nutrition.Units.g.localized)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let brand = food.brand {
                        Text(brand)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FoodSelectionView(foods: [
        Food(nameEN: "Chicken Breast", nameTR: "Tavuk Göğsü", calories: 165, protein: 31, carbs: 0, fat: 3.6, category: .meat),
        Food(nameEN: "Brown Rice", nameTR: "Esmer Pirinç", calories: 111, protein: 2.6, carbs: 23, fat: 0.9, category: .grains)
    ]) { _ in }
        .modelContainer(for: [Food.self, NutritionEntry.self], inMemory: true)
}
