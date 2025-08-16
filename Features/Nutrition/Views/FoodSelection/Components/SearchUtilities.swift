import Foundation

// MARK: - Search normalization & language mapping
struct SearchUtilities {
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
}

enum LanguageSearchMap {
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
        return dict.compactMap { key, vals in
            if let pattern = try? NSRegularExpression(
                pattern: "(^|\\s)" + NSRegularExpression.escapedPattern(for: key) + "(\\s|$)",
                options: [.caseInsensitive]
            ) {
                return (pattern, vals)
            }
            return nil
        }
    }()
    
    static func translateTurkishToEnglishKeywords(query: String) -> [String] {
        let q = SearchUtilities.normalizeForSearch(query)
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
