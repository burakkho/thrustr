import Foundation
import SwiftData
@testable import Thrustr

/**
 * Mock UserService for testing
 * Provides controlled user data without database dependencies
 */
final class MockUserService {
    
    // MARK: - Test Data
    var mockUser: User?
    var shouldFailSave = false
    var shouldFailFetch = false
    
    // MARK: - Test User Factory
    static func createTestUser() -> User {
        let user = User()
        user.name = "Test User"
        user.age = 30
        user.gender = Gender.male.rawValue
        user.height = 180.0 // cm
        user.currentWeight = 75.0 // kg
        user.fitnessGoal = FitnessGoal.cut.rawValue
        user.activityLevel = ActivityLevel.moderate.rawValue
        user.selectedLanguage = "en"
        user.onboardingCompleted = true
        user.consentAccepted = true
        user.marketingOptIn = false
        user.createdAt = Date()
        user.lastActiveDate = Date()
        
        // Initialize required calculated metrics
        user.bmr = 1800
        user.tdee = 2200
        user.dailyCalorieGoal = 2000
        user.dailyProteinGoal = 150
        user.dailyCarbGoal = 200
        user.dailyFatGoal = 75
        
        // Initialize workout stats
        user.totalWorkouts = 0
        user.totalWorkoutTime = 0
        user.totalVolume = 0
        user.totalCardioSessions = 0
        user.totalCardioTime = 0
        user.totalCardioDistance = 0
        user.totalCardioCalories = 0
        user.currentWorkoutStreak = 0
        user.longestWorkoutStreak = 0
        user.strengthTestCompletionCount = 0
        user.lastStrengthScore = 0.0
        user.availablePlates = [1.25, 2.5, 5.0, 10.0, 15.0, 20.0]
        user.hasHomeGym = false
        
        // Set some realistic health data
        // Legacy fields removed - using new data source tracking
        // HealthKit data now accessed directly from HealthKitService
        user.weightSource = DataSource.healthKit.rawValue
        user.weightLastUpdated = Date()
        user.lastHealthKitSync = Date()
        
        return user
    }
    
    // MARK: - Mock Methods
    
    func getCurrentUser(from modelContext: ModelContext) async -> User? {
        if shouldFailFetch {
            return nil
        }
        
        if mockUser == nil {
            mockUser = Self.createTestUser()
        }
        
        return mockUser
    }
    
    func saveUser(_ user: User, to modelContext: ModelContext) async -> Result<Void, DatabaseError> {
        if shouldFailSave {
            return .failure(.saveFailed("Mock save failure"))
        }
        
        mockUser = user
        return .success(())
    }
    
    func updateHealthKitData(
        _ user: User, 
        steps: Double?, 
        calories: Double?, 
        weight: Double?, 
        to modelContext: ModelContext
    ) async -> Result<Void, DatabaseError> {
        if shouldFailSave {
            return .failure(.saveFailed("Mock HealthKit update failure"))
        }
        
        if let steps = steps {
            // Steps now accessed from HealthKitService directly
            print("Mock: Updated steps to \(steps)")
        }
        if let calories = calories {
            // Calories now accessed from HealthKitService directly
            print("Mock: Updated calories to \(calories)")
        }
        if let weight = weight {
            // Use new smart weight update system
            user.updateWeightIntelligently(weight, source: .healthKit)
        }
        
        user.lastHealthKitSync = Date()
        mockUser = user
        
        return .success(())
    }
    
    // MARK: - Test Helpers
    
    func setMockUser(_ user: User) {
        mockUser = user
    }
    
    func simulateFailure() {
        shouldFailSave = true
        shouldFailFetch = true
    }
    
    func simulateSuccess() {
        shouldFailSave = false
        shouldFailFetch = false
    }
    
    func reset() {
        mockUser = nil
        shouldFailSave = false
        shouldFailFetch = false
    }
}