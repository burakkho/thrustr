import SwiftUI

public struct WorkoutCompletionSheet: View {
    @Environment(\.theme) private var theme
    let workout: Workout
    @State private var animate = false

    var body: some View {
        VStack(spacing: theme.spacing.xl) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(theme.colors.success)
                .symbolEffect(.bounce, value: animate)

            Text("Tebrikler! 🎉")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(spacing: theme.spacing.m) {
                StatRow(label: "Süre", value: formatDuration(workout.totalDuration))
                StatRow(label: "Toplam Set", value: "\(workout.totalSets)")
                StatRow(label: "Volume", value: "\(Int(workout.totalVolume)) kg")
            }
            .padding()
            .background(theme.colors.cardBackground)
            .cornerRadius(12)

            ShareLink(item: shareMessage) {
                Label("Paylaş", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(theme.colors.accent)
                    .cornerRadius(12)
            }
            .buttonStyle(PressableStyle())
        }
        .padding()
        .onAppear {
            animate = true
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.success)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Antrenman tamamlandı, süre \(formatDuration(workout.totalDuration)), set \(workout.totalSets), volume \(Int(workout.totalVolume)) kilogram")
    }

    private var shareMessage: String {
        "\n💪 Antrenmanımı tamamladım!\n\n⏱ Süre: \(formatDuration(workout.totalDuration))\n🏋️ Egzersizler: \(Set(workout.parts.flatMap { $0.exerciseSets.compactMap { $0.exercise?.id } }).count)\n📊 Toplam: \(Int(workout.totalVolume)) kg\n\nSpor Hocam 🚀"
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        return hours > 0 ? String(format: "%d:%02d:%02d", hours, minutes, secs) : String(format: "%d:%02d", minutes, secs)
    }
}

struct StatRow: View {
    @Environment(\.theme) private var theme
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(theme.colors.textSecondary)
            Spacer()
            Text(value)
                .font(.headline)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}


