import SwiftUI
import SwiftData
import Foundation

/**
 * ViewModel for AchievementsView with clean separation of concerns.
 *
 * Manages achievement progress tracking, filtering, and statistics.
 * Coordinates with AchievementService for business logic.
 */
@MainActor
@Observable
class AchievementsViewModel {

    // MARK: - State
    var achievements: [Achievement] = []
    var selectedCategory: AchievementCategory = .all
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Dependencies
    // AchievementService is static, no instance needed
    
    // MARK: - Computed Properties
    
    /**
     * Filtered achievements based on selected category.
     */
    var filteredAchievements: [Achievement] {
        if selectedCategory == .all {
            return achievements
        }
        return achievements.filter { $0.category == selectedCategory }
    }
    
    /**
     * Completed achievements count.
     */
    var completedAchievements: [Achievement] {
        return achievements.filter { $0.isCompleted }
    }
    
    /**
     * Total achievements count.
     */
    var totalAchievements: Int {
        return achievements.count
    }
    
    /**
     * Completion percentage across all achievements.
     */
    var completionPercentage: Double {
        guard totalAchievements > 0 else { return 0 }
        return Double(completedAchievements.count) / Double(totalAchievements) * 100
    }
    
    /**
     * Category statistics for progress breakdown.
     */
    var categoryStats: [(AchievementCategory, Int, Int)] {
        return AchievementCategory.allCases.compactMap { category in
            guard category != .all else { return nil }
            let categoryAchievements = achievements.filter { $0.category == category }
            let completed = categoryAchievements.filter { $0.isCompleted }.count
            let total = categoryAchievements.count
            return (category, completed, total)
        }
    }
    
    // MARK: - Initialization
    
    init() {
        // AchievementService is static, no instance needed
    }
    
    // MARK: - Public Methods
    
    /**
     * Loads and updates all achievements with current progress.
     */
    func loadAchievements(
        liftSessions: [LiftSession],
        weightEntries: [WeightEntry],
        nutritionEntries: [NutritionEntry],
        user: User?,
        todaySteps: Double = 0,
        todayActiveCalories: Double = 0
    ) {
        isLoading = true
        errorMessage = nil

        // Get achievements from service using the real method
        achievements = AchievementService.computeRecentAchievements(
            user: user,
            todaySteps: todaySteps,
            todayActiveCalories: todayActiveCalories,
            liftSessions: liftSessions,
            nutritionEntries: nutritionEntries,
            weightEntries: weightEntries
        )

        isLoading = false
    }
    
    /**
     * Updates selected category filter.
     */
    func selectCategory(_ category: AchievementCategory) {
        selectedCategory = category
    }
    
    /**
     * Refreshes achievement progress.
     */
    func refreshAchievements(
        liftSessions: [LiftSession],
        weightEntries: [WeightEntry],
        nutritionEntries: [NutritionEntry],
        user: User?,
        todaySteps: Double = 0,
        todayActiveCalories: Double = 0
    ) {
        loadAchievements(
            liftSessions: liftSessions,
            weightEntries: weightEntries,
            nutritionEntries: nutritionEntries,
            user: user,
            todaySteps: todaySteps,
            todayActiveCalories: todayActiveCalories
        )
    }
    
    /**
     * Gets achievement by ID.
     */
    func getAchievement(by id: UUID) -> Achievement? {
        return achievements.first { $0.id == id }
    }
    
    /**
     * Gets recently completed achievements.
     */
    func getRecentlyCompleted(limit: Int = 3) -> [Achievement] {
        return completedAchievements
            .prefix(limit)
            .map { $0 }
    }
    
    /**
     * Gets achievements closest to completion.
     */
    func getCloseToCompletion(limit: Int = 3) -> [Achievement] {
        return achievements
            .filter { !$0.isCompleted && $0.progressPercentage > 0.5 }
            .sorted { $0.progressPercentage > $1.progressPercentage }
            .prefix(limit)
            .map { $0 }
    }
    
    /**
     * Gets formatted completion percentage.
     */
    func formattedCompletionPercentage() -> String {
        return "\(Int(completionPercentage))%"
    }
    
    /**
     * Gets completed count display text.
     */
    func completedCountText() -> String {
        return "\(completedAchievements.count) / \(totalAchievements)"
    }
    
    /**
     * Resets all achievement data.
     */
    func reset() {
        achievements.removeAll()
        selectedCategory = .all
        isLoading = false
        errorMessage = nil
    }
}

// MARK: - Supporting Extensions

extension AchievementsViewModel {
    
    /**
     * Gets category completion percentage.
     */
    func getCategoryCompletion(for category: AchievementCategory) -> Double {
        let categoryAchievements = achievements.filter { $0.category == category }
        guard !categoryAchievements.isEmpty else { return 0 }
        
        let completed = categoryAchievements.filter { $0.isCompleted }.count
        return Double(completed) / Double(categoryAchievements.count)
    }
    
    /**
     * Gets category progress text.
     */
    func getCategoryProgressText(for category: AchievementCategory) -> String {
        let categoryAchievements = achievements.filter { $0.category == category }
        let completed = categoryAchievements.filter { $0.isCompleted }.count
        return "\(completed)/\(categoryAchievements.count)"
    }
}