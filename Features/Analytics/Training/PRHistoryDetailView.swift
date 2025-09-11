import SwiftUI
import SwiftData

typealias PRRecord = AnalyticsService.DetailedPRRecord

extension AnalyticsService.DetailedPRRecord: Identifiable {
    var id: String {
        return "\(exerciseName)-\(value)-\(date.timeIntervalSince1970)"
    }
}

extension AnalyticsService.DetailedPRRecord {
    var formattedValue: String {
        switch category {
        case .strength:
            return String(format: "%.1f", value)
        case .endurance:
            if unit.contains("min") || unit == "min/km" {
                let minutes = Int(value)
                let seconds = Int((value - Double(minutes)) * 60)
                return String(format: "%d:%02d", minutes, seconds)
            }
            return String(format: "%.1f", value)
        case .volume:
            return "\(Int(value))"
        }
    }
    
    var improvementText: String? {
        guard let improvement = improvement else { return nil }
        let sign = improvement > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", improvement))%"
    }
    
    var notes: String? {
        // Since DetailedPRRecord doesn't have notes, return nil
        return nil
    }
}

struct PRHistoryDetailView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(UnitSettings.self) var unitSettings
    @Query private var users: [User]
    
    @State private var selectedCategory: AnalyticsService.PRCategory = .strength
    @State private var selectedTimeRange: TimeFilter = .all
    @State private var searchText = ""
    @State private var analyticsService: AnalyticsService?
    
    private var currentUser: User? {
        users.first
    }
    
    enum TimeFilter: String, CaseIterable {
        case thisWeek = "this_week"
        case thisMonth = "this_month"
        case last3Months = "last_3_months"
        case thisYear = "this_year"
        case all = "all_time"
        
        var displayName: String {
            switch self {
            case .thisWeek: return "analytics.this_week".localized
            case .thisMonth: return "analytics.this_month".localized
            case .last3Months: return "analytics.last_3_months".localized
            case .thisYear: return "analytics.this_year".localized
            case .all: return "analytics.all_time".localized
            }
        }
    }
    
    private func setupAnalyticsService() {
        if analyticsService == nil {
            analyticsService = AnalyticsService(modelContext: modelContext)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with stats
                headerSection
                
                // Filters
                filterSection
                
                // PR List
                if filteredPRRecords.isEmpty {
                    EmptyStateView(
                        systemImage: "trophy",
                        title: "analytics.no_prs_title".localized,
                        message: "analytics.no_prs_message".localized,
                        primaryTitle: "training.start_workout".localized,
                        primaryAction: { }
                    )
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: theme.spacing.s) {
                            ForEach(filteredPRRecords) { record in
                                PRRecordRow(record: record)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("analytics.personal_records".localized)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "analytics.search_exercises".localized)
        .onAppear {
            setupAnalyticsService()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: theme.spacing.m) {
            HStack(spacing: theme.spacing.l) {
                PRStatCard(
                    title: "analytics.total_prs".localized,
                    value: "\(allPRRecords.count)",
                    icon: "trophy.fill",
                    color: .orange
                )
                
                PRStatCard(
                    title: "analytics.this_month".localized,
                    value: "\(thisMonthPRs)",
                    icon: "calendar",
                    color: .blue
                )
                
                PRStatCard(
                    title: "analytics.recent_streak".localized,
                    value: "\(currentStreak)",
                    icon: "flame.fill",
                    color: .red
                )
            }
            
            Divider()
                .background(theme.colors.border.opacity(0.3))
        }
        .padding()
        .background(theme.colors.backgroundSecondary.opacity(0.3))
    }
    
    private var filterSection: some View {
        VStack(spacing: theme.spacing.s) {
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.s) {
                    ForEach(AnalyticsService.PRCategory.allCases, id: \.self) { category in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedCategory = category
                            }
                        }) {
                            HStack(spacing: theme.spacing.xs) {
                                Image(systemName: category.icon)
                                    .font(.caption)
                                Text(category.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(selectedCategory == category ? .white : theme.colors.textSecondary)
                            .padding(.horizontal, theme.spacing.m)
                            .padding(.vertical, theme.spacing.s)
                            .background(
                                selectedCategory == category ? 
                                category.color : 
                                theme.colors.backgroundSecondary
                            )
                            .cornerRadius(theme.radius.m)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            // Time filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.s) {
                    ForEach(TimeFilter.allCases, id: \.self) { filter in
                        Button(filter.displayName) {
                            selectedTimeRange = filter
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(selectedTimeRange == filter ? theme.colors.accent : theme.colors.textSecondary)
                        .padding(.horizontal, theme.spacing.s)
                        .padding(.vertical, 4)
                        .background(selectedTimeRange == filter ? theme.colors.accent.opacity(0.1) : Color.clear)
                        .cornerRadius(theme.radius.s)
                    }
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom, theme.spacing.s)
        .background(theme.colors.backgroundPrimary)
    }
    
    // MARK: - Data Properties
    
    private var allPRRecords: [PRRecord] {
        guard let analyticsService = analyticsService,
              let user = currentUser else { return [] }
        
        return analyticsService.getPRsByCategory(for: user, category: selectedCategory, limit: 100)
    }
    
    private var filteredPRRecords: [PRRecord] {
        var filtered = allPRRecords
        
        // Apply time filter
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeRange {
        case .thisWeek:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            filtered = filtered.filter { $0.date >= startOfWeek }
        case .thisMonth:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            filtered = filtered.filter { $0.date >= startOfMonth }
        case .last3Months:
            let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now) ?? now
            filtered = filtered.filter { $0.date >= threeMonthsAgo }
        case .thisYear:
            let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
            filtered = filtered.filter { $0.date >= startOfYear }
        case .all:
            break
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { 
                $0.exerciseName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered.sorted { $0.date > $1.date }
    }
    
    private var thisMonthPRs: Int {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        return allPRRecords.filter { $0.date >= startOfMonth }.count
    }
    
    private var currentStreak: Int {
        guard let analyticsService = analyticsService,
              let user = currentUser else { return 0 }
        
        // Get recent PRs from all categories for streak calculation
        let allRecentPRs = AnalyticsService.PRCategory.allCases.flatMap { category in
            analyticsService.getPRsByCategory(for: user, category: category, limit: 50)
        }
        
        // Calculate streak based on consecutive days with PRs
        let sortedPRs = allRecentPRs.sorted { $0.date > $1.date }
        let calendar = Calendar.current
        var streak = 0
        var lastPRDate: Date?
        
        for pr in sortedPRs {
            let prDay = calendar.startOfDay(for: pr.date)
            
            if let lastDate = lastPRDate {
                let daysBetween = calendar.dateComponents([.day], from: prDay, to: lastDate).day ?? 0
                if daysBetween > 7 { // More than a week gap breaks the streak
                    break
                }
            }
            
            if lastPRDate == nil || !calendar.isDate(prDay, inSameDayAs: lastPRDate!) {
                streak += 1
                lastPRDate = prDay
            }
        }
        
        return streak
    }
}

// MARK: - Supporting Components

struct PRStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: theme.spacing.xs) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, theme.spacing.s)
    }
}


struct PRRecordRow: View {
    let record: PRRecord
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: theme.spacing.m) {
            // Category icon and timeline
            VStack(spacing: 0) {
                Circle()
                    .fill(record.isRecent ? record.category.color : theme.colors.textSecondary.opacity(0.5))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(theme.colors.cardBackground, lineWidth: 2)
                    )
            }
            
            // Content
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(record.exerciseName)
                            .font(theme.typography.body)
                            .fontWeight(.medium)
                            .foregroundColor(theme.colors.textPrimary)
                        
                        Text(formatDate(record.date))
                            .font(.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(record.formattedValue) \(record.unit)")
                            .font(theme.typography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(record.category.color)
                        
                        HStack(spacing: theme.spacing.xs) {
                            if let improvementText = record.improvementText {
                                Text(improvementText)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(theme.colors.success)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(theme.colors.success.opacity(0.1))
                                    .cornerRadius(4)
                            }
                            
                            if record.isRecent {
                                Text("common.new".localized)
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(record.category.color)
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                
                if let notes = record.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(theme.colors.textTertiary)
                        .italic()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(theme.spacing.m)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
        .cardStyle()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "common.today".localized
        } else if calendar.isDateInYesterday(date) {
            return "common.yesterday".localized
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "d MMM"
            return formatter.string(from: date)
        } else {
            formatter.dateFormat = "d MMM yy"
            return formatter.string(from: date)
        }
    }
}

#Preview {
    PRHistoryDetailView()
        .environment(ThemeManager())
        .environment(UnitSettings.shared)
        .modelContainer(for: [User.self], inMemory: true)
}