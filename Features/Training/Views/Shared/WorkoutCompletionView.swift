import SwiftUI

public struct WorkoutCompletionSheet: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var unitSettings: UnitSettings
    let workout: Workout
    @State private var animate = false

    public var body: some View {
        VStack(spacing: theme.spacing.xl) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(theme.colors.success)
                .symbolEffect(.bounce, value: animate)

            Text("Tebrikler! 🎉")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(spacing: theme.spacing.m) {
                StatRow(label: "Toplam Set", value: "\(workout.totalSets)")
                let volText = UnitsFormatter.formatVolume(kg: workout.totalVolume, system: unitSettings.unitSystem)
                StatRow(label: "Volume", value: volText)
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
        .accessibilityLabel("Antrenman tamamlandı, set \(workout.totalSets), volume \(UnitsFormatter.formatVolume(kg: workout.totalVolume, system: unitSettings.unitSystem))")
    }

    private var shareMessage: String {
        "\n💪 Antrenmanımı tamamladım!\n\n🏋️ Egzersizler: \(Set(workout.parts.flatMap { $0.exerciseSets.compactMap { $0.exercise?.id } }).count)\n📊 Toplam: \(UnitsFormatter.formatVolume(kg: workout.totalVolume, system: unitSettings.unitSystem))\n\nSpor Hocam 🚀"
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


