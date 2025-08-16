import SwiftUI

struct WorkoutCard: View {
    let workout: Workout
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("d MMM")
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            WorkoutHeader(
                name: workoutName,
                date: formatWorkoutDate(workout.startTime)
            )
            
            WorkoutStats(
                duration: timeRangeText(for: workout),
                volume: "\(Int(workout.totalVolume)) kg"
            )
        }
        .padding()
        .dashboardSurfaceStyle()
        .frame(width: 200)
    }
    
    // MARK: - Private Properties
    private var workoutName: String {
        workout.name ?? LocalizationKeys.Dashboard.Workout.defaultName.localized
    }
    
    // MARK: - Private Methods
    private func formatWorkoutDate(_ date: Date) -> String {
        WorkoutCard.dateFormatter.string(from: date)
    }
    
    private func timeRangeText(for workout: Workout) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let start = formatter.string(from: workout.startTime)
        
        if let end = workout.endTime {
            return "\(start) - \(formatter.string(from: end))"
        }
        return start
    }
}

// MARK: - Workout Header Component
private struct WorkoutHeader: View {
    let name: String
    let date: String
    
    var body: some View {
        HStack {
            Text(name)
                .font(.headline)
                .lineLimit(1)
            
            Spacer()
            
            Text(date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Workout Stats Component
private struct WorkoutStats: View {
    let duration: String
    let volume: String
    
    var body: some View {
        HStack {
            StatColumn(
                title: LocalizationKeys.Dashboard.Workout.duration.localized,
                value: duration,
                color: .blue
            )
            
            Spacer()
            
            StatColumn(
                title: LocalizationKeys.Dashboard.Workout.volume.localized,
                value: volume,
                color: .green,
                alignment: .trailing
            )
        }
    }
}

// MARK: - Stat Column Component
private struct StatColumn: View {
    let title: String
    let value: String
    let color: Color
    let alignment: HorizontalAlignment
    
    init(title: String, value: String, color: Color, alignment: HorizontalAlignment = .leading) {
        self.title = title
        self.value = value
        self.color = color
        self.alignment = alignment
    }
    
    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(color)
        }
    }
}

#Preview {
    let workout = Workout(name: "Push Day")
    workout.startTime = Date()
    workout.endTime = Date().addingTimeInterval(3600) // 1 hour later
    
    return WorkoutCard(workout: workout)
        .padding()
}