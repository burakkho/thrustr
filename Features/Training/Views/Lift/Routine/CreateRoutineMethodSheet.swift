import SwiftUI

// MARK: - Create Routine Method Sheet
struct CreateRoutineMethodSheet: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    
    let onStartFromScratch: () -> Void
    let onCopyFromTemplate: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle indicator
            handleIndicator
            
            // Header
            headerSection
            
            // Method options
            methodOptionsSection
            
            // Cancel button
            cancelButtonSection
        }
        .background(theme.colors.backgroundPrimary)
        .cornerRadius(20, corners: [.topLeft, .topRight])
    }
    
    // MARK: - Handle Indicator
    private var handleIndicator: some View {
        RoundedRectangle(cornerRadius: 2.5)
            .fill(theme.colors.textSecondary.opacity(0.3))
            .frame(width: 40, height: 5)
            .padding(.top, 12)
            .padding(.bottom, 24)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: theme.spacing.s) {
            Text("routine.create.title".localized)
                .font(theme.typography.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)
            
            Text("routine.create.method".localized)
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, theme.spacing.l)
        .padding(.bottom, theme.spacing.l)
    }
    
    // MARK: - Method Options Section
    private var methodOptionsSection: some View {
        ScrollView {
            VStack(spacing: theme.spacing.m) {
                // Start From Scratch Option
                MethodOptionCard(
                    icon: "plus.circle.fill",
                    title: "routine.create.fromScratch".localized,
                    subtitle: "routine.create.fromScratch.desc".localized,
                    color: theme.colors.success,
                    action: {
                        HapticManager.shared.impact(.light)
                        dismiss()
                        onStartFromScratch()
                    }
                )
                
                // Copy From Template Option
                MethodOptionCard(
                    icon: "doc.on.clipboard.fill",
                    title: "routine.create.fromTemplate".localized,
                    subtitle: "routine.create.fromTemplate.desc".localized,
                    color: theme.colors.accent,
                    action: {
                        HapticManager.shared.impact(.light)
                        dismiss()
                        onCopyFromTemplate()
                    }
                )
            }
            .padding(.horizontal, theme.spacing.l)
        }
        .frame(maxHeight: 300)
    }
    
    // MARK: - Cancel Button Section
    private var cancelButtonSection: some View {
        Button(action: {
            HapticManager.shared.impact(.light)
            dismiss()
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
}

// MARK: - Method Option Card Component
private struct MethodOptionCard: View {
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
                        .fontWeight(.semibold)
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
    CreateRoutineMethodSheet(
        onStartFromScratch: { print("Start from scratch") },
        onCopyFromTemplate: { print("Copy from template") }
    )
    .frame(height: 400)
}