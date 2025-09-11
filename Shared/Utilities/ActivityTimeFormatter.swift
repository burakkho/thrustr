import Foundation

/**
 * ActivityTimeFormatter - Time formatting utilities for activities
 * 
 * Provides consistent time-based formatting for activity display,
 * including relative time formatting (time ago) and duration formatting.
 */
struct ActivityTimeFormatter {
    
    // MARK: - Time Ago Formatting
    
    /**
     * Formats a date as a human-readable "time ago" string
     */
    static func timeAgo(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        // Future dates
        if interval < 0 {
            return DashboardKeys.Activities.inTheFuture.localized
        }
        
        // Just now (less than 1 minute)
        if interval < 60 {
            return DashboardKeys.Activities.justNow.localized
        }
        
        // Minutes ago (1-59 minutes)
        if interval < 3600 {
            let minutes = Int(interval / 60)
            if minutes == 1 {
                return DashboardKeys.Activities.oneMinuteAgo.localized
            } else {
                return String(format: DashboardKeys.Activities.minutesAgo.localized, minutes)
            }
        }
        
        // Hours ago (1-23 hours)
        if interval < 86400 {
            let hours = Int(interval / 3600)
            if hours == 1 {
                return DashboardKeys.Activities.oneHourAgo.localized
            } else {
                return String(format: DashboardKeys.Activities.hoursAgo.localized, hours)
            }
        }
        
        // Yesterday
        if Calendar.current.isDateInYesterday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return String(format: DashboardKeys.Activities.yesterday.localized, formatter.string(from: date))
        }
        
        // This week (2-6 days ago)
        if Calendar.current.dateInterval(of: .weekOfYear, for: now)?.contains(date) == true {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"  // Day of week
            return formatter.string(from: date)
        }
        
        // This month
        if Calendar.current.dateInterval(of: .month, for: now)?.contains(date) == true {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"  // "Jan 15"
            return formatter.string(from: date)
        }
        
        // This year
        if Calendar.current.dateInterval(of: .year, for: now)?.contains(date) == true {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"  // "Jan 15"
            return formatter.string(from: date)
        }
        
        // Previous years
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"  // "Jan 15, 2023"
        return formatter.string(from: date)
    }
    
    // MARK: - Precise Time Formatting
    
    /**
     * Formats a date with precise relative time for debugging/admin views
     */
    static func preciseTimeAgo(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return String(format: "%.0f seconds ago", interval)
        } else if interval < 3600 {
            let minutes = interval / 60
            return String(format: "%.1f minutes ago", minutes)
        } else if interval < 86400 {
            let hours = interval / 3600
            return String(format: "%.1f hours ago", hours)
        } else {
            let days = interval / 86400
            return String(format: "%.1f days ago", days)
        }
    }
    
    // MARK: - Duration Formatting
    
    /**
     * Formats a time interval as a duration string
     */
    static func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            if minutes > 0 {
                return String(format: "%dh %dm", hours, minutes)
            } else {
                return String(format: "%dh", hours)
            }
        } else if minutes > 0 {
            if seconds > 0 && minutes < 10 {
                return String(format: "%dm %ds", minutes, seconds)
            } else {
                return String(format: "%dm", minutes)
            }
        } else {
            return String(format: "%ds", seconds)
        }
    }
    
    // MARK: - Compact Duration Formatting
    
    /**
     * Formats a duration in compact format (e.g., "1:23:45" or "23:45")
     */
    static func formatDurationCompact(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    // MARK: - Time Range Formatting
    
    /**
     * Formats a time range between two dates
     */
    static func formatTimeRange(from startDate: Date, to endDate: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        
        // Same day
        if calendar.isDate(startDate, inSameDayAs: endDate) {
            formatter.timeStyle = .short
            let startTime = formatter.string(from: startDate)
            let endTime = formatter.string(from: endDate)
            return "\(startTime) - \(endTime)"
        }
        
        // Different days
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        let startString = formatter.string(from: startDate)
        let endString = formatter.string(from: endDate)
        return "\(startString) - \(endString)"
    }
    
    // MARK: - Activity Session Time
    
    /**
     * Formats session time for active activities
     */
    static func formatSessionTime(_ duration: TimeInterval) -> String {
        let totalMinutes = Int(duration / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            return String(format: "%d:%02d", hours, minutes)
        } else {
            return String(format: "%d min", minutes > 0 ? minutes : 1)
        }
    }
}