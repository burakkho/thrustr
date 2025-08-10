import Foundation
import SwiftData
import HealthKit

@MainActor
class UserService: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var error: Error?
    @Published var validationErrors: [ValidationError] = []
    
    // MARK: - Dependencies
    private var modelContext: ModelContext?

    // MARK: - Validation Error Types
    enum ValidationError: LocalizedError {
        case invalidAge(String)
        case invalidHeight(String)
        case invalidWeight(String)
        case invalidName(String)
        case invalidMeasurement(String, String)
        
        var errorDescription: String? {
            switch self {
            case .invalidAge(let message):
                return "Yaş hatası: \(message)"
            case .invalidHeight(let message):
                return "Boy hatası: \(message)"
            case .invalidWeight(let message):
                return "Kilo hatası: \(message)"
            case .invalidName(let message):
                return "İsim hatası: \(message)"
            case .invalidMeasurement(let field, let message):
                return "\(field) hatası: \(message)"
            }
        }
    }
    
    // MARK: - User Data Export Structure
    struct UserDataExport: Codable {
        let user: UserData
        let exportDate: Date
        let appVersion: String
        
        struct UserData: Codable {
            let name: String
            let age: Int
            let gender: String
            let height: Double
            let currentWeight: Double
            let fitnessGoal: String
            let activityLevel: String
            let bmr: Double
            let tdee: Double
            let dailyCalorieGoal: Double
            let totalWorkouts: Int
            let totalWorkoutTime: TimeInterval
            let totalVolume: Double
            let bodyMeasurements: BodyMeasurements?
            
            struct BodyMeasurements: Codable {
                let chest: Double?
                let waist: Double?
                let hips: Double?
                let neck: Double?
                let bicep: Double?
                let thigh: Double?
            }
        }
    }
    
    // MARK: - Initialization
    init() {
        // Empty init - healthKitService lazy olarak yüklenecek
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // HealthKitService'i lazy property yapalım
    private lazy var healthKitService = HealthKitService()
    
    // MARK: - User Profile Management
    func updateUserProfile(
        user: User,
        name: String? = nil,
        age: Int? = nil,
        gender: Gender? = nil,
        height: Double? = nil,
        weight: Double? = nil,
        fitnessGoal: FitnessGoal? = nil,
        activityLevel: ActivityLevel? = nil
    ) async throws {
        isLoading = true
        validationErrors = []
        defer { isLoading = false }
        
        // Validate input data
        try validateUserInput(
            name: name ?? user.name,
            age: age ?? user.age,
            height: height ?? user.height,
            weight: weight ?? user.currentWeight
        )
        
        // Update user profile
        user.updateProfile(
            name: name,
            age: age,
            gender: gender,
            height: height,
            weight: weight,
            fitnessGoal: fitnessGoal,
            activityLevel: activityLevel
        )
        
        // Save to database
        try await saveUser(user)
        
        // Sync weight with HealthKit if updated
        if let weight = weight {
            await syncWeightToHealthKit(weight)
        }
        
        print("✅ User profile updated successfully")
    }
    
    func createUser(
        name: String,
        age: Int,
        gender: Gender,
        height: Double,
        weight: Double,
        fitnessGoal: FitnessGoal,
        activityLevel: ActivityLevel,
        selectedLanguage: String = "tr"
    ) async throws -> User {
        isLoading = true
        defer { isLoading = false }
        
        // Validate input
        try validateUserInput(name: name, age: age, height: height, weight: weight)
        
        // Create new user
        let user = User(
            name: name,
            age: age,
            gender: gender,
            height: height,
            currentWeight: weight,
            fitnessGoal: fitnessGoal,
            activityLevel: activityLevel,
            selectedLanguage: selectedLanguage
        )
        
        // Insert to database
        guard let context = modelContext else {
            throw ServiceError.contextNotAvailable
        }
        
        context.insert(user)
        try context.save()
        
        print("✅ New user created successfully")
        return user
    }
    
    // MARK: - Health Metrics Calculation
    func calculateHealthMetrics(for user: User) -> HealthMetrics {
        let bmi = user.bmi
        let bodyFatPercentage = user.calculateBodyFatPercentage()
        let ffmi = calculateFFMI(user: user, bodyFatPercentage: bodyFatPercentage)
        
        return HealthMetrics(
            bmi: bmi,
            bmiCategory: user.bmiCategory,
            bmr: user.bmr,
            tdee: user.tdee,
            bodyFatPercentage: bodyFatPercentage,
            ffmi: ffmi,
            ffmiCategory: categorizeFFMI(ffmi)
        )
    }
    
    func recalculateMetrics(for user: User) {
        user.calculateMetrics()
    }
    
    // MARK: - Body Measurements Management
    func updateBodyMeasurements(
        user: User,
        chest: Double? = nil,
        waist: Double? = nil,
        hips: Double? = nil,
        neck: Double? = nil,
        bicep: Double? = nil,
        thigh: Double? = nil
    ) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Validate measurements
        try validateMeasurements(
            chest: chest,
            waist: waist,
            hips: hips,
            neck: neck,
            bicep: bicep,
            thigh: thigh
        )
        
        // Update measurements
        if let chest = chest { user.chest = chest }
        if let waist = waist { user.waist = waist }
        if let hips = hips { user.hips = hips }
        if let neck = neck { user.neck = neck }
        if let bicep = bicep { user.bicep = bicep }
        if let thigh = thigh { user.thigh = thigh }
        
        user.lastActiveDate = Date()
        
        // Save to database
        try await saveUser(user)
        
        print("✅ Body measurements updated successfully")
    }
    
    func getBodyMeasurements(for user: User) -> BodyMeasurements {
        return BodyMeasurements(
            chest: user.chest,
            waist: user.waist,
            hips: user.hips,
            neck: user.neck,
            bicep: user.bicep,
            thigh: user.thigh,
            bodyFatPercentage: user.calculateBodyFatPercentage()
        )
    }
    
    // MARK: - HealthKit Integration
    func syncWithHealthKit(user: User) async {
        isLoading = true
        defer { isLoading = false }
        
        // Read latest HealthKit data
        await healthKitService.readTodaysData()
        
        // Update user with HealthKit data
        user.updateHealthKitData(
            steps: healthKitService.todaySteps > 0 ? healthKitService.todaySteps : nil,
            calories: healthKitService.todayCalories > 0 ? healthKitService.todayCalories : nil,
            weight: healthKitService.currentWeight
        )
        
        // Save updated user
        do {
            try await saveUser(user)
            print("✅ HealthKit data synced successfully")
        } catch {
            print("❌ Failed to save HealthKit sync: \(error)")
            self.error = error
        }
    }
    
    private func syncWeightToHealthKit(_ weight: Double) async {
        let success = await healthKitService.saveWeight(weight)
        if !success {
            print("⚠️ Failed to sync weight to HealthKit")
        }
    }
    
    // MARK: - Data Validation
    func validateUserInput(name: String, age: Int, height: Double, weight: Double) throws {
        validationErrors = []
        
        // Name validation
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append(.invalidName("İsim boş olamaz"))
        } else if name.count < 2 {
            validationErrors.append(.invalidName("İsim en az 2 karakter olmalı"))
        } else if name.count > 50 {
            validationErrors.append(.invalidName("İsim en fazla 50 karakter olabilir"))
        }
        
        // Age validation
        if age < 13 {
            validationErrors.append(.invalidAge("Yaş en az 13 olmalı"))
        } else if age > 120 {
            validationErrors.append(.invalidAge("Yaş en fazla 120 olabilir"))
        }
        
        // Height validation (cm)
        if height < 100 {
            validationErrors.append(.invalidHeight("Boy en az 100 cm olmalı"))
        } else if height > 250 {
            validationErrors.append(.invalidHeight("Boy en fazla 250 cm olabilir"))
        }
        
        // Weight validation (kg)
        if weight < 30 {
            validationErrors.append(.invalidWeight("Kilo en az 30 kg olmalı"))
        } else if weight > 300 {
            validationErrors.append(.invalidWeight("Kilo en fazla 300 kg olabilir"))
        }
        
        if !validationErrors.isEmpty {
            throw ValidationError.invalidName("Geçersiz giriş verileri")
        }
    }
    
    private func validateMeasurements(
        chest: Double?,
        waist: Double?,
        hips: Double?,
        neck: Double?,
        bicep: Double?,
        thigh: Double?
    ) throws {
        validationErrors = []
        
        if let chest = chest, chest < 50 || chest > 200 {
            validationErrors.append(.invalidMeasurement("Göğüs", "50-200 cm arasında olmalı"))
        }
        
        if let waist = waist, waist < 40 || waist > 200 {
            validationErrors.append(.invalidMeasurement("Bel", "40-200 cm arasında olmalı"))
        }
        
        if let hips = hips, hips < 50 || hips > 200 {
            validationErrors.append(.invalidMeasurement("Kalça", "50-200 cm arasında olmalı"))
        }
        
        if let neck = neck, neck < 20 || neck > 60 {
            validationErrors.append(.invalidMeasurement("Boyun", "20-60 cm arasında olmalı"))
        }
        
        if let bicep = bicep, bicep < 15 || bicep > 70 {
            validationErrors.append(.invalidMeasurement("Bicep", "15-70 cm arasında olmalı"))
        }
        
        if let thigh = thigh, thigh < 30 || thigh > 100 {
            validationErrors.append(.invalidMeasurement("Uyluk", "30-100 cm arasında olmalı"))
        }
        
        if !validationErrors.isEmpty {
            throw ValidationError.invalidMeasurement("Ölçümler", "Geçersiz ölçüm değerleri")
        }
    }
    
    // MARK: - Data Export
    func exportUserData(user: User) -> UserDataExport {
        let bodyMeasurements = UserDataExport.UserData.BodyMeasurements(
            chest: user.chest,
            waist: user.waist,
            hips: user.hips,
            neck: user.neck,
            bicep: user.bicep,
            thigh: user.thigh
        )
        
        let userData = UserDataExport.UserData(
            name: user.name,
            age: user.age,
            gender: user.gender,
            height: user.height,
            currentWeight: user.currentWeight,
            fitnessGoal: user.fitnessGoal,
            activityLevel: user.activityLevel,
            bmr: user.bmr,
            tdee: user.tdee,
            dailyCalorieGoal: user.dailyCalorieGoal,
            totalWorkouts: user.totalWorkouts,
            totalWorkoutTime: user.totalWorkoutTime,
            totalVolume: user.totalVolume,
            bodyMeasurements: bodyMeasurements
        )
        
        return UserDataExport(
            user: userData,
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        )
    }
    
    // MARK: - Helper Methods
    private func saveUser(_ user: User) async throws {
        guard let context = modelContext else {
            throw ServiceError.contextNotAvailable
        }
        
        try context.save()
    }
    
    private func calculateFFMI(user: User, bodyFatPercentage: Double?) -> Double? {
        guard let bodyFat = bodyFatPercentage else { return nil }
        
        let leanBodyMass = user.currentWeight * (1 - bodyFat / 100)
        let heightInMeters = user.height / 100
        let ffmi = leanBodyMass / (heightInMeters * heightInMeters)
        
        // Normalize for height (standard normalization)
        let normalizedFFMI = ffmi + 6.1 * (1.8 - heightInMeters)
        
        return normalizedFFMI
    }
    
    private func categorizeFFMI(_ ffmi: Double?) -> String {
        guard let ffmi = ffmi else { return "Hesaplanamıyor" }
        
        switch ffmi {
        case ..<16:
            return "Düşük"
        case 16..<18:
            return "Ortalama altı"
        case 18..<20:
            return "Ortalama"
        case 20..<22:
            return "İyi"
        case 22..<24:
            return "Çok iyi"
        case 24..<26:
            return "Mükemmel"
        default:
            return "Elite"
        }
    }
}

// MARK: - Supporting Types
struct HealthMetrics {
    let bmi: Double
    let bmiCategory: String
    let bmr: Double
    let tdee: Double
    let bodyFatPercentage: Double?
    let ffmi: Double?
    let ffmiCategory: String
}

struct BodyMeasurements {
    let chest: Double?
    let waist: Double?
    let hips: Double?
    let neck: Double?
    let bicep: Double?
    let thigh: Double?
    let bodyFatPercentage: Double?
}

enum ServiceError: LocalizedError {
    case contextNotAvailable
    case userNotFound
    case invalidData(String)
    
    var errorDescription: String? {
        switch self {
        case .contextNotAvailable:
            return "Veritabanı bağlantısı bulunamadı"
        case .userNotFound:
            return "Kullanıcı bulunamadı"
        case .invalidData(let message):
            return "Geçersiz veri: \(message)"
        }
    }
}
