import SwiftUI

struct AnimatedHealthRing: View {
    let progress: Double
    let title: String
    let value: String
    let goal: String
    let color: Color
    let animate: Bool
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)

                // Progress ring
                Circle()
                    .trim(from: 0, to: animate ? progress : 0)
                    .stroke(
                        LinearGradient(
                            colors: [color.opacity(0.8), color],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.5), value: animate)

                // Center value
                VStack(spacing: 2) {
                    Text(value)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)

                    Text("/ \(goal)")
                        .font(.caption2)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }

            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(theme.colors.textPrimary)
        }
    }
}

// MARK: - Alternative Ring Styles

struct AnimatedHealthRingLarge: View {
    let progress: Double
    let title: String
    let value: String
    let goal: String
    let color: Color
    let animate: Bool
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 12)
                    .frame(width: 120, height: 120)

                // Progress ring
                Circle()
                    .trim(from: 0, to: animate ? progress : 0)
                    .stroke(
                        LinearGradient(
                            colors: [color.opacity(0.7), color],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 2.0), value: animate)

                // Center content
                VStack(spacing: 4) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)

                    Text("/ \(goal)")
                        .font(.caption)
                        .foregroundColor(theme.colors.textSecondary)

                    Text("\(Int(progress * 100))%")
                        .font(.caption2)
                        .foregroundColor(color)
                        .fontWeight(.medium)
                }
            }

            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
        }
    }
}

struct AnimatedHealthRingCompact: View {
    let progress: Double
    let title: String
    let value: String
    let color: Color
    let animate: Bool
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 6)
                    .frame(width: 50, height: 50)

                // Progress ring
                Circle()
                    .trim(from: 0, to: animate ? progress : 0)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: animate)

                // Progress percentage
                Text("\(Int(progress * 100))%")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.textPrimary)

                Text(value)
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

#Preview {
    VStack(spacing: 32) {
        // Standard rings
        HStack(spacing: 40) {
            AnimatedHealthRing(
                progress: 0.65,
                title: "Steps",
                value: "6.5k",
                goal: "10k",
                color: .blue,
                animate: true
            )

            AnimatedHealthRing(
                progress: 0.80,
                title: "Calories",
                value: "400",
                goal: "500",
                color: .orange,
                animate: true
            )

            AnimatedHealthRing(
                progress: 0.92,
                title: "Recovery",
                value: "92%",
                goal: "85%",
                color: .red,
                animate: true
            )
        }

        // Large ring
        AnimatedHealthRingLarge(
            progress: 0.75,
            title: "Daily Activity",
            value: "7.5k",
            goal: "10k",
            color: .green,
            animate: true
        )

        // Compact rings
        VStack(spacing: 8) {
            AnimatedHealthRingCompact(
                progress: 0.60,
                title: "Steps Today",
                value: "6,000 steps",
                color: .blue,
                animate: true
            )

            AnimatedHealthRingCompact(
                progress: 0.85,
                title: "Active Calories",
                value: "425 kcal",
                color: .orange,
                animate: true
            )
        }
    }
    .environment(ThemeManager())
    .padding()
}