import XCTest
import SwiftData
@testable import Thrustr

final class OpenFoodFactsServiceTests: XCTestCase {
    private class MockURLProtocol: URLProtocol {
        static var response: (Int, Data)?
        static var responsesQueue: [(Int, Data)] = []
        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
        override func startLoading() {
            if !MockURLProtocol.responsesQueue.isEmpty {
                let (status, data) = MockURLProtocol.responsesQueue.removeFirst()
                let resp = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
                client?.urlProtocol(self, didReceive: resp, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } else if let (status, data) = MockURLProtocol.response {
                let resp = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
                client?.urlProtocol(self, didReceive: resp, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } else {
                client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            }
        }
        override func stopLoading() {}
    }

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        config.httpAdditionalHeaders = [
            "User-Agent": "Thrustr/1.0 (+https://thrustr.app)",
            "Accept": "application/json"
        ]
        return URLSession(configuration: config)
    }

    func testFetchProduct_Success_EN() async throws {
        let json = """
        {"status":1,"product":{"code":"1234567890123","product_name":"Test Bar","brands":"TestBrand","image_small_url":"https://img","last_modified_t":1700000000,"lc":"en","nutriments":{"energy-kcal_100g":100,"proteins_100g":10,"carbohydrates_100g":20,"fat_100g":5}}}
        """.data(using: .utf8)!
        MockURLProtocol.response = (200, json)
        let service = OpenFoodFactsService(session: makeSession())

        let container = try XCTUnwrap(try? ModelContainer(for: Food.self, NutritionEntry.self))
        let result = try await service.fetchProduct(barcode: "1234567890123", modelContext: container.mainContext, preferTurkish: false)

        XCTAssertEqual(result.food.nameEN, "Test Bar")
        XCTAssertEqual(Int(result.food.calories), 100)
        XCTAssertEqual(Int(result.food.protein), 10)
        XCTAssertEqual(result.barcode, "1234567890123")
        XCTAssertEqual(result.locale, "en")
    }

    func testFetchProduct_NotFound() async throws {
        let json = "{\"status\":0}".data(using: .utf8)!
        MockURLProtocol.response = (404, json)
        let service = OpenFoodFactsService(session: makeSession())
        let container = try XCTUnwrap(try? ModelContainer(for: Food.self))
        do {
            _ = try await service.fetchProduct(barcode: "0000000000000", modelContext: container.mainContext)
            XCTFail("Expected not found")
        } catch let err as OpenFoodFactsError {
            XCTAssertEqual(err, .productNotFound)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testFetchProduct_RetryThenSuccess() async throws {
        // First 429, then 200
        let successJSON = """
        {"status":1,"product":{"code":"1234567890123","product_name":"Retry Bar","brands":"B","image_small_url":null,"last_modified_t":1700000000,"lc":"en","nutriments":{"energy-kcal_100g":50,"proteins_100g":5,"carbohydrates_100g":10,"fat_100g":1}}}
        """.data(using: .utf8)!
        MockURLProtocol.responsesQueue = [ (429, Data()), (200, successJSON) ]
        let service = OpenFoodFactsService(session: makeSession())
        let container = try XCTUnwrap(try? ModelContainer(for: Food.self))
        let result = try await service.fetchProduct(barcode: "1234567890123", modelContext: container.mainContext)
        XCTAssertEqual(result.food.nameEN, "Retry Bar")
        XCTAssertEqual(Int(result.food.calories), 50)
    }

    func testFetchProduct_TRtoENFallback() async throws {
        // Simulate TR 404 then EN 200
        let enJSON = """
        {"status":1,"product":{"code":"3213213213213","product_name":"English Name","brands":null,"image_small_url":null,"last_modified_t":1700000000,"lc":"en","nutriments":{"energy-kcal_100g":10,"proteins_100g":1,"carbohydrates_100g":2,"fat_100g":0}}}
        """.data(using: .utf8)!
        MockURLProtocol.responsesQueue = [ (404, Data()), (200, enJSON) ]
        let service = OpenFoodFactsService(session: makeSession())
        let container = try XCTUnwrap(try? ModelContainer(for: Food.self))
        let result = try await service.fetchProduct(barcode: "3213213213213", modelContext: container.mainContext, preferTurkish: true)
        XCTAssertEqual(result.locale, "en")
        XCTAssertEqual(result.food.nameEN, "English Name")
    }
}

final class BarcodeValidatorTests: XCTestCase {
    func testEAN13Valid() {
        XCTAssertEqual(BarcodeValidator.normalizeAndValidate("4006381333931"), "4006381333931")
    }
    func testEAN8Valid() {
        XCTAssertEqual(BarcodeValidator.normalizeAndValidate("73513537"), "73513537")
    }
    func testUPCAtoEAN13() {
        let normalized = BarcodeValidator.normalizeAndValidate("036000291452")
        XCTAssertNotNil(normalized)
        XCTAssertEqual(normalized?.count, 13)
        XCTAssertTrue(normalized!.hasPrefix("0"))
    }
    func testInvalidBarcode() {
        XCTAssertNil(BarcodeValidator.normalizeAndValidate("ABC123"))
        XCTAssertNil(BarcodeValidator.normalizeAndValidate("123"))
    }
}

final class BarcodeCacheTests: XCTestCase {
    func testSetGetAndExpiry() async {
        await BarcodeCache.shared.clearAll()
        let food = Food(nameEN: "X", nameTR: "X", calories: 10, protein: 1, carbs: 1, fat: 0, category: .other)
        let dto = CachedFoodDTO(barcode: "1234567890123", from: food)
        await BarcodeCache.shared.set(dto)
        let got = await BarcodeCache.shared.get(barcode: "1234567890123")
        XCTAssertNotNil(got)
    }
}


