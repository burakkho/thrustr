import SwiftUI

struct AnalyticsTabView: View {
    @Environment(\.theme) private var theme
    @State private var selectedCategory: AnalyticsCategory = .health
    @State private var showingCrossInsights = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 📱 TAB SELECTOR - Generic TabSelector (ScrollView ile text kesme sorunu çözüldü)
                TabSelector(
                    selection: $selectedCategory,
                    items: AnalyticsCategory.allCases
                )
                
                // 🎨 SCROLLABLE CONTENT
                ScrollView {
                    LazyVStack(spacing: theme.spacing.l) {
                        // 🎨 ANIMATED CONTENT TRANSITIONS
                        switch selectedCategory {
                        case .health:
                            HealthAnalyticsView()
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        case .training:
                            TrainingAnalyticsView()
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        case .nutrition:
                            NutritionAnalyticsDashboardView()
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        }
                    }
                    .padding(.bottom, theme.spacing.xl)
                }
            }
            .navigationTitle("analytics.title".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCrossInsights = true }) {
                        Image(systemName: "lightbulb.fill")
                            .font(.title3)
                            .foregroundColor(theme.colors.accent)
                    }
                    .accessibilityLabel("Cross-category insights")
                }
            }
        }
        .sheet(isPresented: $showingCrossInsights) {
            CrossCategoryInsightsView()
        }
    }
}

// MARK: - Analytics Category Enum
enum AnalyticsCategory: String, CaseIterable {
    case health = "health"
    case training = "training"
    case nutrition = "nutrition"
    
    var displayName: String {
        switch self {
        case .health:
            return "analytics.health".localized
        case .training:
            return "analytics.training".localized
        case .nutrition:
            return "analytics.nutrition".localized
        }
    }
    
    var icon: String? {
        switch self {
        case .health:
            return "heart.fill"
        case .training:
            return "dumbbell.fill"
        case .nutrition:
            return "leaf.fill"
        }
    }
}

// MARK: - TabSelectorItem Conformance
extension AnalyticsCategory: TabSelectorItem {
    var id: String { rawValue }
    var badge: Int? { nil }
}




// MARK: - Cross Category Insights View
struct CrossCategoryInsightsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Cross-category correlation insights
                    CrossCategoryInsightCard(
                        title: "💪 Sleep × Strength",
                        insight: "Your best lifting sessions happen after 7.5+ hours of sleep",
                        correlation: "+23% performance",
                        colors: [.blue, .purple]
                    )
                    
                    CrossCategoryInsightCard(
                        title: "🍎 Protein × Recovery",
                        insight: "High protein days lead to faster muscle recovery",
                        correlation: "85% correlation",
                        colors: [.green, .red]
                    )
                    
                    CrossCategoryInsightCard(
                        title: "🔥 Consistency Pattern",
                        insight: "Your Tuesday workouts are 18% more effective",
                        correlation: "Weekly peak",
                        colors: [.orange, .yellow]
                    )
                }
                .padding()
            }
            .navigationTitle("Cross-Category Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Models

// TrendDirection is now defined in Core/Models/TrendDirection.swift

struct CrossCategoryInsightCard: View {
    let title: String
    let insight: String
    let correlation: String
    let colors: [Color]
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)
            
            Text(insight)
                .font(.body)
                .foregroundColor(theme.colors.textSecondary)
                .lineSpacing(2)
            
            HStack {
                Text(correlation)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(8)
                
                Spacer()
            }
        }
        .padding(16)
        .background(theme.colors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(colors: colors.map { $0.opacity(0.3) }, startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
    }
}

#Preview {
    AnalyticsTabView()
        .environment(ThemeManager())
        .environment(UnitSettings.shared)
}