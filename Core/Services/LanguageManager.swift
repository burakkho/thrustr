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
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .system:
                return "Sistem"
            case .turkish:
                return "Türkçe"
            case .english:
                return "İngilizce"
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
            }
        }
    }
    
    private init() {
        loadLanguagePreference()
    }
    
    private func loadLanguagePreference() {
        let savedLanguage = UserDefaults.standard.string(forKey: "app_language") ?? "system"
        currentLanguage = Language(rawValue: savedLanguage) ?? .system
        updateAppLanguage()
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
