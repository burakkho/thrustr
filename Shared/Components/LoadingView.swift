import SwiftUI
import SwiftData

struct LoadingView: View {
    @Environment(\.theme) private var theme
    let progress: SeedingProgress?
    let onRetry: (() -> Void)?
    let onSkip: (() -> Void)?
    
    init(progress: SeedingProgress? = nil, onRetry: (() -> Void)? = nil, onSkip: (() -> Void)? = nil) {
        self.progress = progress
        self.onRetry = onRetry
        self.onSkip = onSkip
    }
    
    var body: some View {
        VStack(spacing: 32) {
            // App Logo/Icon
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .scaleEffect(1.2)
            
            // Progress Section
            VStack(spacing: 16) {
                if let progress = progress {
                    switch progress {
                    case .error(let message):
                        ErrorStateView(
                            message: message,
                            onRetry: onRetry,
                            onSkip: onSkip
                        )
                    case .completed:
                        CompletedStateView()
                    default:
                        ProgressStateView(progress: progress)
                    }
                } else {
                    // Default loading state
                    DefaultLoadingView()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.backgroundPrimary)
    }
}

// MARK: - Progress State View
private struct ProgressStateView: View {
    @Environment(\.theme) private var theme
    let progress: SeedingProgress
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress Bar - Defensive programming to prevent crash
            let safeProgressValue = max(0.0, min(1.0, progress.progressValue))
            ProgressView(value: safeProgressValue, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: theme.colors.accent))
                .frame(height: 8)
                .frame(maxWidth: 280)
            
            // Progress Text
            VStack(spacing: 8) {
                Text(progress.title)
                    .font(theme.typography.headline)
                    .foregroundColor(theme.colors.textPrimary)
                
                // Defensive programming - safe Int conversion
                let safePercentage = Int(max(0.0, min(100.0, safeProgressValue * 100)))
                Text("\(safePercentage)% Complete")
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            // Loading Spinner
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: theme.colors.accent))
                .scaleEffect(0.8)
        }
    }
}

// MARK: - Error State View  
private struct ErrorStateView: View {
    @Environment(\.theme) private var theme
    let message: String
    let onRetry: (() -> Void)?
    let onSkip: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            // Error Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            // Error Text
            VStack(spacing: 8) {
                Text("Setup Error")
                    .font(theme.typography.headline)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(message)
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            // Action Buttons
            HStack(spacing: 16) {
                if let onRetry = onRetry {
                    Button(CommonKeys.Onboarding.Common.retry.localized) {
                        onRetry()
                    }
                    .buttonStyle(.bordered)
                }
                
                if let onSkip = onSkip {
                    Button(CommonKeys.Onboarding.Common.continueAnyway.localized) {
                        onSkip()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}

// MARK: - Completed State View
private struct CompletedStateView: View {
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 16) {
            // Success Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.green)
            
            // Success Text
            VStack(spacing: 8) {
                Text("Ready to Go!")
                    .font(theme.typography.headline)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text("Database setup completed successfully")
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            // Progress Bar (Full)
            ProgressView(value: 1.0, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                .frame(height: 8)
                .frame(maxWidth: 280)
        }
    }
}

// MARK: - Default Loading View
private struct DefaultLoadingView: View {
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 16) {
            // Loading Spinner
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: theme.colors.accent))
                .scaleEffect(1.5)
            
            // Loading Text
            VStack(spacing: 8) {
                Text("loading.title")
                    .font(theme.typography.headline)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text("loading.subtitle")
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
    }
}

#Preview("Default Loading") {
    LoadingView()
        .environment(\.theme, DefaultLightTheme())
}

#Preview("Progress Loading") {
    LoadingView(progress: .exercises)
        .environment(\.theme, DefaultLightTheme())
}

#Preview("Error State") {
    LoadingView(
        progress: .error("Failed to load exercise database"),
        onRetry: { print("Retry tapped") },
        onSkip: { print("Skip tapped") }
    )
    .environment(\.theme, DefaultLightTheme())
}

#Preview("Completed State") {
    LoadingView(progress: .completed)
        .environment(\.theme, DefaultLightTheme())
}
