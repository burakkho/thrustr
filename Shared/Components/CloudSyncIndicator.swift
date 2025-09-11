import SwiftUI

/**
 * Subtle CloudKit sync status indicator for navigation bars
 * 
 * Shows current sync status with appropriate colors and animations.
 * Designed to be non-intrusive but informative.
 */
struct CloudSyncIndicator: View {
    @Environment(CloudSyncManager.self) var cloudSyncManager
    @State private var isAnimating = false
    
    var body: some View {
        Group {
            if cloudSyncManager.canSync {
                Button {
                    // Optional: tap to show sync details or trigger manual sync
                    Task {
                        await cloudSyncManager.sync()
                    }
                } label: {
                    HStack(spacing: 4) {
                        syncIcon
                            .font(.caption)
                            .foregroundColor(syncColor)
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .rotationEffect(.degrees(isRotating ? 360 : 0))
                            .animation(
                                isRotating ? 
                                .linear(duration: 1.0).repeatForever(autoreverses: false) :
                                .easeInOut(duration: 0.2),
                                value: isAnimating
                            )
                            .animation(
                                isRotating ?
                                .linear(duration: 1.0).repeatForever(autoreverses: false) :
                                .default,
                                value: isRotating
                            )
                        
                        // Optional status text for larger screens
                        if UIDevice.current.userInterfaceIdiom == .pad {
                            Text(cloudSyncManager.syncStatusSummary)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .onChange(of: cloudSyncManager.syncStatus) { _, newStatus in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isAnimating.toggle()
                    }
                    
                    // Reset animation after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        isAnimating = false
                    }
                }
            }
        }
    }
    
    private var syncIcon: Image {
        switch cloudSyncManager.syncStatus {
        case .idle:
            return Image(systemName: "icloud")
        case .syncing:
            return Image(systemName: "arrow.triangle.2.circlepath.icloud")
        case .success:
            return Image(systemName: "checkmark.icloud")
        case .failed:
            return Image(systemName: "exclamationmark.icloud")
        }
    }
    
    private var syncColor: Color {
        switch cloudSyncManager.syncStatus {
        case .idle:
            return .secondary
        case .syncing:
            return .blue
        case .success:
            return .green
        case .failed:
            return .red
        }
    }
    
    private var isRotating: Bool {
        cloudSyncManager.syncStatus == .syncing
    }
}

#Preview {
    NavigationStack {
        Text("Dashboard Content")
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    CloudSyncIndicator()
                        .environment(CloudSyncManager.shared)
                }
            }
    }
}