import Foundation

extension Double {
    
    // MARK: - Weight & Measurements
    
    /// Kilo formatı: "75.5 kg" (Deprecated in favor of UnitsFormatter)
    var weightString: String { String(format: "%.1f kg", self) }
    
    /// Kilo formatı (tam sayı): "75 kg" (Deprecated)
    var weightStringRounded: String { String(format: "%.0f kg", self) }
    
    /// Boy formatı: "175 cm" (Deprecated)
    var heightString: String { String(format: "%.0f cm", self) }
    
    /// Vücut ölçüsü formatı: "85.5 cm" (Deprecated)
    var measurementString: String { String(format: "%.1f cm", self) }
    
    // MARK: - Nutrition & Calories
    
    /// Kalori formatı: "2,150 kcal"
    var calorieString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let formattedNumber = formatter.string(from: NSNumber(value: self)) ?? String(format: "%.0f", self)
        return "\(formattedNumber) kcal"
    }
    
    /// Makro formatı (gram): "150.5g"
    var macroString: String {
        return String(format: "%.1fg", self)
    }
    
    /// Makro formatı (tam sayı): "150g"
    var macroStringRounded: String {
        return String(format: "%.0fg", self)
    }
    
    /// Protein formatı: "150g protein"
    var proteinString: String {
        return String(format: "%.0fg protein", self)
    }
    
    /// Karbonhidrat formatı: "200g karb"
    var carbString: String {
        return String(format: "%.0fg karb", self)
    }
    
    /// Yağ formatı: "70g yağ"
    var fatString: String {
        return String(format: "%.0fg yağ", self)
    }
    
    // MARK: - Percentages & Ratios
    
    /// Yüzde formatı: "%15.5"
    var percentageString: String {
        return String(format: "%%%.1f", self)
    }
    
    /// Yüzde formatı (tam sayı): "%15"
    var percentageStringRounded: String {
        return String(format: "%%%.0f", self)
    }
    
    /// BMI formatı: "24.5"
    var bmiString: String {
        return String(format: "%.1f", self)
    }
    
    /// Vücut yağı formatı: "%15.5"
    var bodyFatString: String {
        return String(format: "%%%.1f", self)
    }
    
    // MARK: - Workout Related
    
    /// Ağırlık formatı (antrenman): "75kg" veya "75.5kg"
    var workoutWeightString: String {
        if self.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0fkg", self)
        } else {
            return String(format: "%.1fkg", self)
        }
    }
    
    /// Volume formatı: "2,150 kg"
    var volumeString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let formattedNumber = formatter.string(from: NSNumber(value: self)) ?? String(format: "%.0f", self)
        return "\(formattedNumber) kg"
    }
    
    /// RPE formatı: "RPE 8"
    var rpeString: String {
        return "RPE \(Int(self))"
    }
    
    /// Mesafe formatı: "5.2 km" veya "500 m"
    var distanceString: String {
        if self >= 1000 {
            return String(format: "%.1f km", self / 1000)
        } else {
            return String(format: "%.0f m", self)
        }
    }
    
    // MARK: - Time & Duration
    
    /// Süre formatı (saniye): "1:45" veya "0:45"
    var durationString: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Uzun süre formatı: "1s 45d" veya "45d"
    var longDurationString: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)s \(minutes)d"
        } else {
            return "\(minutes)d"
        }
    }
    
    /// Rest timer formatı: "3:00"
    var restTimerString: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Health Metrics
    
    /// TDEE formatı: "2,350 kcal/gün"
    var tdeeString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let formattedNumber = formatter.string(from: NSNumber(value: self)) ?? String(format: "%.0f", self)
        return "\(formattedNumber) kcal/gün"
    }
    
    /// BMR formatı: "1,800 kcal/gün"
    var bmrString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let formattedNumber = formatter.string(from: NSNumber(value: self)) ?? String(format: "%.0f", self)
        return "\(formattedNumber) kcal/gün"
    }
    
    /// FFMI formatı: "22.5"
    var ffmiString: String {
        return String(format: "%.1f", self)
    }
    
    // MARK: - Step & Activity
    
    /// Adım formatı: "12,450 adım"
    var stepsString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let formattedNumber = formatter.string(from: NSNumber(value: self)) ?? String(format: "%.0f", self)
        return "\(formattedNumber) adım"
    }
    
    /// Kısa adım formatı: "12.4K"
    var shortStepsString: String {
        if self >= 1000 {
            return String(format: "%.1fK", self / 1000)
        } else {
            return String(format: "%.0f", self)
        }
    }
    
    // MARK: - Currency & Numbers
    
    /// Para formatı: "₺299.99"
    var currencyString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₺"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: NSNumber(value: self)) ?? "₺\(String(format: "%.2f", self))"
    }
    
    /// Büyük sayı formatı: "1.5K", "2.3M"
    var shortNumberString: String {
        if self >= 1_000_000 {
            return String(format: "%.1fM", self / 1_000_000)
        } else if self >= 1_000 {
            return String(format: "%.1fK", self / 1_000)
        } else {
            return String(format: "%.0f", self)
        }
    }
    
    // MARK: - Validation Helpers
    
    /// Geçerli kilo aralığında mı? (30-300 kg)
    var isValidWeight: Bool {
        return self >= 30 && self <= 300
    }
    
    /// Geçerli boy aralığında mı? (100-250 cm)
    var isValidHeight: Bool {
        return self >= 100 && self <= 250
    }
    
    /// Geçerli BMI aralığında mı? (10-50)
    var isValidBMI: Bool {
        return self >= 10 && self <= 50
    }
    
    /// Geçerli vücut yağı aralığında mı? (5-50%)
    var isValidBodyFat: Bool {
        return self >= 5 && self <= 50
    }
    
    // MARK: - Math Helpers
    
    /// Belirtilen ondalık basamağa yuvarla
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
    
    /// Değerin iki değer arasında olup olmadığını kontrol et
    func isBetween(_ min: Double, and max: Double) -> Bool {
        return self >= min && self <= max
    }
    
    /// Yüzdelik dilim hesapla
    func percentage(of total: Double) -> Double {
        guard total != 0 else { return 0 }
        return (self / total) * 100
    }
}

// String+Localization.swift
// Bu extension'ı Strings+Extensions.swift dosyasına ekleyin veya ayrı bir dosya oluşturun

import Foundation

extension String {
    
    // MARK: - Main Localization Method
    var localized: String {
        // Try to get the current language from UserDefaults
        let savedLanguage = UserDefaults.standard.string(forKey: "app_language") ?? "system"
        
        // Determine which bundle to use
        if savedLanguage == "system" {
            // Use system language
            return NSLocalizedString(self, comment: "")
        } else {
            // Use specific language bundle
            guard let path = Bundle.main.path(forResource: savedLanguage, ofType: "lproj"),
                  let bundle = Bundle(path: path) else {
                // Fallback to default localization
                return NSLocalizedString(self, comment: "")
            }
            return NSLocalizedString(self, bundle: bundle, comment: "")
        }
    }
    
    // MARK: - Localization with Arguments
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
    
    // MARK: - Alternative method if above doesn't work
    func localizedString() -> String {
        let savedLanguage = UserDefaults.standard.string(forKey: "app_language") ?? "system"
        
        if savedLanguage == "system" {
            // Use default bundle
            return NSLocalizedString(self, bundle: Bundle.main, comment: "")
        }
        
        // Try to load specific language bundle
        let languageCode = savedLanguage == "tr" ? "tr" : "en"
        
        guard let bundlePath = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let languageBundle = Bundle(path: bundlePath) else {
            // Fallback to main bundle
            return NSLocalizedString(self, bundle: Bundle.main, comment: "")
        }
        
        return NSLocalizedString(self, bundle: languageBundle, value: self, comment: "")
    }
}

// MARK: - Debug Helper
extension String {
    var debugLocalized: String {
        let result = self.localized
        if result == self {
            print("⚠️ Missing localization for key: \(self)")
        }
        return result
    }
}
