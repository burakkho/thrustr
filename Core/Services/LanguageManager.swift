import SwiftUI
import Foundation

@MainActor
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: Language = .system {
        didSet {
            saveLanguagePreference()
            updateAppLanguage()
        }
    }
    
    // Custom bundle for localization
    private var customBundle: Bundle?
    
    enum Language: String, CaseIterable, Identifiable {
        case system = "system"
        case turkish = "tr"
        case english = "en"
        case spanish = "es"
        case german = "de"
        case italian = "it"
        case french = "fr"
        case portuguese = "pt"
        case indonesian = "id"
        case polish = "pl"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .system:
                return CommonKeys.LanguageNames.system.localized
            case .turkish:
                return CommonKeys.LanguageNames.turkish.localized
            case .english:
                return CommonKeys.LanguageNames.english.localized
            case .spanish:
                return CommonKeys.LanguageNames.spanish.localized
            case .german:
                return CommonKeys.LanguageNames.german.localized
            case .italian:
                return CommonKeys.LanguageNames.italian.localized
            case .french:
                return CommonKeys.LanguageNames.french.localized
            case .portuguese:
                return CommonKeys.LanguageNames.portuguese.localized
            case .indonesian:
                return CommonKeys.LanguageNames.indonesian.localized
            case .polish:
                return CommonKeys.LanguageNames.polish.localized
            }
        }
        
        var flag: String {
            switch self {
            case .system:
                return "🌐"
            case .turkish:
                return "🇹🇷"
            case .english:
                return "🇺🇸"
            case .spanish:
                return "🇪🇸"
            case .german:
                return "🇩🇪"
            case .italian:
                return "🇮🇹"
            case .french:
                return "🇫🇷"
            case .portuguese:
                return "🇵🇹"
            case .indonesian:
                return "🇮🇩"
            case .polish:
                return "🇵🇱"
            }
        }
    }
    
    private init() {
        loadLanguagePreference()
    }
    
    private func loadLanguagePreference() {
        let savedLanguage = UserDefaults.standard.string(forKey: "app_language") ?? "system"
        
        // If no saved preference, try to match system language with supported languages
        if savedLanguage == "system" {
            let systemLanguage = detectBestSupportedLanguage()
            currentLanguage = systemLanguage
            print("🌍 Auto-detected best language: \(systemLanguage.rawValue)")
        } else {
            currentLanguage = Language(rawValue: savedLanguage) ?? .system
        }
        
        updateAppLanguage()
    }
    
    /// Detects the best supported language based on system preferences
    private func detectBestSupportedLanguage() -> Language {
        let preferredLanguages = Locale.preferredLanguages
        print("🔍 System preferred languages: \(preferredLanguages)")
        
        // Check each preferred language against supported languages
        for preferredLang in preferredLanguages {
            let langCode = String(preferredLang.prefix(2)) // Get first 2 characters (language code)
            
            switch langCode {
            case "tr":
                return .turkish
            case "en":
                return .english
            case "es":
                return .spanish
            case "de":
                return .german
            case "it":
                return .italian
            case "fr":
                return .french
            case "pt":
                return .portuguese
            case "id":
                return .indonesian
            case "pl":
                return .polish
            default:
                continue
            }
        }
        
        // If no match found, fall back to English (our base localization)
        print("ℹ️ No supported language found in system preferences, defaulting to English")
        return .english
    }
    
    private func saveLanguagePreference() {
        UserDefaults.standard.set(currentLanguage.rawValue, forKey: "app_language")
    }
    
    private func updateAppLanguage() {
        print("🔄 Changing language to: \(currentLanguage.rawValue)")
        
        // Set custom bundle based on language
        switch currentLanguage {
        case .system:
            customBundle = Bundle.main
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        case .turkish:
            if let path = Bundle.main.path(forResource: "tr", ofType: "lproj"),
               let bundle = Bundle(path: path) {
                customBundle = bundle
            }
            UserDefaults.standard.set(["tr"], forKey: "AppleLanguages")
        case .english:
            if let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
               let bundle = Bundle(path: path) {
                customBundle = bundle
            }
            UserDefaults.standard.set(["en"], forKey: "AppleLanguages")
        case .spanish:
            if let path = Bundle.main.path(forResource: "es", ofType: "lproj"),
               let bundle = Bundle(path: path) {
                customBundle = bundle
            }
            UserDefaults.standard.set(["es"], forKey: "AppleLanguages")
        case .german:
            if let path = Bundle.main.path(forResource: "de", ofType: "lproj"),
               let bundle = Bundle(path: path) {
                customBundle = bundle
                print("✅ German bundle found at: \(path)")
            } else {
                print("❌ German bundle not found")
            }
            UserDefaults.standard.set(["de"], forKey: "AppleLanguages")
        case .italian:
            if let path = Bundle.main.path(forResource: "it", ofType: "lproj"),
               let bundle = Bundle(path: path) {
                customBundle = bundle
                print("✅ Italian bundle found at: \(path)")
            } else {
                print("❌ Italian bundle not found")
            }
            UserDefaults.standard.set(["it"], forKey: "AppleLanguages")
        case .french:
            if let path = Bundle.main.path(forResource: "fr", ofType: "lproj"),
               let bundle = Bundle(path: path) {
                customBundle = bundle
                print("✅ French bundle found at: \(path)")
            } else {
                print("❌ French bundle not found")
            }
            UserDefaults.standard.set(["fr"], forKey: "AppleLanguages")
        case .portuguese:
            if let path = Bundle.main.path(forResource: "pt", ofType: "lproj"),
               let bundle = Bundle(path: path) {
                customBundle = bundle
                print("✅ Portuguese bundle found at: \(path)")
            } else {
                print("❌ Portuguese bundle not found")
            }
            UserDefaults.standard.set(["pt"], forKey: "AppleLanguages")
        case .indonesian:
            if let path = Bundle.main.path(forResource: "id", ofType: "lproj"),
               let bundle = Bundle(path: path) {
                customBundle = bundle
                print("✅ Indonesian bundle found at: \(path)")
            } else {
                print("❌ Indonesian bundle not found")
            }
            UserDefaults.standard.set(["id"], forKey: "AppleLanguages")
        case .polish:
            if let path = Bundle.main.path(forResource: "pl", ofType: "lproj"),
               let bundle = Bundle(path: path) {
                customBundle = bundle
                print("✅ Polish bundle found at: \(path)")
            } else {
                print("❌ Polish bundle not found")
            }
            UserDefaults.standard.set(["pl"], forKey: "AppleLanguages")
        }
        
        UserDefaults.standard.synchronize()
        
        // Trigger UI refresh
        NotificationCenter.default.post(name: .languageDidChange, object: nil)
        
        print("📱 Language updated. CustomBundle: \(customBundle?.bundlePath ?? "main")")
    }
    
    func setLanguage(_ language: Language) {
        currentLanguage = language
    }
    
    // Custom localization method
    func localizedString(_ key: String, comment: String = "") -> String {
        guard let bundle = customBundle else {
            return NSLocalizedString(key, comment: comment)
        }
        
        return NSLocalizedString(key, bundle: bundle, comment: comment)
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
}

// ✅ String Extension SİLİNDİ - conflict çözüldü!
// String+Extensions.swift dosyasında zaten mevcut
