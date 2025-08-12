import Foundation
import SwiftData

// MARK: - OpenFoodFacts Error
enum OpenFoodFactsError: Error, LocalizedError, Equatable {
    case invalidBarcode
    case productNotFound
    case networkUnavailable
    case rateLimited
    case serverError(statusCode: Int)
    case decodingFailed
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidBarcode: return "Geçersiz barkod"
        case .productNotFound: return "Ürün bulunamadı"
        case .networkUnavailable: return "Ağ bağlantısı yok"
        case .rateLimited: return "Çok fazla istek, lütfen tekrar deneyin"
        case .serverError(let status): return "Sunucu hatası (\(status))"
        case .decodingFailed: return "Veri çözümlenemedi"
        case .invalidResponse: return "Geçersiz yanıt"
        }
    }
}

// MARK: - DTOs (limited OFF fields)
struct OFFResponse: Decodable {
    let status: Int?
    let status_verbose: String?
    let product: OFFProduct?
}

struct OFFSearchResponse: Decodable {
    let products: [OFFProduct]?
}

struct OFFProduct: Decodable {
    let code: String?
    let product_name: String?
    let brands: String?
    let image_small_url: String?
    let last_modified_t: Double?
    let lc: String?
    let nutriments: OFFNutriments?
}

struct OFFNutriments: Decodable {
    let energyKcal100g: OFFNumeric?
    let protein100g: OFFNumeric?
    let carbs100g: OFFNumeric?
    let fat100g: OFFNumeric?

    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case protein100g = "proteins_100g"
        case carbs100g = "carbohydrates_100g"
        case fat100g = "fat_100g"
    }
}

// OFF bazen sayıları string olarak döndürüyor. Her iki formu da karşılayan decoder.
struct OFFNumeric: Decodable {
    let value: Double?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let d = try? container.decode(Double.self) {
            value = d
            return
        }
        if let s = try? container.decode(String.self) {
            let normalized = s.replacingOccurrences(of: ",", with: ".")
            value = Double(normalized.trimmingCharacters(in: .whitespacesAndNewlines))
            return
        }
        value = nil
    }
}

// MARK: - Result wrapper to carry metadata (even if Food model lacks fields)
struct OpenFoodFactsLookupResult {
    let food: Food
    let barcode: String
    let imageURL: URL?
    let lastModified: Date?
    let qualityScore: Int?
    let locale: String?
}

// MARK: - Service
@MainActor
final class OpenFoodFactsService: ObservableObject {
    // MARK: - Configuration
    private let baseURL = URL(string: "https://world.openfoodfacts.org/api/v2/")!
    private let userAgent = "SporHocam/1.0 (+https://sporhocam.app)"
    private let timeout: TimeInterval = 10
    private let maxRetries = 3
    private let retryBaseDelay: TimeInterval = 0.5
    private let session: URLSession

    // MARK: - Published state (aligning with app patterns)
    @Published var isLoading: Bool = false
    @Published var lastError: Error?

    // MARK: - Public API
    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let sessionConfig = URLSessionConfiguration.ephemeral
            sessionConfig.timeoutIntervalForRequest = timeout
            sessionConfig.timeoutIntervalForResource = timeout
            sessionConfig.httpAdditionalHeaders = [
                "User-Agent": userAgent,
                "Accept": "application/json"
            ]
            self.session = URLSession(configuration: sessionConfig)
        }
    }

    func fetchProduct(barcode: String, modelContext: ModelContext, preferTurkish: Bool = true) async throws -> OpenFoodFactsLookupResult {
        guard Self.isValidBarcode(barcode) else { throw OpenFoodFactsError.invalidBarcode }

        isLoading = true
        defer { isLoading = false }

        // Try TR first, then EN fallback
        do {
            if preferTurkish {
                if let result = try await fetchSingleLocale(barcode: barcode, lc: "tr", modelContext: modelContext) {
                    return result
                }
            }
            if let result = try await fetchSingleLocale(barcode: barcode, lc: "en", modelContext: modelContext) {
                return result
            }
        } catch {
            lastError = error
            throw error
        }

        lastError = OpenFoodFactsError.productNotFound
        throw OpenFoodFactsError.productNotFound
    }

    /// Search products by free-text name via OFF and map to minimal Food models.
    /// Results are not persisted automatically; caller decides when to insert.
    func searchProducts(query: String, lc: String = "tr", limit: Int = 20) async throws -> [OpenFoodFactsLookupResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var components = URLComponents(string: "https://world.openfoodfacts.org/cgi/search.pl")!
        components.queryItems = [
            URLQueryItem(name: "search_terms", value: trimmed),
            URLQueryItem(name: "search_simple", value: "1"),
            URLQueryItem(name: "action", value: "process"),
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "fields", value: "code,product_name,brands,nutriments,image_small_url,last_modified_t,lc"),
            URLQueryItem(name: "page_size", value: String(limit)),
            URLQueryItem(name: "lc", value: lc)
        ]
        guard let url = components.url else { throw OpenFoodFactsError.invalidResponse }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw OpenFoodFactsError.invalidResponse
        }

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(OFFSearchResponse.self, from: data)
        let products = decoded.products ?? []

        let results: [OpenFoodFactsLookupResult] = products.compactMap { product in
            let calories = product.nutriments?.energyKcal100g?.value ?? 0
            let protein = product.nutriments?.protein100g?.value ?? 0
            let carbs = product.nutriments?.carbs100g?.value ?? 0
            let fat = product.nutriments?.fat100g?.value ?? 0

            // Names: prefer localized if provided
            let displayName = product.product_name?.trimmingCharacters(in: .whitespacesAndNewlines)
            let nameTR = lc == "tr" ? (displayName ?? "") : ""
            let nameEN = lc == "en" ? (displayName ?? "") : (displayName ?? "")

            let food = Food(
                nameEN: nameEN,
                nameTR: nameTR,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                category: .other
            )
            if let brand = product.brands, !brand.isEmpty { food.brand = brand }
            food.source = .openFoodFacts
            food.barcode = product.code ?? ""
            if let img = product.image_small_url, !img.isEmpty { food.imageUrlString = img }
            if let ts = product.last_modified_t { food.lastModified = Date(timeIntervalSince1970: ts) }

            return OpenFoodFactsLookupResult(
                food: food,
                barcode: product.code ?? "",
                imageURL: URL(string: product.image_small_url ?? ""),
                lastModified: product.last_modified_t.flatMap { Date(timeIntervalSince1970: $0) },
                qualityScore: nil,
                locale: product.lc ?? lc
            )
        }

        // If Turkish results are weak and lc==tr, fallback to English to broaden coverage
        if results.isEmpty && lc == "tr" {
            do {
                let enFallback = try await searchProducts(query: query, lc: "en", limit: limit)
                return enFallback
            } catch {
                return results
            }
        }
        return results
    }

    // MARK: - Internal
    private func fetchSingleLocale(barcode: String, lc: String, modelContext: ModelContext) async throws -> OpenFoodFactsLookupResult? {
        let url = baseURL.appendingPathComponent("product/\(barcode)")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "fields", value: "code,product_name,brands,nutriments,image_small_url,last_modified_t,lc"),
            URLQueryItem(name: "lc", value: lc)
        ]
        guard let finalURL = components.url else { throw OpenFoodFactsError.invalidResponse }

        var lastError: Error?
        for attempt in 0...maxRetries {
            do {
                var request = URLRequest(url: finalURL)
                request.httpMethod = "GET"

                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else { throw OpenFoodFactsError.invalidResponse }

                // Retry on 429/5xx with exponential backoff
                if http.statusCode == 429 || (500...599).contains(http.statusCode) {
                    if attempt < maxRetries {
                        try await Self.sleepForBackoff(base: retryBaseDelay, attempt: attempt)
                        continue
                    } else {
                        if http.statusCode == 429 { throw OpenFoodFactsError.rateLimited }
                        throw OpenFoodFactsError.serverError(statusCode: http.statusCode)
                    }
                }

                guard (200...299).contains(http.statusCode) else {
                    if http.statusCode == 404 { return nil }
                    throw OpenFoodFactsError.serverError(statusCode: http.statusCode)
                }

                let decoder = JSONDecoder()
                let decoded = try decoder.decode(OFFResponse.self, from: data)
                guard let product = decoded.product else { return nil }

                // Map to Food (100g normalization)
                let calories = product.nutriments?.energyKcal100g?.value ?? 0
                let protein = product.nutriments?.protein100g?.value ?? 0
                let carbs = product.nutriments?.carbs100g?.value ?? 0
                let fat = product.nutriments?.fat100g?.value ?? 0

                // Names: prefer localized name; fallback chain
                let displayName = product.product_name?.trimmingCharacters(in: .whitespacesAndNewlines)
                let nameTR = lc == "tr" ? (displayName ?? "") : ""
                let nameEN = lc == "en" ? (displayName ?? "") : (displayName ?? "")

                let food = Food(
                    nameEN: nameEN,
                    nameTR: nameTR,
                    calories: calories,
                    protein: protein,
                    carbs: carbs,
                    fat: fat,
                    category: .other
                )
                if let brand = product.brands, !brand.isEmpty {
                    food.brand = brand
                }
                food.source = .openFoodFacts
                food.barcode = product.code ?? barcode
                if let img = product.image_small_url, !img.isEmpty { food.imageUrlString = img }
                if let ts = product.last_modified_t { food.lastModified = Date(timeIntervalSince1970: ts) }

                let imageURL = URL(string: product.image_small_url ?? "")
                let lastModified: Date? = {
                    guard let ts = product.last_modified_t else { return nil }
                    return Date(timeIntervalSince1970: ts)
                }()

                // OFF quality score is not directly provided in this minimal payload.
                let result = OpenFoodFactsLookupResult(
                    food: food,
                    barcode: product.code ?? barcode,
                    imageURL: imageURL,
                    lastModified: lastModified,
                    qualityScore: nil,
                    locale: product.lc ?? lc
                )

                return result
            } catch {
                lastError = error
                // Network timeouts or transient errors → retry with backoff
                if attempt < maxRetries, (error as? URLError)?.code == .timedOut || (error as? URLError)?.code == .networkConnectionLost {
                    try await Self.sleepForBackoff(base: retryBaseDelay, attempt: attempt)
                    continue
                }
                throw error
            }
        }

        if let lastError { throw lastError }
        return nil
    }

    // MARK: - Helpers
    private static func isValidBarcode(_ code: String) -> Bool {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        // Accept common retail formats: EAN-8 (8), EAN-13/UPC-A (12/13), UPC-E (6-8 compressed)
        let allowedLengths: Set<Int> = [6, 7, 8, 12, 13]
        return allowedLengths.contains(trimmed.count) && CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: trimmed))
    }

    private static func sleepForBackoff(base: TimeInterval, attempt: Int) async throws {
        let jitter = TimeInterval.random(in: 0...0.2)
        let delay = pow(2.0, Double(attempt)) * base + jitter
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }
}
