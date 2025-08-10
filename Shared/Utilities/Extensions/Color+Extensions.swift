import SwiftUI

extension Color {
    
    // MARK: - App Theme Colors (Adaptive)
    
    /// Ana mavi renk - Primary brand color (adaptive)
    static let appPrimary = Color(.systemBlue)
    
    /// İkincil renk - Secondary actions (adaptive)
    static let appSecondary = Color(.systemBlue).opacity(0.7)
    
    /// Accent renk - Highlights and CTAs (adaptive)
    static let appAccent = Color(.systemBlue)
    
    /// Başarı rengi (adaptive)
    static let appSuccess = Color(.systemGreen)
    
    /// Uyarı rengi (adaptive)
    static let appWarning = Color(.systemOrange)
    
    /// Hata rengi (adaptive)
    static let appError = Color(.systemRed)
    
    // MARK: - Feature Module Colors (Adaptive)
    
    /// Training modülü ana rengi (adaptive)
    static let trainingPrimary = Color(.systemBlue)
    
    /// Training modülü ikincil rengi (adaptive)
    static let trainingSecondary = Color(.systemBlue).opacity(0.7)
    
    /// Nutrition modülü ana rengi (adaptive)
    static let nutritionPrimary = Color(.systemOrange)
    
    /// Nutrition modülü ikincil rengi (adaptive)
    static let nutritionSecondary = Color(.systemOrange).opacity(0.7)
    
    /// Dashboard modülü ana rengi (adaptive)
    static let dashboardPrimary = Color(.systemGreen)
    
    /// Dashboard modülü ikincil rengi (adaptive)
    static let dashboardSecondary = Color(.systemGreen).opacity(0.7)
    
    /// Profile modülü ana rengi (adaptive)
    static let profilePrimary = Color(.systemPurple)
    
    /// Profile modülü ikincil rengi (adaptive)
    static let profileSecondary = Color(.systemPurple).opacity(0.7)
    
    // MARK: - Macro Colors (Adaptive)
    
    /// Protein rengi (adaptive)
    static let proteinColor = Color(.systemRed)
    
    /// Karbonhidrat rengi (adaptive)
    static let carbsColor = Color(.systemBlue)
    
    /// Yağ rengi (adaptive)
    static let fatColor = Color(.systemYellow)
    
    /// Kalori rengi (adaptive)
    static let calorieColor = Color(.systemOrange)
    
    /// Fiber rengi (adaptive)
    static let fiberColor = Color(.systemGreen)
    
    /// Sugar rengi (adaptive)
    static let sugarColor = Color(.systemPink)
    
    // MARK: - Health & Fitness Colors (Adaptive)
    
    /// Heart rate / Cardio (adaptive)
    static let heartRateColor = Color(.systemRed)
    
    /// Steps / Walking (adaptive)
    static let stepsColor = Color(.systemGreen)
    
    /// Weight / Scale (adaptive)
    static let weightColor = Color(.systemBlue)
    
    /// Body fat (adaptive)
    static let bodyFatColor = Color(.systemOrange)
    
    /// Muscle / Strength (adaptive)
    static let muscleColor = Color(.systemPurple)
    
    /// Flexibility / Yoga (adaptive)
    static let flexibilityColor = Color(.systemMint)
    
    // MARK: - RPE (Rate of Perceived Exertion) Colors (Adaptive)
    
    /// RPE 1-3: Very Light (adaptive)
    static let rpeVeryLight = Color(.systemGreen)
    
    /// RPE 4-6: Light to Moderate (adaptive)
    static let rpeModerate = Color(.systemYellow)
    
    /// RPE 7-8: Vigorous (adaptive)
    static let rpeVigorous = Color(.systemOrange)
    
    /// RPE 9-10: Very Hard (adaptive)
    static let rpeVeryHard = Color(.systemRed)
    
    /// RPE rengi al (1-10 arası) (adaptive)
    static func rpeColor(for value: Int) -> Color {
        switch value {
        case 1...3:
            return .rpeVeryLight
        case 4...6:
            return .rpeModerate
        case 7...8:
            return .rpeVigorous
        case 9...10:
            return .rpeVeryHard
        default:
            return Color(.systemGray)
        }
    }
    
    // MARK: - BMI Colors (Adaptive)
    
    /// BMI Underweight (<18.5) (adaptive)
    static let bmiUnderweight = Color(.systemBlue)
    
    /// BMI Normal (18.5-25) (adaptive)
    static let bmiNormal = Color(.systemGreen)
    
    /// BMI Overweight (25-30) (adaptive)
    static let bmiOverweight = Color(.systemOrange)
    
    /// BMI Obese (>30) (adaptive)
    static let bmiObese = Color(.systemRed)
    
    /// BMI kategorisine göre renk al (adaptive)
    static func bmiColor(for value: Double) -> Color {
        switch value {
        case ..<18.5:
            return .bmiUnderweight
        case 18.5..<25:
            return .bmiNormal
        case 25..<30:
            return .bmiOverweight
        default:
            return .bmiObese
        }
    }
    
    // MARK: - Progress Colors (Adaptive)
    
    /// 0-30% ilerleme (adaptive)
    static let progressLow = Color(.systemRed)
    
    /// 30-70% ilerleme (adaptive)
    static let progressMedium = Color(.systemOrange)
    
    /// 70-90% ilerleme (adaptive)
    static let progressHigh = Color(.systemYellow)
    
    /// 90-100% ilerleme (adaptive)
    static let progressComplete = Color(.systemGreen)
    
    /// İlerleme yüzdesine göre renk al (adaptive)
    static func progressColor(for percentage: Double) -> Color {
        switch percentage {
        case 0..<30:
            return .progressLow
        case 30..<70:
            return .progressMedium
        case 70..<90:
            return .progressHigh
        default:
            return .progressComplete
        }
    }
    
    // MARK: - Workout Type Colors (Adaptive)
    
    /// Strength training (adaptive)
    static let strengthColor = Color(.systemBlue)
    
    /// Cardio (adaptive)
    static let cardioColor = Color(.systemRed)
    
    /// Flexibility (adaptive)
    static let flexibilityTypeColor = Color(.systemGreen)
    
    /// CrossFit / WOD (adaptive)
    static let wodColor = Color(.systemOrange)
    
    /// Olympic lifts (adaptive)
    static let olympicColor = Color(.systemPurple)
    
    /// Accessory work (adaptive)
    static let accessoryColor = Color(.systemMint)
    
    /// Warmup (adaptive)
    static let warmupColor = Color(.systemYellow)
    
    // MARK: - Chart Colors (Adaptive)
    
    /// Chart color palette (adaptive)
    static let chartColors: [Color] = [
        Color(.systemBlue),
        Color(.systemGreen),
        Color(.systemOrange),
        Color(.systemRed),
        Color(.systemPurple),
        Color(.systemMint),
        Color(.systemPink),
        Color(.systemYellow),
        Color(.systemIndigo),
        Color(.systemTeal)
    ]
    
    /// Chart color al (index'e göre) (adaptive)
    static func chartColor(at index: Int) -> Color {
        return chartColors[index % chartColors.count]
    }
    
    // MARK: - Background Colors (Adaptive)
    
    /// Primary background (adaptive)
    static let backgroundPrimary = Color(.systemBackground)
    
    /// Secondary background (adaptive)
    static let backgroundSecondary = Color(.secondarySystemBackground)
    
    /// Tertiary background (adaptive)
    static let backgroundTertiary = Color(.tertiarySystemBackground)
    
    /// Grouped background (adaptive)
    static let backgroundGrouped = Color(.systemGroupedBackground)
    
    /// Card background (adaptive)
    static let cardBackground = Color(.systemBackground)
    
    /// Modal background (adaptive)
    static let modalBackground = Color(.systemBackground)
    
    // MARK: - Text Colors (Adaptive)
    
    /// Primary text (adaptive)
    static let textPrimary = Color(.label)
    
    /// Secondary text (adaptive)
    static let textSecondary = Color(.secondaryLabel)
    
    /// Tertiary text (adaptive)
    static let textTertiary = Color(.tertiaryLabel)
    
    /// Quaternary text (adaptive)
    static let textQuaternary = Color(.quaternaryLabel)
    
    /// Placeholder text (adaptive)
    static let textPlaceholder = Color(.placeholderText)
    
    // MARK: - Border Colors (Adaptive)
    
    /// Primary border (adaptive)
    static let borderPrimary = Color(.separator)
    
    /// Secondary border (adaptive)
    static let borderSecondary = Color(.opaqueSeparator)
    
    /// Input border (adaptive)
    static let borderInput = Color(.systemGray4)
    
    /// Focus border (adaptive)
    static let borderFocus = Color.appPrimary
    
    /// Error border (adaptive)
    static let borderError = Color.appError
    
    // MARK: - Shadow Colors (Adaptive)
    
    /// Light shadow (adaptive)
    static var shadowLight: Color {
        Color(.label).opacity(0.05)
    }
    
    /// Medium shadow (adaptive)
    static var shadowMedium: Color {
        Color(.label).opacity(0.1)
    }
    
    /// Heavy shadow (adaptive)
    static var shadowHeavy: Color {
        Color(.label).opacity(0.2)
    }
    
    // MARK: - Overlay Colors (Adaptive)
    
    /// Modal overlay (adaptive)
    static var overlayModal: Color {
        Color(.label).opacity(0.4)
    }
    
    /// Loading overlay (adaptive)
    static var overlayLoading: Color {
        Color(.label).opacity(0.2)
    }
    
    /// Disabled overlay (adaptive)
    static var overlayDisabled: Color {
        Color(.systemGray).opacity(0.3)
    }
    
    // MARK: - Brand Gradients (Adaptive)
    
    /// Primary brand gradient (adaptive)
    static let gradientPrimary = LinearGradient(
        colors: [.appPrimary, .appSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Success gradient (adaptive)
    static let gradientSuccess = LinearGradient(
        colors: [Color(.systemGreen), Color(.systemMint)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Warning gradient (adaptive)
    static let gradientWarning = LinearGradient(
        colors: [Color(.systemOrange), Color(.systemYellow)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Error gradient (adaptive)
    static let gradientError = LinearGradient(
        colors: [Color(.systemRed), Color(.systemPink)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Training gradient (adaptive)
    static let gradientTraining = LinearGradient(
        colors: [.trainingPrimary, .trainingSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Nutrition gradient (adaptive)
    static let gradientNutrition = LinearGradient(
        colors: [.nutritionPrimary, .nutritionSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Utility Methods
    
    /// Hex string'den Color oluştur
    static func hex(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Color'u hex string'e çevir
    var hexString: String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let rgb = Int(red * 255) << 16 | Int(green * 255) << 8 | Int(blue * 255)
        return String(format: "#%06x", rgb)
    }
    
    /// Color'a opacity ekle
    func withOpacity(_ opacity: Double) -> Color {
        return self.opacity(opacity)
    }
    
    /// Color'u darken et
    func darker(by amount: Double = 0.2) -> Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        return Color(UIColor(
            hue: hue,
            saturation: saturation,
            brightness: max(0, brightness - CGFloat(amount)),
            alpha: alpha
        ))
    }
    
    /// Color'u lighten et
    func lighter(by amount: Double = 0.2) -> Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        return Color(UIColor(
            hue: hue,
            saturation: saturation,
            brightness: min(1, brightness + CGFloat(amount)),
            alpha: alpha
        ))
    }
}
