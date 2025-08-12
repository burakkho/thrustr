import Foundation

enum BarcodeValidator {
    static func normalizeAndValidate(_ raw: String) -> String? {
        let code = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: code)), !code.isEmpty else { return nil }

        switch code.count {
        case 8:
            return isValidEAN8(code) ? code : nil
        case 12:
            // UPC-A → convert to EAN-13 by prefixing 0 and recomputing checksum
            return isValidUPCA(code) ? toEAN13(fromUPCA: code) : nil
        case 13:
            return isValidEAN13(code) ? code : nil
        case 6, 7: // Likely UPC-E; accept as-is (no reliable expansion without number system)
            return code
        default:
            return nil
        }
    }

    // MARK: - EAN-8
    private static func isValidEAN8(_ code: String) -> Bool {
        guard code.count == 8 else { return false }
        let digits = code.compactMap { Int(String($0)) }
        guard digits.count == 8 else { return false }
        let sum = 3*(digits[0] + digits[2] + digits[4] + digits[6]) + (digits[1] + digits[3] + digits[5])
        let checksum = (10 - (sum % 10)) % 10
        return checksum == digits[7]
    }

    // MARK: - EAN-13
    private static func isValidEAN13(_ code: String) -> Bool {
        guard code.count == 13 else { return false }
        let digits = code.compactMap { Int(String($0)) }
        guard digits.count == 13 else { return false }
        let sum = zip(digits[0..<12], (0..<12)).reduce(0) { acc, pair in
            let (digit, idx) = pair
            return acc + digit * ((idx % 2 == 0) ? 1 : 3)
        }
        let checksum = (10 - (sum % 10)) % 10
        return checksum == digits[12]
    }

    // MARK: - UPC-A (12 digits)
    private static func isValidUPCA(_ code: String) -> Bool {
        guard code.count == 12 else { return false }
        let digits = code.compactMap { Int(String($0)) }
        guard digits.count == 12 else { return false }
        let oddSum = digits[0] + digits[2] + digits[4] + digits[6] + digits[8] + digits[10]
        let evenSum = digits[1] + digits[3] + digits[5] + digits[7] + digits[9]
        let total = (oddSum * 3) + evenSum
        let checksum = (10 - (total % 10)) % 10
        return checksum == digits[11]
    }

    private static func toEAN13(fromUPCA upc: String) -> String {
        // Prefix 0 + first 11 digits, recompute checksum
        let base = "0" + String(upc.prefix(11))
        let digits = base.compactMap { Int(String($0)) }
        let sum = zip(digits[0..<12], (0..<12)).reduce(0) { acc, pair in
            let (digit, idx) = pair
            return acc + digit * ((idx % 2 == 0) ? 1 : 3)
        }
        let checksum = (10 - (sum % 10)) % 10
        return base + String(checksum)
    }
}


