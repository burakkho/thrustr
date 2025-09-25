import Foundation

/// Service responsible for date formatting throughout the app
struct DateFormatterService {

    // MARK: - Relative Date Formatting

    /**
     * Formats a date relative to now (e.g., "Today", "2 days ago", "1 week ago")
     *
     * - Parameter date: The date to format
     * - Returns: Human-readable relative date string
     */
    static func formatRelativeDate(_ date: Date) -> String {
        let now = Date()
        let calendar = Calendar.current

        let daysDifference = calendar.dateComponents([.day], from: date, to: now).day ?? 0

        switch daysDifference {
        case 0:
            return "Today"
        case 1:
            return "Yesterday"
        case 2...6:
            return "\(daysDifference) days ago"
        case 7...13:
            return "1 week ago"
        case 14...20:
            return "2 weeks ago"
        case 21...27:
            return "3 weeks ago"
        default:
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }

    /**
     * Formats a date for PR timeline display (more compact format)
     *
     * - Parameter date: The date to format
     * - Returns: Compact relative date string for timeline display
     */
    static func formatPRTimelineDate(_ date: Date) -> String {
        let now = Date()
        let calendar = Calendar.current
        let daysDifference = calendar.dateComponents([.day], from: date, to: now).day ?? 0

        switch daysDifference {
        case 0: return "Today"
        case 1: return "1 day ago"
        case 2...6: return "\(daysDifference) days ago"
        case 7...13: return "1 week ago"
        case 14...20: return "2 weeks ago"
        case 21...27: return "3 weeks ago"
        default:
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }

    // MARK: - Standard Formatters

    /**
     * Standard short date formatter (e.g., "12/25/23")
     */
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()

    /**
     * Standard medium date formatter (e.g., "Dec 25, 2023")
     */
    static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    /**
     * Time only formatter (e.g., "2:30 PM")
     */
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    /**
     * Relative date time formatter using system RelativeDateTimeFormatter
     */
    static let relativeDateTimeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()
}