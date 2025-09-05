import Foundation
import SwiftData

@MainActor
final class FoodSearchService: ObservableObject {
    // MARK: - Published Properties
    @Published var isSearching = false
    @Published var searchResults: [Food] = []
    @Published var aliasResults: [Food] = []
    @Published var lastError: Error?
    
    // MARK: - Private Properties
    private var searchTask: Task<Void, Never>?
    private var aliasTask: Task<Void, Never>?
    private let debounceDelay: UInt64 = 250_000_000 // 250ms in nanoseconds
    
    // MARK: - Search Cache for Performance
    private var searchCache: [String: SearchResult] = [:]
    private var cacheTimestamps: [String: Date] = [:]
    private let cacheExpirySeconds: TimeInterval = 300 // 5 minutes
    private let maxCacheSize = 50
    
    // MARK: - Public API
    
    /// Unified search across Food database and FoodAlias system
    /// Returns immediate results from cache if available, otherwise performs async search
    func search(
        query: String,
        foods: [Food],
        selectedCategory: FoodCategory?,
        modelContext: ModelContext
    ) {
        let normalizedQuery = normalizeForSearch(query.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !normalizedQuery.isEmpty else {
            searchResults = []
            aliasResults = []
            return
        }
        
        // Check cache first
        let cacheKey = createCacheKey(query: normalizedQuery, category: selectedCategory)
        if let cached = getCachedResult(for: cacheKey) {
            searchResults = cached.foods
            aliasResults = cached.aliasMatches
            return
        }
        
        // Cancel previous searches
        searchTask?.cancel()
        aliasTask?.cancel()
        
        isSearching = true
        
        // Debounced search
        searchTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: debounceDelay)
                if Task.isCancelled { return }
                
                await performUnifiedSearch(
                    query: normalizedQuery,
                    foods: foods,
                    selectedCategory: selectedCategory,
                    modelContext: modelContext
                )
                isSearching = false
                
                // Cache the results
                let result = SearchResult(foods: searchResults, aliasMatches: aliasResults)
                setCachedResult(result, for: cacheKey)
                
            } catch {
                if !Task.isCancelled {
                    lastError = error
                    isSearching = false
                }
            }
        }
    }
    
    /// Clear all search results and cancel ongoing searches
    func clearSearch() {
        searchTask?.cancel()
        aliasTask?.cancel()
        searchResults = []
        aliasResults = []
        isSearching = false
    }
    
    // MARK: - Private Search Implementation
    
    private func performUnifiedSearch(
        query: String,
        foods: [Food],
        selectedCategory: FoodCategory?,
        modelContext: ModelContext
    ) async {
        // Phase 1: Direct food search (immediate)
        let directResults = searchFoodsDirectly(
            query: query,
            foods: foods,
            selectedCategory: selectedCategory
        )
        
        // Phase 2: Alias-enhanced search (async)
        let aliasMatches = await searchViaAliases(
            query: query,
            selectedCategory: selectedCategory,
            modelContext: modelContext,
            existingFoodIds: Set(directResults.map { $0.id })
        )
        
        // Update results
        searchResults = directResults
        aliasResults = aliasMatches
    }
    
    private func searchFoodsDirectly(
        query: String,
        foods: [Food],
        selectedCategory: FoodCategory?
    ) -> [Food] {
        var filtered = foods
        
        // Category filter first (performance optimization)
        if let category = selectedCategory {
            filtered = filtered.filter { $0.categoryEnum == category }
        }
        
        // Search filter with enhanced matching
        let normalizedQuery = normalizeForSearch(query)
        let englishKeywords = translateTurkishToEnglishKeywords(query: query)
        
        filtered = filtered.filter { food in
            // Pre-normalize for performance
            let nameTR = normalizeForSearch(food.nameTR)
            let nameEN = normalizeForSearch(food.nameEN)
            let brand = normalizeForSearch(food.brand ?? "")
            let display = normalizeForSearch(food.displayName)
            
            // Primary matching
            if display.contains(normalizedQuery) || 
               nameTR.contains(normalizedQuery) || 
               nameEN.contains(normalizedQuery) || 
               (!brand.isEmpty && brand.contains(normalizedQuery)) {
                return true
            }
            
            // Enhanced TR→EN keyword matching
            for keyword in englishKeywords {
                let normalizedKeyword = normalizeForSearch(keyword)
                if !normalizedKeyword.isEmpty && 
                   (nameEN.contains(normalizedKeyword) || display.contains(normalizedKeyword)) {
                    return true
                }
            }
            
            return false
        }
        
        // Sort by relevance and limit results
        return Array(filtered.sorted { $0.displayName < $1.displayName }.prefix(100))
    }
    
    private func searchViaAliases(
        query: String,
        selectedCategory: FoodCategory?,
        modelContext: ModelContext,
        existingFoodIds: Set<UUID>
    ) async -> [Food] {
        let normalizedQuery = normalizeForSearch(query)
        guard !normalizedQuery.isEmpty else { return [] }
        
        // Enhanced alias search with language preference
        let currentLang = LanguageManager.shared.currentLanguage
        
        // Build predicate for alias search  
        var descriptor = FetchDescriptor<FoodAlias>(
            sortBy: [SortDescriptor(\FoodAlias.term)]
        )
        descriptor.fetchLimit = 200 // Performance limit
        
        let aliases = (try? modelContext.fetch(descriptor)) ?? []
        
        // Filter aliases by search term and language preference
        let matchingAliases = aliases.filter { alias in
            let normalizedTerm = normalizeForSearch(alias.term)
            
            // Prefer current language matches, but include all matches
            let isCurrentLang = alias.language == currentLang.rawValue
            let matchesQuery = normalizedTerm.contains(normalizedQuery)
            
            return matchesQuery && (isCurrentLang || alias.language == "en" || alias.language == "tr")
        }
        
        // Extract foods from matching aliases
        let aliasedFoods = matchingAliases.compactMap { $0.food }
        
        // Filter by category if specified
        var filtered = aliasedFoods
        if let category = selectedCategory {
            filtered = filtered.filter { $0.categoryEnum == category }
        }
        
        // Remove foods already in direct results to avoid duplicates
        filtered = filtered.filter { !existingFoodIds.contains($0.id) }
        
        // Sort by usage and relevance
        return filtered.sorted { food1, food2 in
            // Prioritize recent usage and popularity
            if food1.isRecentlyUsed != food2.isRecentlyUsed {
                return food1.isRecentlyUsed
            }
            if food1.isPopular != food2.isPopular {
                return food1.isPopular
            }
            return food1.displayName < food2.displayName
        }
    }
    
    // MARK: - Search Utilities (migrated from SearchUtilities)
    
    static func normalizeForSearch(_ text: String) -> String {
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
    
    static func translateTurkishToEnglishKeywords(query: String) -> [String] {
        let mapping: [String: [String]] = [
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
            "brokoli": ["broccoli"],
            "ıspanak": ["spinach"],
            "salatalık": ["cucumber"],
            "havuç": ["carrot"],
            "soğan": ["onion"],
            "sarımsak": ["garlic"],
            "zeytinyağı": ["olive oil"],
            "tereyağı": ["butter"],
            "yumurta": ["eggs", "egg"],
            "protein": ["protein"],
            "balık": ["fish"]
        ]
        
        let normalized = normalizeForSearch(query)
        var results: Set<String> = []
        
        // Direct mapping lookup
        for (turkish, english) in mapping {
            let normalizedTurkish = normalizeForSearch(turkish)
            if normalized.contains(normalizedTurkish) {
                english.forEach { results.insert($0) }
            }
        }
        
        // Token-based fallback for partial matches
        let tokens = normalized.split(separator: " ").map(String.init)
        for token in tokens {
            switch token {
            case "tavuk": results.insert("chicken")
            case "gogsu", "göğsü": results.insert("breast")
            case "pirinc", "pirinç": results.insert("rice")
            case "ton": results.insert("tuna")
            case "somon": results.insert("salmon")
            case "yogurt", "yoğurt": results.insert("yogurt")
            case "sut", "süt": results.insert("milk")
            case "peynir": results.insert("cheese")
            case "badem": results.insert("almond")
            case "findik", "fındık": results.insert("hazelnut")
            case "ceviz": results.insert("walnut")
            case "muz": results.insert("banana")
            case "cilek", "çilek": results.insert("strawberry")
            case "domates": results.insert("tomato")
            case "elma": results.insert("apple")
            case "ekmek": results.insert("bread")
            case "makarna": results.insert("pasta")
            case "yumurta": results.insert("eggs")
            case "balik", "balık": results.insert("fish")
            default: break
            }
        }
        
        return Array(results)
    }
    
    // MARK: - Cache Management
    
    private struct SearchResult {
        let foods: [Food]
        let aliasMatches: [Food]
    }
    
    private func createCacheKey(query: String, category: FoodCategory?) -> String {
        let categoryKey = category?.rawValue ?? "all"
        return "\(query)|\(categoryKey)"
    }
    
    private func getCachedResult(for key: String) -> SearchResult? {
        guard let cached = searchCache[key],
              let timestamp = cacheTimestamps[key],
              Date().timeIntervalSince(timestamp) < cacheExpirySeconds else {
            // Remove expired cache
            searchCache.removeValue(forKey: key)
            cacheTimestamps.removeValue(forKey: key)
            return nil
        }
        return cached
    }
    
    private func setCachedResult(_ result: SearchResult, for key: String) {
        // Enforce cache size limit
        if searchCache.count >= maxCacheSize {
            // Remove oldest entries (simple FIFO)
            let oldestKey = cacheTimestamps.min(by: { $0.value < $1.value })?.key
            if let oldest = oldestKey {
                searchCache.removeValue(forKey: oldest)
                cacheTimestamps.removeValue(forKey: oldest)
            }
        }
        
        searchCache[key] = result
        cacheTimestamps[key] = Date()
    }
    
    // MARK: - Category Intelligence
    
    /// Suggests appropriate category based on food name using keyword analysis
    static func suggestCategory(for foodName: String) -> FoodCategory {
        let normalized = normalizeForSearch(foodName)
        
        // Category keywords mapping
        let categoryKeywords: [FoodCategory: [String]] = [
            .meat: ["tavuk", "chicken", "dana", "beef", "kuzu", "lamb", "hindi", "turkey", "et", "meat"],
            .seafood: ["somon", "salmon", "ton", "tuna", "levrek", "bass", "balik", "fish", "karides", "shrimp"],
            .dairy: ["süt", "milk", "yoğurt", "yogurt", "peynir", "cheese", "tereyağı", "butter"],
            .vegetables: ["domates", "tomato", "salatalık", "cucumber", "ıspanak", "spinach", "brokoli", "broccoli", "sebze", "vegetable"],
            .fruits: ["muz", "banana", "elma", "apple", "çilek", "strawberry", "portakal", "orange", "meyve", "fruit"],
            .grains: ["pirinç", "rice", "ekmek", "bread", "makarna", "pasta", "bulgur", "yulaf", "oats"],
            .nuts: ["badem", "almond", "fındık", "hazelnut", "ceviz", "walnut", "fıstık", "peanut"],
            .beverages: ["su", "water", "çay", "tea", "kahve", "coffee", "süt", "milk"],
            .supplements: ["protein", "kreatin", "creatine", "takviye", "supplement", "tozu", "powder"]
        ]
        
        // Find best matching category
        for (category, keywords) in categoryKeywords {
            for keyword in keywords {
                if normalized.contains(normalizeForSearch(keyword)) {
                    return category
                }
            }
        }
        
        return .other
    }
    
    // MARK: - Cleanup
    
    deinit {
        searchTask?.cancel()
        aliasTask?.cancel()
    }
}

// MARK: - Private Helpers
private extension FoodSearchService {
    func normalizeForSearch(_ text: String) -> String {
        Self.normalizeForSearch(text)
    }
    
    func translateTurkishToEnglishKeywords(query: String) -> [String] {
        Self.translateTurkishToEnglishKeywords(query: query)
    }
}