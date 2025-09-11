import SwiftUI

struct InAppNotificationView: View {
    let notification: InAppNotificationData
    @Binding var isVisible: Bool
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: theme.spacing.m) {
            // Icon
            Image(systemName: notification.icon)
                .font(.title3)
                .foregroundColor(notification.color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(notification.color.opacity(0.1))
                )
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(notification.message)
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            Spacer()
            
            // Dismiss Button
            Button {
                withAnimation(.easeOut(duration: 0.3)) {
                    isVisible = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
        .padding(theme.spacing.m)
        .background(
            RoundedRectangle(cornerRadius: theme.radius.m)
                .fill(theme.colors.cardBackground)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, theme.spacing.m)
        .transition(.move(edge: .top).combined(with: .opacity))
        .onTapGesture {
            notification.action?()
            withAnimation(.easeOut(duration: 0.3)) {
                isVisible = false
            }
        }
        .onAppear {
            // Auto dismiss after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + notification.duration) {
                withAnimation(.easeOut(duration: 0.3)) {
                    isVisible = false
                }
            }
        }
    }
}

// MARK: - Notification Data Model
struct InAppNotificationData {
    let title: String
    let message: String
    let icon: String
    let color: Color
    let duration: TimeInterval
    let action: (() -> Void)?
    
    init(
        title: String,
        message: String,
        icon: String,
        color: Color = .blue,
        duration: TimeInterval = 3.0,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.color = color
        self.duration = duration
        self.action = action
    }
}

// MARK: - Notification Manager for In-App Notifications
@MainActor
@Observable
final class InAppNotificationManager {
    static let shared = InAppNotificationManager()
    
    var currentNotification: InAppNotificationData?
    var isVisible = false
    
    private init() {}
    
    func show(_ notification: InAppNotificationData) {
        currentNotification = notification
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            isVisible = true
        }
        
        HapticManager.shared.notification(.success)
    }
    
    func showAchievement(title: String, description: String) {
        let notification = InAppNotificationData(
            title: "🏆 " + title,
            message: description,
            icon: "trophy.fill",
            color: .orange,
            duration: 4.0
        )
        show(notification)
    }
    
    func showGoalProgress(message: String) {
        let notification = InAppNotificationData(
            title: "goals.progress".localized,
            message: message,
            icon: "target",
            color: .green,
            duration: 2.5
        )
        show(notification)
    }
}

// MARK: - View Extension for Easy Usage
extension View {
    func withInAppNotifications() -> some View {
        self.overlay(
            InAppNotificationOverlay(),
            alignment: .top
        )
    }
}

// MARK: - Notification Overlay
struct InAppNotificationOverlay: View {
    @State private var manager = InAppNotificationManager.shared
    
    var body: some View {
        VStack {
            if manager.isVisible, let notification = manager.currentNotification {
                InAppNotificationView(
                    notification: notification,
                    isVisible: $manager.isVisible
                )
                .padding(.top, 8)
                .zIndex(999)
            }
            
            Spacer()
        }
    }
}