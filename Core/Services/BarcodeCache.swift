import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - DTO for cache persistence (Codable)
struct CachedFoodDTO: Codable, Equatable, Sendable {
    let barcode: String
    let nameEN: String
    let nameTR: String
    let brand: String?
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let category: String
    let imageUrlString: String?
    let qualityScore: Int
    let lastModified: Date?
    let fetchedAt: Date
}

// MARK: - Cache Entry (LRU bookkeeping)
private struct CacheEntry: Codable, Equatable, Sendable {
    var dto: CachedFoodDTO
    var lastAccess: Date
}

// MARK: - BarcodeCache
actor BarcodeCache {
    static let shared = BarcodeCache()

    // Configuration
    private(set) var capacity: Int = 100
    private let expiryDays: Int = 7

    // State
    private var map: [String: CacheEntry] = [:]
    private var lruKeys: [String] = [] // MRU at the end

    // Stats
    private var hitCount: Int = 0
    private var missCount: Int = 0

    // Disk
    private lazy var fileURL: URL = {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("BarcodeCache.json")
    }()

    init() {
        Task { @Sendable in await loadFromDisk() }
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            Task { @Sendable in await self.trimTo(limit: self.capacity / 2) }
        }
        #endif
    }

    // MARK: - Public API
    func get(barcode: String) -> CachedFoodDTO? {
        guard var entry = map[barcode] else {
            missCount += 1
            return nil
        }
        // Expiry based on lastModified or fetchedAt
        let referenceDate = entry.dto.lastModified ?? entry.dto.fetchedAt
        if let expiry = Calendar.current.date(byAdding: .day, value: expiryDays, to: referenceDate), Date() > expiry {
            // expired
            removeInternal(for: barcode)
            missCount += 1
            return nil
        }
        // Touch LRU
        entry.lastAccess = Date()
        map[barcode] = entry
        moveKeyToMRU(barcode)
        hitCount += 1
        return entry.dto
    }

    func set(_ dto: CachedFoodDTO) {
        let entry = CacheEntry(dto: dto, lastAccess: Date())
        map[dto.barcode] = entry
        moveKeyToMRU(dto.barcode)
        enforceCapacity()
        Task { @Sendable in await saveToDisk() }
    }

    func remove(barcode: String) {
        removeInternal(for: barcode)
        Task { @Sendable in await saveToDisk() }
    }

    func clearAll() {
        map.removeAll()
        lruKeys.removeAll()
        Task { @Sendable in await saveToDisk() }
    }

    func trimTo(limit: Int) {
        let target = max(0, min(limit, capacity))
        while map.count > target, let lru = lruKeys.first {
            removeInternal(for: lru)
        }
        Task { @Sendable in await saveToDisk() }
    }

    func stats() -> (hits: Int, misses: Int, count: Int) {
        (hitCount, missCount, map.count)
    }

    // MARK: - Private helpers
    private func enforceCapacity() {
        while map.count > capacity, let lru = lruKeys.first {
            removeInternal(for: lru)
        }
    }

    private func moveKeyToMRU(_ key: String) {
        if let idx = lruKeys.firstIndex(of: key) {
            lruKeys.remove(at: idx)
        }
        lruKeys.append(key)
    }

    private func removeInternal(for key: String) {
        map.removeValue(forKey: key)
        if let idx = lruKeys.firstIndex(of: key) {
            lruKeys.remove(at: idx)
        }
    }

    // MARK: - Persistence
    private func saveToDisk() async {
        do {
            let toPersist = map.mapValues { $0 }
            let data = try JSONEncoder().encode(toPersist)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            #if DEBUG
            print("BarcodeCache save error: \(error)")
            #endif
        }
    }

    private func loadFromDisk() async {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([String: CacheEntry].self, from: data)
            map = decoded
            lruKeys = map.values.sorted(by: { $0.lastAccess < $1.lastAccess }).map { $0.dto.barcode }
        } catch {
            // cold start is fine
        }
    }
}

// MARK: - Mapping helpers
extension CachedFoodDTO {
    init(barcode: String, from food: Food) {
        self.barcode = barcode
        self.nameEN = food.nameEN
        self.nameTR = food.nameTR
        self.brand = food.brand
        self.calories = food.calories
        self.protein = food.protein
        self.carbs = food.carbs
        self.fat = food.fat
        self.category = food.category
        self.imageUrlString = food.imageUrlString
        self.qualityScore = food.qualityScore
        self.lastModified = food.lastModified
        self.fetchedAt = Date()
    }

    func toFood() -> Food {
        let catEnum = FoodCategory(rawValue: category) ?? .other
        let food = Food(
            nameEN: nameEN,
            nameTR: nameTR,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            category: catEnum
        )
        food.brand = brand
        food.source = .openFoodFacts
        food.barcode = barcode
        food.imageUrlString = imageUrlString
        food.lastModified = lastModified
        food.qualityScore = qualityScore
        return food
    }
}


