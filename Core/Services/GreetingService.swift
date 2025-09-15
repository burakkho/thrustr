import Foundation

/**
 * GreetingService - Time-based greeting business logic
 *
 * Handles all greeting-related business logic that was previously embedded in Views.
 * Provides time-based greetings and user-specific greeting formatting.
 */
final class GreetingService {

    // MARK: - Public Methods

    /**
     * Generate time-based greeting for user
     *
     * - Parameter user: User model containing name and preferences
     * - Returns: Localized greeting string with user's name
     */
    static func generateGreeting(for user: User) -> String {
        let greeting = getTimeBasedGreeting()
        let displayName = user.name.isEmpty ? "User" : user.name
        return "\(greeting), \(displayName)"
    }

    /**
     * Get current time-based greeting without user name
     *
     * - Returns: Localized greeting based on current time
     */
    static func getTimeBasedGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 6..<12:
            return DashboardKeys.Greeting.goodMorning.localized
        case 12..<18:
            return DashboardKeys.Greeting.goodAfternoon.localized
        case 18..<22:
            return DashboardKeys.Greeting.goodEvening.localized
        default:
            return DashboardKeys.Greeting.goodNight.localized
        }
    }

    /**
     * Check if it's a special time for enhanced greetings
     *
     * - Returns: True if current time warrants special greeting behavior
     */
    static func isSpecialGreetingTime() -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        // Early morning (5-6 AM) or late night (22-24 PM) could be special
        return hour >= 22 || hour <= 6
    }
}