import SwiftUI
import SwiftData

struct TestsMainView: View {
    // MARK: - Properties
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @Query(sort: \StrengthTest.testDate, order: .reverse) private var strengthTests: [StrengthTest]
    
    @State private var viewModel: TestResultsViewModel?
    @State private var showingNewTest = false
    @State private var selectedTest: StrengthTest?
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        NavigationStack {
            Group {
                if strengthTests.isEmpty {
                    emptyStateView
                } else {
                    contentView
                }
            }
            .navigationTitle(TrainingKeys.Strength.title.localized)
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            if viewModel == nil {
                viewModel = TestResultsViewModel(modelContext: modelContext)
            }
            viewModel?.loadTestHistory()
        }
        .fullScreenCover(isPresented: $showingNewTest) {
            if let user = users.first {
                StrengthTestView(user: user, modelContext: modelContext)
            } else {
                EmptyStateView(
                    systemImage: "person.slash",
                    title: TrainingKeys.Strength.noUser.localized,
                    message: TrainingKeys.Strength.noUserSubtitle.localized,
                    primaryTitle: CommonKeys.Onboarding.Common.ok.localized,
                    primaryAction: { }
                )
            }
        }
        .sheet(item: $selectedTest) { test in
            TestResultDetailView(strengthTest: test)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: theme.spacing.xl) {
            // Hero image
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 80, weight: .light))
                .foregroundColor(theme.colors.accent)
            
            // Content
            VStack(spacing: theme.spacing.m) {
                Text("strength.main.empty.title".localized)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundColor(theme.colors.textPrimary)
                
                Text("strength.main.empty.subtitle".localized)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Benefits list
            VStack(spacing: theme.spacing.s) {
                BenefitRow(
                    icon: "target",
                    title: "strength.main.empty.benefit1".localized,
                    description: "strength.main.empty.benefit1Description".localized
                )
                
                BenefitRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "strength.main.empty.benefit2".localized,
                    description: "strength.main.empty.benefit2Description".localized
                )
                
                BenefitRow(
                    icon: "brain.head.profile",
                    title: "strength.main.empty.benefit3".localized,
                    description: "strength.main.empty.benefit3Description".localized
                )
            }
            .padding(.horizontal)
            
            // Call to action
            Button {
                showingNewTest = true
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("strength.main.empty.startTest".localized)
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(theme.colors.accent)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.l))
            }
            .padding(.horizontal, theme.spacing.xl)
            
            Spacer()
        }
        .padding(theme.spacing.l)
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: theme.spacing.l) {
                // Current strength profile
                if let latestTest = strengthTests.first(where: { $0.isCompleted }) {
                    currentStrengthSection(latestTest)
                }
                
                // Quick actions
                quickActionsSection
                
                // Test history
                testHistorySection
            }
            .padding(theme.spacing.l)
        }
    }
    
    // MARK: - Current Strength Section
    
    private func currentStrengthSection(_ latestTest: StrengthTest) -> some View {
        VStack(spacing: theme.spacing.m) {
            // Section header
            HStack {
                Text("strength.main.currentProfile".localized)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                
                Spacer()
                
                if let user = users.first, user.isStrengthTestRecommended {
                    Text("strength.main.retestRecommended".localized)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .padding(.horizontal, theme.spacing.s)
                        .padding(.vertical, theme.spacing.xs)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .clipShape(Capsule())
                }
            }
            
            // Profile card
            Button {
                selectedTest = latestTest
            } label: {
                HStack(spacing: theme.spacing.l) {
                    // Body visualization
                    CompactBodyVisualization(
                        results: latestTest.results,
                        size: 80
                    )
                    
                    // Metrics
                    VStack(alignment: .leading, spacing: theme.spacing.s) {
                        HStack {
                            Text(latestTest.averageStrengthLevel.name)
                                .font(.system(.title3, design: .rounded, weight: .bold))
                                .foregroundColor(theme.colors.textPrimary)
                            
                            Text(latestTest.averageStrengthLevel.emoji)
                                .font(.title3)
                        }
                        
                        Text("\(latestTest.strengthProfileEmoji) \(latestTest.strengthProfile.capitalized)")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(theme.colors.textSecondary)
                        
                        Text("strength.main.lastTest".localized + ": " + formatDate(latestTest.testDate))
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Overall score
                    VStack {
                        Text(String(format: "%.0f%%", latestTest.overallScore * 100))
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundColor(theme.colors.accent)
                        
                        Text("strength.main.score".localized)
                            .font(.system(.caption2, design: .rounded))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
                .padding(theme.spacing.l)
                .background(theme.colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.l))
                .shadow(color: theme.shadows.card.opacity(0.05), radius: 2)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Quick Actions Section
    
    private var quickActionsSection: some View {
        VStack(spacing: theme.spacing.m) {
            HStack {
                Text("strength.main.quickActions".localized)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                
                Spacer()
            }
            
            HStack(spacing: theme.spacing.m) {
                // New test
                QuickActionButton(
                    title: "strength.main.actions.newTest".localized,
                    icon: "plus.circle.fill",
                    subtitle: "strength.main.actions.newTestSubtitle".localized,
                    style: .primary,
                    size: .fullWidth
                ) {
                    showingNewTest = true
                }
                
                // View history
                QuickActionButton(
                    title: "strength.main.actions.history".localized,
                    icon: "clock.arrow.circlepath",
                    subtitle: "strength.main.actions.historySubtitle".localized,
                    style: .secondary,
                    size: .fullWidth
                ) {
                    // Scroll to history section
                }
            }
        }
    }
    
    // MARK: - Test History Section
    
    private var testHistorySection: some View {
        VStack(spacing: theme.spacing.m) {
            HStack {
                Text("strength.main.history".localized)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                
                Spacer()
                
                if strengthTests.count > 3 {
                    Button("common.seeAll".localized) {
                        // Navigate to full history
                    }
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(theme.colors.accent)
                }
            }
            
            LazyVStack(spacing: theme.spacing.s) {
                ForEach(Array(strengthTests.prefix(5).enumerated()), id: \.element.testDate) { index, test in
                    TestHistoryRow(
                        strengthTest: test,
                        isLatest: index == 0,
                        onTap: {
                            selectedTest = test
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Supporting Views

private struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(alignment: .top, spacing: theme.spacing.m) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(theme.colors.accent)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                
                Text(description)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(theme.colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}


// MARK: - Test Result Detail View

private struct TestResultDetailView: View {
    let strengthTest: StrengthTest
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            TestResultSummary(
                strengthTest: strengthTest,
                onShareTapped: {
                    // Handle sharing
                },
                onSaveTapped: {
                    dismiss()
                }
            )
            .navigationTitle("strength.results.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.done".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Tests Main View") {
    TestsMainView()
        .modelContainer(for: [User.self, StrengthTest.self, StrengthTestResult.self], inMemory: true)
}
