import SwiftUI

/**
 * Compact row display for strength test history.
 * 
 * Shows test date, overall level, and key metrics in a list-friendly format.
 */
struct TestHistoryRow: View {
    // MARK: - Properties
    let strengthTest: StrengthTest
    let isLatest: Bool
    let onTap: (() -> Void)?
    
    @Environment(\.theme) private var theme
    
    // MARK: - Initialization
    init(
        strengthTest: StrengthTest,
        isLatest: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.strengthTest = strengthTest
        self.isLatest = isLatest
        self.onTap = onTap
    }
    
    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: theme.spacing.m) {
                // Date and status
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    HStack {
                        Text(formattedDate)
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundColor(theme.colors.textPrimary)
                        
                        if isLatest {
                            Text("strength.history.latest".localized)
                                .font(.system(.caption2, design: .rounded, weight: .medium))
                                .padding(.horizontal, theme.spacing.xs)
                                .padding(.vertical, 2)
                                .background(theme.colors.accent.opacity(0.2))
                                .foregroundColor(theme.colors.accent)
                                .clipShape(Capsule())
                        }
                        
                        Spacer()
                    }
                    
                    Text(strengthTest.strengthProfile.capitalized)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                Spacer()
                
                // Overall level indicator
                VStack(alignment: .trailing, spacing: theme.spacing.xs) {
                    CompactLevelRing(
                        level: strengthTest.averageStrengthLevel,
                        percentileInLevel: strengthTest.overallScore
                    )
                    
                    Text(strengthTest.averageStrengthLevel.name)
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            .padding(.vertical, theme.spacing.s)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helper Properties
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: strengthTest.testDate)
    }
}

/**
 * Empty state for test history.
 */
struct TestHistoryEmptyState: View {
    let onStartTest: () -> Void
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: theme.spacing.l) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(theme.colors.textSecondary)
            
            VStack(spacing: theme.spacing.s) {
                Text("strength.history.empty.title".localized)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundColor(theme.colors.textPrimary)
                
                Text("strength.history.empty.subtitle".localized)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onStartTest) {
                Text("strength.history.empty.startTest".localized)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(theme.colors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radius.m))
            }
            .padding(.horizontal, theme.spacing.xl)
        }
        .padding()
    }
}

/**
 * Test history list with section grouping by month.
 */
struct TestHistoryList: View {
    let strengthTests: [StrengthTest]
    let onTestTap: (StrengthTest) -> Void
    let onStartNewTest: () -> Void
    
    @Environment(\.theme) private var theme
    
    private var groupedTests: [(String, [StrengthTest])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        let grouped = Dictionary(grouping: strengthTests.sorted { $0.testDate > $1.testDate }) { test in
            formatter.string(from: test.testDate)
        }
        
        return grouped.sorted { $0.key > $1.key }
    }
    
    var body: some View {
        if strengthTests.isEmpty {
            TestHistoryEmptyState(onStartTest: onStartNewTest)
        } else {
            List {
                ForEach(groupedTests, id: \.0) { monthYear, tests in
                    Section {
                        ForEach(Array(tests.enumerated()), id: \.element.testDate) { index, test in
                            TestHistoryRow(
                                strengthTest: test,
                                isLatest: index == 0 && monthYear == groupedTests.first?.0,
                                onTap: { onTestTap(test) }
                            )
                        }
                    } header: {
                        Text(monthYear)
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

// MARK: - Preview

#Preview("Test History Row") {
    let sampleTest = StrengthTest(
        userAge: 25,
        userGender: .male,
        userWeight: 80.0
    )
    // Add some sample results
    sampleTest.isCompleted = true
    sampleTest.overallScore = 0.65
    sampleTest.strengthProfile = "balanced"
    
    return VStack {
        TestHistoryRow(
            strengthTest: sampleTest,
            isLatest: true,
            onTap: { print("Test tapped") }
        )
        
        TestHistoryEmptyState {
            print("Start test tapped")
        }
    }
    .padding()
}