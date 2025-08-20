import SwiftUI

// MARK: - Start Workout Action Sheet
struct StartWorkoutActionSheet: View {
    @Environment(\.theme) private var theme
    
    // Callbacks for each action
    let onNewWorkout: () -> Void
    let onSelectProgram: () -> Void
    let onLiftSession: () -> Void
    let onCardioWorkout: () -> Void
    let onDoWOD: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle indicator
            RoundedRectangle(cornerRadius: 2.5)
                .fill(theme.colors.textSecondary.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 24)
            
            // Title
            Text("training.start.title".localized)
                .font(theme.typography.title2)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
                .padding(.bottom, theme.spacing.l)
            
            // Action buttons
            ScrollView {
                VStack(spacing: theme.spacing.m) {
                    // New Workout Button
                    ActionButton(
                        icon: "plus.circle.fill",
                        title: "training.start.new".localized,
                        subtitle: "training.start.new.subtitle".localized,
                        color: theme.colors.success,
                        action: {
                            HapticManager.shared.impact(.light)
                            onNewWorkout()
                        }
                    )
                    
                    // Select Program Button
                    ActionButton(
                        icon: "list.clipboard.fill",
                        title: "training.start.program".localized,
                        subtitle: "training.start.program.subtitle".localized,
                        color: theme.colors.accent,
                        action: {
                            HapticManager.shared.impact(.light)
                            onSelectProgram()
                        }
                    )
                    
                    // Lift Session Button
                    ActionButton(
                        icon: "dumbbell.fill",
                        title: "training.start.lift".localized,
                        subtitle: "training.start.lift.subtitle".localized,
                        color: Color.purple,
                        action: {
                            HapticManager.shared.impact(.light)
                            onLiftSession()
                        }
                    )
                    
                    // Cardio Workout Button
                    ActionButton(
                        icon: "heart.circle.fill",
                        title: "training.start.cardio".localized,
                        subtitle: "training.start.cardio.subtitle".localized,
                        color: Color.pink,
                        action: {
                            HapticManager.shared.impact(.light)
                            onCardioWorkout()
                        }
                    )
                    
                    // WOD Button
                    ActionButton(
                        icon: "timer.circle.fill",
                        title: "training.start.wod".localized,
                        subtitle: "training.start.wod.subtitle".localized,
                        color: theme.colors.warning,
                        action: {
                            HapticManager.shared.impact(.light)
                            onDoWOD()
                        }
                    )
                }
                .padding(.horizontal, theme.spacing.l)
            }
            .frame(maxHeight: 350)
            
            // Cancel button
            Button(action: {
                HapticManager.shared.impact(.light)
                onDismiss()
            }) {
                Text("common.cancel".localized)
                    .font(theme.typography.headline)
                    .foregroundColor(theme.colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, theme.spacing.m)
            }
            .padding(.horizontal, theme.spacing.l)
            .padding(.top, theme.spacing.l)
            .padding(.bottom, theme.spacing.xl)
        }
        .background(theme.colors.backgroundPrimary)
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .accessibilityElement(children: .contain)
        .accessibilityLabel("training.start.title".localized)
    }
}

// MARK: - Action Button Component
private struct ActionButton: View {
    @Environment(\.theme) private var theme
    
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: theme.spacing.m) {
                // Icon container
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(theme.typography.headline)
                        .foregroundColor(theme.colors.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            .padding(theme.spacing.m)
            .background(theme.colors.cardBackground)
            .cornerRadius(theme.radius.m)
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.m)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle)")
        .accessibilityHint("training.start.action.hint".localized)
    }
}

// MARK: - Pressable Button Style
private struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Corner Radius Extension
private extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

private struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview
#Preview {
    StartWorkoutActionSheet(
        onNewWorkout: { print("New workout") },
        onSelectProgram: { print("Select program") },
        onLiftSession: { print("Lift session") },
        onCardioWorkout: { print("Cardio workout") },
        onDoWOD: { print("Do WOD") },
        onDismiss: { print("Dismiss") }
    )
    .frame(height: 500)
}