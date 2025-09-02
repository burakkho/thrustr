import SwiftUI

/**
 * Skeleton loading view for dashboard components.
 * Provides consistent loading states across the app with shimmer animation.
 */
struct SkeletonView: View {
    @Environment(\.theme) private var theme
    @State private var isAnimating = false
    
    let height: CGFloat
    let width: CGFloat?
    let cornerRadius: CGFloat
    
    init(height: CGFloat = 20, width: CGFloat? = nil, cornerRadius: CGFloat = 8) {
        self.height = height
        self.width = width
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        theme.colors.cardBackground.opacity(0.6),
                        theme.colors.cardBackground.opacity(0.9),
                        theme.colors.cardBackground.opacity(0.6)
                    ],
                    startPoint: isAnimating ? .trailing : .leading,
                    endPoint: isAnimating ? UnitPoint(x: 2, y: 0) : .trailing
                )
            )
            .frame(height: height)
            .frame(width: width)
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

/**
 * Skeleton card matching the AthleteProfileCard layout.
 */
struct SkeletonUserStatCard: View {
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: theme.spacing.s) {
            // Icon placeholder
            SkeletonView(height: 20, cornerRadius: 4)
                .frame(width: 20)
            
            // Value placeholder
            SkeletonView(height: 24, cornerRadius: 6)
                .frame(width: 40)
            
            // Title placeholder
            SkeletonView(height: 12, cornerRadius: 3)
                .frame(width: 50)
        }
        .frame(maxWidth: .infinity, idealHeight: 80)
        .padding(theme.spacing.m)
        .background(
            RoundedRectangle(cornerRadius: theme.radius.m)
                .fill(theme.colors.cardBackground)
                .shadow(color: Color.black.opacity(0.08), radius: 2, y: 1)
        )
    }
}

/**
 * Skeleton card matching the ActionableStatCard layout.
 */
struct SkeletonActionableStatCard: View {
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon placeholder
            SkeletonView(height: 24, cornerRadius: 6)
                .frame(width: 24)
            
            // Value placeholder
            SkeletonView(height: 22, cornerRadius: 6)
                .frame(width: 50)
            
            // Title placeholder
            SkeletonView(height: 14, cornerRadius: 4)
                .frame(width: 40)
            
            // Progress bar placeholder
            SkeletonView(height: 8, cornerRadius: 4)
            
            // Subtitle placeholder
            SkeletonView(height: 10, cornerRadius: 3)
                .frame(width: 60)
        }
        .frame(maxWidth: .infinity, idealHeight: 140)
        .padding(theme.spacing.m)
        .background(
            RoundedRectangle(cornerRadius: theme.radius.m)
                .fill(theme.colors.cardBackground)
                .shadow(color: Color.black.opacity(0.08), radius: 2, y: 1)
        )
    }
}

/**
 * Skeleton for WelcomeSection.
 */
struct SkeletonWelcomeSection: View {
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    // Greeting placeholder
                    SkeletonView(height: 24, cornerRadius: 6)
                        .frame(width: 200)
                    
                    // Subtitle placeholder
                    SkeletonView(height: 16, cornerRadius: 4)
                        .frame(width: 150)
                }
                
                Spacer()
                
                // Profile initials placeholder
                Circle()
                    .fill(theme.colors.cardBackground.opacity(0.6))
                    .frame(width: 60, height: 60)
                    .overlay(
                        SkeletonView(height: 20, cornerRadius: 4)
                            .frame(width: 20)
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: theme.radius.m)
                .fill(theme.colors.cardBackground)
                .shadow(color: Color.black.opacity(0.08), radius: 2, y: 1)
        )
        .padding(theme.spacing.m)
    }
}

/**
 * Skeleton components for different content types
 */
struct WorkoutSkeletonCard: View {
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SkeletonView(height: 20, width: 150)
                Spacer()
                SkeletonView(height: 18, width: 60, cornerRadius: 12)
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    SkeletonView(height: 12, width: 60)
                    SkeletonView(height: 16, width: 40)
                }
                VStack(alignment: .leading, spacing: 4) {
                    SkeletonView(height: 12, width: 80)
                    SkeletonView(height: 16, width: 50)
                }
                Spacer()
            }
            
            SkeletonView(height: 8, width: nil, cornerRadius: 4)
        }
        .padding()
        .background(theme.colors.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 2, y: 1)
    }
}

struct FoodSkeletonRow: View {
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: 12) {
            SkeletonView(height: 40, width: 40, cornerRadius: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                SkeletonView(height: 16, width: 180)
                SkeletonView(height: 14, width: 120)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                SkeletonView(height: 16, width: 60)
                SkeletonView(height: 12, width: 40)
            }
        }
        .padding(.vertical, 8)
    }
}

struct SkeletonList: View {
    let itemCount: Int
    let spacing: CGFloat
    
    init(itemCount: Int = 5, spacing: CGFloat = 12) {
        self.itemCount = itemCount
        self.spacing = spacing
    }
    
    var body: some View {
        VStack(spacing: spacing) {
            ForEach(0..<itemCount, id: \.self) { _ in
                WorkoutSkeletonCard()
            }
        }
    }
}

#Preview("Skeleton Components") {
    ScrollView {
        VStack(spacing: 16) {
            SkeletonWelcomeSection()
            
            HStack(spacing: 8) {
                SkeletonUserStatCard()
                SkeletonUserStatCard()
                SkeletonUserStatCard()
                SkeletonUserStatCard()
            }
            
            HStack(spacing: 12) {
                SkeletonActionableStatCard()
                SkeletonActionableStatCard()
                SkeletonActionableStatCard()
            }
            
            WorkoutSkeletonCard()
            FoodSkeletonRow()
            
            SkeletonList(itemCount: 3)
        }
        .padding()
        .environment(\.theme, DefaultLightTheme())
    }
}