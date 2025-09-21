import SwiftUI

struct AnalyticsScoreDetailRow: View {
    let title: String
    let score: Double
    @Environment(\.theme) private var theme

    var body: some View {
        HStack {
            Text(title)
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textPrimary)

            Spacer()

            HStack(spacing: 8) {
                ProgressView(value: score, total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: getScoreColor(score)))
                    .frame(width: 60)

                Text("\(Int(score))")
                    .font(theme.typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(width: 30)
            }
        }
    }

    private func getScoreColor(_ score: Double) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .yellow
        case 20..<40: return .orange
        default: return .red
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        AnalyticsScoreDetailRow(title: "Sleep Score", score: 85)
        AnalyticsScoreDetailRow(title: "HRV Score", score: 65)
        AnalyticsScoreDetailRow(title: "Workload Score", score: 45)
    }
    .padding()
    .environment(\.theme, DefaultLightTheme())
}