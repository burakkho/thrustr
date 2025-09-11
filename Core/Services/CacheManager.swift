import Foundation

/**
 * Thread-safe cache management using Swift 6 actor pattern.
 * 
 * Handles all background caching operations including:
 * - Workout data caching
 * - Image thumbnail caching  
 * - API response caching
 * - User preference caching
 */
actor CacheManager {
    static let shared = CacheManager()
    
    // MARK: - Private Storage
    private var cache: [String: CacheEntry] = [:]
    private var accessTimes: [String: Date] = [:]
    private let maxCacheSize = 100 // Maximum number of entries
    private let maxAge: TimeInterval = 3600 // 1 hour
    
    private init() {
        // Start periodic cleanup
        Task { @Sendable in
            await startPeriodicCleanup()
        }
    }
    
    // MARK: - Public Interface
    
    /**
     * Store a Sendable value in cache
     */
    func store<T: Sendable>(_ value: T, forKey key: String, ttl: TimeInterval? = nil) async {
        let expirationTime = ttl.map { Date().addingTimeInterval($0) }
        let entry = CacheEntry(value: value, expirationTime: expirationTime)
        
        cache[key] = entry
        accessTimes[key] = Date()
        
        // Clean up if cache is getting too large
        if cache.count > maxCacheSize {
            await evictOldestEntries()
        }
    }
    
    /**
     * Retrieve a value from cache
     */
    func retrieve<T: Sendable>(_ type: T.Type, forKey key: String) async -> T? {
        guard let entry = cache[key] else { return nil }
        
        // Check if expired
        if let expirationTime = entry.expirationTime, Date() > expirationTime {
            cache.removeValue(forKey: key)
            accessTimes.removeValue(forKey: key)
            return nil
        }
        
        // Update access time
        accessTimes[key] = Date()
        
        return entry.value as? T
    }
    
    /**
     * Remove specific cache entry
     */
    func remove(forKey key: String) async {
        cache.removeValue(forKey: key)
        accessTimes.removeValue(forKey: key)
    }
    
    /**
     * Clear all cache entries
     */
    func clearAll() async {
        cache.removeAll()
        accessTimes.removeAll()
    }
    
    /**
     * Get cache statistics
     */
    func getCacheStats() async -> CacheStats {
        let totalEntries = cache.count
        let expiredEntries = cache.values.filter { entry in
            guard let expirationTime = entry.expirationTime else { return false }
            return Date() > expirationTime
        }.count
        
        return CacheStats(
            totalEntries: totalEntries,
            expiredEntries: expiredEntries,
            memoryUsage: estimateMemoryUsage()
        )
    }
    
    // MARK: - Private Methods
    
    private func evictOldestEntries() async {
        let sortedByAccess = accessTimes.sorted { $0.value < $1.value }
        let keysToRemove = sortedByAccess.prefix(10).map { $0.key }
        
        for key in keysToRemove {
            cache.removeValue(forKey: key)
            accessTimes.removeValue(forKey: key)
        }
    }
    
    private func cleanupExpiredEntries() async {
        let now = Date()
        var keysToRemove: [String] = []
        
        for (key, entry) in cache {
            if let expirationTime = entry.expirationTime, now > expirationTime {
                keysToRemove.append(key)
            }
        }
        
        for key in keysToRemove {
            cache.removeValue(forKey: key)
            accessTimes.removeValue(forKey: key)
        }
    }
    
    private func startPeriodicCleanup() async {
        while true {
            try? await Task.sleep(nanoseconds: 300_000_000_000) // 5 minutes
            await cleanupExpiredEntries()
        }
    }
    
    private func estimateMemoryUsage() -> Int {
        // Simple estimation - in real app this could be more sophisticated
        return cache.count * 1000 // Rough estimate in bytes
    }
}

// MARK: - Supporting Types

private struct CacheEntry {
    let value: Any
    let expirationTime: Date?
    let createdAt: Date = Date()
}

struct CacheStats: Sendable {
    let totalEntries: Int
    let expiredEntries: Int
    let memoryUsage: Int
}

// MARK: - Convenience Extensions

extension CacheManager {
    /**
     * Cache workout data with 24 hour TTL
     */
    func cacheWorkoutData<T: Sendable>(_ data: T, forWorkoutId id: String) async {
        await store(data, forKey: "workout_\(id)", ttl: 86400) // 24 hours
    }
    
    /**
     * Cache API response with 1 hour TTL
     */
    func cacheAPIResponse<T: Sendable>(_ response: T, forEndpoint endpoint: String) async {
        await store(response, forKey: "api_\(endpoint)", ttl: 3600) // 1 hour
    }
    
    /**
     * Cache user preference with no expiration
     */
    func cacheUserPreference<T: Sendable>(_ preference: T, forKey key: String) async {
        await store(preference, forKey: "pref_\(key)")
    }
}