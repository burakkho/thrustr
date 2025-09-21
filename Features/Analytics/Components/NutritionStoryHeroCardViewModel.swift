import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
class NutritionStoryHeroCardViewModel {

    // MARK: - Properties
    var avgCalories: Int = 0
    var loggedDays: Int = 0
    var consistencyScore: Int = 0
    var celebrationType: CelebrationType = .none

    // MARK: - Dependencies
    private let healthKitNutrition = HealthKitNutritionService.shared

    // MARK: - Initialization
    init() {}

    // MARK: - Public Methods

    func updateNutritionStory(entries: [NutritionEntry]) {
        avgCalories = calculateAvgCalories(entries: entries)
        loggedDays = calculateLoggedDays(entries: entries)
        consistencyScore = calculateConsistency(entries: entries)
        celebrationType = calculateCaloriesCelebration(avgCalories: avgCalories)
    }

    // MARK: - Business Logic

    private func calculateAvgCalories(entries: [NutritionEntry]) -> Int {
        guard !entries.isEmpty else { return 0 }

        let totalCalories = entries.reduce(0) { $0 + $1.calories }
        return Int(totalCalories / Double(entries.count))
    }

    private func calculateLoggedDays(entries: [NutritionEntry]) -> Int {
        let calendar = Calendar.current
        let last7Days = Set(entries.compactMap { entry in
            calendar.dateInterval(of: .day, for: entry.date)?.start
        })

        return last7Days.count
    }

    private func calculateConsistency(entries: [NutritionEntry]) -> Int {
        let loggedDaysCount = calculateLoggedDays(entries: entries)
        let targetDays = 7 // Last 7 days

        return Int((Double(loggedDaysCount) / Double(targetDays)) * 100)
    }

    private func calculateCaloriesCelebration(avgCalories: Int) -> CelebrationType {
        // Base celebration on average calories vs targets
        if avgCalories >= 2500 { return .fire }
        if avgCalories >= 2000 { return .celebration }
        if avgCalories >= 1500 { return .progress }
        return .none
    }

    // MARK: - Helper Methods

    func getWeeklyNutritionEntries(from modelContext: ModelContext) -> [NutritionEntry] {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        let descriptor = FetchDescriptor<NutritionEntry>(
            predicate: #Predicate { entry in
                entry.date >= weekAgo
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            Logger.error("Failed to fetch nutrition entries: \(error)")
            return []
        }
    }

    func getNutritionSummaryText() -> String {
        if loggedDays >= 6 {
            return "Excellent nutrition tracking! \(celebrationType.emoji)"
        } else if loggedDays >= 4 {
            return "Good consistency this week \(celebrationType.emoji)"
        } else if loggedDays >= 2 {
            return "Making progress with tracking \(celebrationType.emoji)"
        } else {
            return "Let's improve nutrition logging!"
        }
    }

    func getConsistencyColor() -> Color {
        switch consistencyScore {
        case 80...100:
            return .green
        case 60...79:
            return .orange
        case 40...59:
            return .yellow
        default:
            return .red
        }
    }
}