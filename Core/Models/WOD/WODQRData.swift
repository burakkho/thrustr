import Foundation

// Minimal WOD data structure for QR code sharing
// Using short keys to minimize QR code size
struct WODQRData: Codable {
    let v: Int // version
    let n: String // name
    let t: String // type (WODType raw value)
    let r: [Int]? // repScheme (optional)
    let tc: Int? // timeCap in seconds (optional)
    let m: [Movement] // movements
    
    struct Movement: Codable {
        let n: String // name
        let rx: String? // RX weight (e.g., "43/30kg")
        let rp: Int? // reps (optional, if not using repScheme)
    }
    
    init(from wod: WOD) {
        self.v = 1
        self.n = wod.name
        self.t = wod.type
        self.r = wod.repScheme.isEmpty ? nil : wod.repScheme
        self.tc = wod.timeCap
        self.m = wod.movements.map { movement in
            var rxWeight: String? = nil
            if let male = movement.rxWeightMale, let female = movement.rxWeightFemale {
                rxWeight = "\(male)/\(female)"
            } else if let male = movement.rxWeightMale {
                rxWeight = male
            }
            
            return Movement(
                n: movement.name,
                rx: rxWeight,
                rp: movement.reps
            )
        }
    }
    
    // Convert back to WOD for timer
    func toWOD() -> WOD {
        let wod = WOD(
            name: n,
            type: WODType(rawValue: t) ?? .custom,
            repScheme: r ?? [],
            timeCap: tc,
            isCustom: true
        )
        
        // Add movements
        for (index, movement) in m.enumerated() {
            let wodMovement = WODMovement(
                name: movement.n,
                rxWeightMale: parseRXWeight(movement.rx).male,
                rxWeightFemale: parseRXWeight(movement.rx).female,
                reps: movement.rp,
                orderIndex: index
            )
            wod.movements.append(wodMovement)
        }
        
        return wod
    }
    
    private func parseRXWeight(_ rx: String?) -> (male: String?, female: String?) {
        guard let rx = rx else { return (nil, nil) }
        
        // Parse format like "43/30kg" or "95/65lb"
        if rx.contains("/") {
            let parts = rx.split(separator: "/")
            if parts.count == 2 {
                return (String(parts[0]), String(parts[1]))
            }
        }
        
        // Single weight applies to both
        return (rx, rx)
    }
    
    // Encode to JSON string for QR
    func toQRString() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [] // No pretty printing to save space
        let data = try encoder.encode(self)
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    // Decode from QR string
    static func fromQRString(_ string: String) throws -> WODQRData {
        guard let data = string.data(using: .utf8) else {
            throw QRError.invalidData
        }
        let decoder = JSONDecoder()
        return try decoder.decode(WODQRData.self, from: data)
    }
}

enum QRError: LocalizedError {
    case invalidData
    case sizeTooLarge
    case unsupportedVersion
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "This QR code is not a valid WOD"
        case .sizeTooLarge:
            return "WOD data is too large for QR code"
        case .unsupportedVersion:
            return "This QR code version is not supported"
        }
    }
}