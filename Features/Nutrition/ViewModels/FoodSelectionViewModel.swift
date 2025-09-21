import SwiftUI
import SwiftData
import Foundation

/**
 * ViewModel for FoodSelectionView with clean separation of concerns.
 *
 * Manages food search, barcode scanning, OpenFoodFacts integration,
 * and coordinates with multiple services for food discovery and selection.
 */
@MainActor
@Observable
class FoodSelectionViewModel {

    // MARK: - State
    var searchText = ""
    var debouncedSearchText = ""
    var selectedCategory: FoodCategory? = nil
    var showingCustomFoodEntry = false
    var showingScanner = false
    var isLoadingOFF = false
    var offErrorMessage: String? = nil
    var offResults: [Food] = []
    var recentSearches: [String] = []
    var toastMessage: String? = nil

    // MARK: - Search State
    var searchService = FoodSearchService()
    var isSearching: Bool { searchService.isSearching }
    var filteredFoods: [Food] { searchService.searchResults }
    var aliasMatches: [Food] { searchService.aliasResults }

    // MARK: - Private Properties
    private var searchTask: Task<Void, Never>? = nil
    private var offSearchTask: Task<Void, Never>? = nil
    private var modelContext: ModelContext?

    // MARK: - Computed Properties

    /**
     * Determines if any search results are available.
     */
    var hasAnyResults: Bool {
        !filteredFoods.isEmpty || !aliasMatches.isEmpty || !offResults.isEmpty
    }

    /**
     * Determines if loading indicator should be shown.
     */
    var shouldShowLoading: Bool {
        (isLoadingOFF || isSearching) && !hasAnyResults
    }

    /**
     * Current search state for UI decisions.
     */
    var isActivelySearching: Bool {
        !debouncedSearchText.isEmpty
    }

    // MARK: - Initialization

    init() {}

    // MARK: - Public Methods

    /**
     * Sets the model context for database operations.
     */
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    /**
     * Updates search text with debouncing.
     */
    func updateSearchText(_ text: String, foods: [Food]) {
        searchText = text

        searchTask?.cancel()
        searchTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            if Task.isCancelled { return }

            debouncedSearchText = text
            performSearch(query: text, foods: foods)
        }
    }

    /**
     * Updates selected category and re-triggers search.
     */
    func updateSelectedCategory(_ category: FoodCategory?, foods: [Food]) {
        selectedCategory = category

        if !searchText.isEmpty {
            performSearch(query: searchText, foods: foods)
        }
    }

    /**
     * Performs search using FoodSearchService.
     */
    func performSearch(query: String, foods: [Food]) {
        guard let modelContext = modelContext else { return }

        searchService.search(
            query: query,
            foods: foods,
            selectedCategory: selectedCategory,
            modelContext: modelContext
        )
    }

    /**
     * Triggers OpenFoodFacts search when debounced text changes.
     */
    func handleDebouncedSearchChange(_ query: String) {
        offSearchTask?.cancel()
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedQuery.isEmpty else {
            offResults = []
            searchService.clearSearch()
            return
        }

        offSearchTask = Task { @MainActor in
            await performOFFSearch(query: trimmedQuery)
        }
    }

    /**
     * Shows scanner modal.
     */
    func startScanning() {
        showingScanner = true
    }

    /**
     * Shows custom food entry modal.
     */
    func showCustomFoodEntry() {
        showingCustomFoodEntry = true
    }

    /**
     * Handles scanned barcode processing.
     */
    func handleScannedBarcode(_ code: String) async {
        guard let normalized = BarcodeValidator.normalizeAndValidate(code) else {
            offErrorMessage = NutritionKeys.Scan.invalidBarcode.localized
            return
        }

        isLoadingOFF = true
        defer { isLoadingOFF = false }

        let service = OpenFoodFactsService()

        do {
            // Check existing by barcode
            if let _ = try fetchFood(byBarcode: normalized) {
                HapticManager.shared.notification(.success)
                toastMessage = NutritionKeys.Scan.existing.localized
                // Handle food selection through closure
                showingScanner = false
                return
            }

            // Cache lookup (LRU) before network
            if let cached = await BarcodeCache.shared.get(barcode: normalized) {
                let food = cached.toFood()
                await insertAndSaveFood(food)
                HapticManager.shared.notification(.success)
                toastMessage = NutritionKeys.Scan.cached.localized
                showingScanner = false
                return
            }

            // Fetch from OpenFoodFacts
            guard let modelContext = modelContext else {
                offErrorMessage = "Invalid model context"
                return
            }

            let result = try await service.fetchProduct(barcode: normalized, modelContext: modelContext)

            // Ensure TR name is present for Turkish searches
            if result.food.nameTR.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                result.food.nameTR = result.food.nameEN
            }

            await insertAndSaveFood(result.food)

            // Update cache
            let dto = CachedFoodDTO(barcode: normalized, from: result.food)
            await BarcodeCache.shared.set(dto)

            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif

            toastMessage = NutritionKeys.Scan.scanned.localized
            showingScanner = false

        } catch {
            HapticManager.shared.notification(.error)
            handleScanError(error)
        }
    }

    /**
     * Handles selection of OpenFoodFacts search result.
     */
    func handleOFFResultSelection(_ food: Food) async {
        // Prevent duplicates by barcode
        if let code = food.barcode {
            do {
                if let _ = try fetchFood(byBarcode: code) {
                    #if canImport(UIKit)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    #endif
                    toastMessage = NutritionKeys.Scan.existing.localized
                    // Handle existing food selection through closure
                    return
                }
            } catch {
                offErrorMessage = error.localizedDescription
                return
            }
        }

        // Ensure TR name is present
        if food.nameTR.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            food.nameTR = food.nameEN
        }

        await insertAndSaveFood(food)
        HapticManager.shared.notification(.success)
        toastMessage = NutritionKeys.Scan.scanned.localized
    }

    /**
     * Clears all search state and cancels ongoing operations.
     */
    func clearSearchState() {
        searchTask?.cancel()
        offSearchTask?.cancel()
        searchService.clearSearch()
    }

    /**
     * Resets all state to initial values.
     */
    func reset() {
        searchText = ""
        debouncedSearchText = ""
        selectedCategory = nil
        showingCustomFoodEntry = false
        showingScanner = false
        isLoadingOFF = false
        offErrorMessage = nil
        offResults = []
        toastMessage = nil
        clearSearchState()
    }

    // MARK: - Private Methods

    @MainActor
    private func performOFFSearch(query: String) async {
        isLoadingOFF = true
        defer { isLoadingOFF = false }

        let service = OpenFoodFactsService()
        do {
            let results = try await service.searchProducts(query: query, lc: "tr", limit: 20)

            // Map to transient Food objects and avoid duplicates
            let existingNames = Set(filteredFoods.map { $0.displayName.lowercased() })
            let mapped: [Food] = results.map { $0.food }.map { f in
                let nf = f
                if nf.nameTR.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    nf.nameTR = nf.nameEN
                }
                return nf
            }.filter { !existingNames.contains($0.displayName.lowercased()) }

            // Remove duplicates by barcode/name/brand
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
            handleOFFError(error)
        }
    }

    private func fetchFood(byBarcode code: String) throws -> Food? {
        guard let modelContext = modelContext else { return nil }

        let descriptor = FetchDescriptor<Food>(
            predicate: #Predicate { $0.barcode == code }
        )
        return try modelContext.fetch(descriptor).first
    }

    @MainActor
    private func insertAndSaveFood(_ food: Food) async {
        guard let modelContext = modelContext else {
            offErrorMessage = "Invalid model context"
            return
        }

        modelContext.insert(food)
        do {
            try modelContext.save()
        } catch {
            offErrorMessage = error.localizedDescription
        }
    }

    private func handleScanError(_ error: Error) {
        if let offError = error as? OpenFoodFactsError {
            offErrorMessage = offError.localizedDescription

            // Handle specific error cases
            switch offError {
            case .productNotFound:
                showingScanner = false
                showingCustomFoodEntry = true
                toastMessage = NutritionKeys.Scan.notFound.localized
            case .rateLimited:
                toastMessage = NutritionKeys.Scan.rateLimited.localized
            default:
                break
            }
        } else {
            offErrorMessage = error.localizedDescription
            toastMessage = NutritionKeys.Scan.networkError.localized
        }
    }

    private func handleOFFError(_ error: Error) {
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

// MARK: - Supporting Types

/**
 * Food selection errors.
 */
enum FoodSelectionError: LocalizedError {
    case invalidContext
    case networkError
    case barcodeValidationFailed

    var errorDescription: String? {
        switch self {
        case .invalidContext:
            return "Invalid model context"
        case .networkError:
            return "Network error occurred"
        case .barcodeValidationFailed:
            return "Invalid barcode format"
        }
    }
}
