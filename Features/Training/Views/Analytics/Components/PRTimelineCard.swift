import SwiftUI
import SwiftData

struct PRTimelineCard: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var unitSettings: UnitSettings
    
    let user: User
    @State private var selectedCategory: PRCategory = .strength
    @State private var prRecords: [PRRecord] = []
    @State private var isLoading = false
    
    enum PRCategory: String, CaseIterable {
        case strength = "strength"
        case endurance = "endurance" 
        case volume = "volume"
        
        var displayName: String {
            switch self {
            case .strength: return "Kuvvet"
            case .endurance: return "Dayanıklılık"
            case .volume: return "Hacim"
            }
        }
        
        var icon: String {
            switch self {
            case .strength: return "dumbbell.fill"
            case .endurance: return "heart.fill"
            case .volume: return "chart.bar.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .strength: return .orange
            case .endurance: return .red
            case .volume: return .blue
            }
        }
    }
    
    struct PRRecord: Identifiable {
        let id = UUID()
        let exerciseName: String
        let value: Double
        let unit: String
        let date: Date
        let category: PRCategory
        let improvement: Double? // % improvement from previous
        let isRecent: Bool // Within last 7 days
        
        var formattedValue: String {
            switch category {
            case .strength:
                return "\(Int(value))"
            case .endurance:
                return String(format: "%.1f", value)
            case .volume:
                return "\(Int(value))"
            }
        }
        
        var improvementText: String? {
            guard let improvement = improvement else { return nil }
            return improvement > 0 ? "+\(String(format: "%.1f", improvement))%" : nil
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            headerSection
            categorySelector
            
            if isLoading {
                loadingState
            } else if prRecords.isEmpty {
                emptyPRState
            } else {
                prTimeline
                summaryStats
            }
        }
        .padding(theme.spacing.m)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.l)
        .shadow(color: theme.shadows.card, radius: 4, y: 2)
        .onAppear {
            loadPRData()
        }
        .onChange(of: selectedCategory) { _, _ in
            loadPRData()
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("🏆 Personal Records")
                    .font(theme.typography.headline)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.textPrimary)
                
                Text("Recent PR Achievement Timeline")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
            
            Spacer()
            
            if !prRecords.isEmpty {
                Text("\(prRecords.count) PR")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.colors.accent.opacity(0.1))
                    .cornerRadius(theme.radius.s)
            }
        }
    }
    
    private var categorySelector: some View {
        HStack(spacing: 8) {
            ForEach(PRCategory.allCases, id: \.self) { category in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedCategory = category
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: category.icon)
                            .font(.caption)
                        
                        Text(category.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedCategory == category ? .white : theme.colors.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        selectedCategory == category ? 
                        category.color : 
                        theme.colors.backgroundSecondary
                    )
                    .cornerRadius(theme.radius.s)
                }
            }
            
            Spacer()
        }
    }
    
    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.2)
            
            Text("PR verileri yükleniyor...")
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
    
    private var prTimeline: some View {
        VStack(spacing: 0) {
            ForEach(Array(prRecords.enumerated()), id: \.element.id) { index, record in
                prTimelineRow(record: record, isLast: index == prRecords.count - 1)
            }
        }
        .padding(.vertical, theme.spacing.xs)
    }
    
    private func prTimelineRow(record: PRRecord, isLast: Bool) -> some View {
        HStack(spacing: theme.spacing.s) {
            // Timeline connector
            VStack(spacing: 0) {
                Circle()
                    .fill(record.isRecent ? record.category.color : theme.colors.textSecondary)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(theme.colors.cardBackground, lineWidth: 2)
                    )
                
                if !isLast {
                    Rectangle()
                        .fill(theme.colors.border.opacity(0.3))
                        .frame(width: 2, height: 40)
                }
            }
            
            // PR Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(record.exerciseName)
                        .font(theme.typography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                    
                    Spacer()
                    
                    Text(record.formattedValue + " " + record.unit)
                        .font(theme.typography.body)
                        .fontWeight(.bold)
                        .foregroundColor(record.category.color)
                }
                
                HStack {
                    Text(formatPRDate(record.date))
                        .font(.caption)
                        .foregroundColor(theme.colors.textSecondary)
                    
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
                        Text("YENİ")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(record.category.color)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                }
            }
            .padding(.bottom, isLast ? 0 : theme.spacing.s)
        }
    }
    
    private var summaryStats: some View {
        VStack(spacing: theme.spacing.s) {
            Divider()
                .background(theme.colors.border.opacity(0.3))
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bu Ay")
                        .font(.caption)
                        .foregroundColor(theme.colors.textSecondary)
                    
                    Text("\(recentPRCount)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Toplam PR")
                        .font(.caption)
                        .foregroundColor(theme.colors.textSecondary)
                    
                    Text("\(totalPRCount)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.accent)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("En Son")
                        .font(.caption)
                        .foregroundColor(theme.colors.textSecondary)
                    
                    Text(lastPRDate)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.textPrimary)
                }
            }
        }
    }
    
    private var emptyPRState: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy")
                .font(.system(size: 48))
                .foregroundColor(theme.colors.textSecondary.opacity(0.5))
            
            Text("Henüz PR Kaydı Yok")
                .font(theme.typography.headline)
                .foregroundColor(theme.colors.textPrimary)
            
            Text("\(selectedCategory.displayName) kategorisinde PR kırmaya başla")
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("İlk PR'ını Kaydet") {
                // Navigate to appropriate section
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Data Processing
    
    private var recentPRCount: Int {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        return prRecords.filter { $0.date >= startOfMonth }.count
    }
    
    private var totalPRCount: Int {
        // Mock total - in real implementation would query historical PR data
        return max(prRecords.count, user.totalPRsThisMonth)
    }
    
    private var lastPRDate: String {
        guard let lastPR = prRecords.first else { return "--" }
        return formatPRDate(lastPR.date, short: true)
    }
    
    private func loadPRData() {
        isLoading = true
        
        // Generate PR records based on category
        var records: [PRRecord] = []
        
        switch selectedCategory {
        case .strength:
            records = generateStrengthPRs()
        case .endurance:
            records = generateEndurancePRs()
        case .volume:
            records = generateVolumePRs()
        }
        
        // Sort by date descending (newest first)
        prRecords = records.sorted { $0.date > $1.date }
        isLoading = false
    }
    
    private func generateStrengthPRs() -> [PRRecord] {
        var records: [PRRecord] = []
        let calendar = Calendar.current
        
        // Generate strength PRs from user's 1RM data
        let strengthExercises: [(String, Double?, String)] = [
            ("Back Squat", user.squatOneRM, "kg"),
            ("Bench Press", user.benchPressOneRM, "kg"),
            ("Deadlift", user.deadliftOneRM, "kg"),
            ("Overhead Press", user.overheadPressOneRM, "kg"),
            ("Pull-up", user.pullUpOneRM, "kg")
        ]
        
        for (index, (name, value, unit)) in strengthExercises.enumerated() {
            guard let prValue = value, prValue > 0 else { continue }
            
            // Simulate PR dates over the last few months
            let daysAgo = index * 7 + Int.random(in: 1...14) // Spread over weeks
            let prDate = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            
            // Calculate mock improvement (5-15% from "previous" PR)
            let improvement = Double.random(in: 5.0...15.0)
            
            records.append(PRRecord(
                exerciseName: name,
                value: prValue,
                unit: unit,
                date: prDate,
                category: .strength,
                improvement: improvement,
                isRecent: calendar.isDate(prDate, equalTo: Date(), toGranularity: .weekOfYear)
            ))
        }
        
        return records
    }
    
    private func generateEndurancePRs() -> [PRRecord] {
        var records: [PRRecord] = []
        let calendar = Calendar.current
        
        // Generate endurance PRs from cardio data
        let enduranceMetrics: [(String, Double?, String, Double?)] = [
            ("5K Best Time", calculateBest5KTime(), "min", nil),
            ("10K Best Time", calculateBest10KTime(), "min", nil),
            ("Longest Run", user.longestRun, "km", Double.random(in: 8.0...12.0)),
            ("Best Average Pace", calculateBestPace(), "min/km", Double.random(in: 3.0...8.0)),
            ("Max Distance Week", calculateMaxWeeklyDistance(), "km", Double.random(in: 15.0...25.0))
        ]
        
        for (index, (name, value, unit, mockImprovement)) in enduranceMetrics.enumerated() {
            guard let prValue = value, prValue > 0 else { continue }
            
            let daysAgo = index * 10 + Int.random(in: 2...21)
            let prDate = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            
            records.append(PRRecord(
                exerciseName: name,
                value: prValue,
                unit: unit,
                date: prDate,
                category: .endurance,
                improvement: mockImprovement,
                isRecent: calendar.isDate(prDate, equalTo: Date(), toGranularity: .weekOfYear)
            ))
        }
        
        return records
    }
    
    private func generateVolumePRs() -> [PRRecord] {
        var records: [PRRecord] = []
        let calendar = Calendar.current
        
        // Generate volume PRs from user stats
        let volumeMetrics: [(String, Double?, String, Double?)] = [
            ("Most Sets in Day", Double(user.maxSetsInSingleWorkout), "sets", Double.random(in: 10.0...20.0)),
            ("Weekly Volume", calculateWeeklyVolume(), "kg", Double.random(in: 12.0...18.0)),
            ("Most Reps Single Set", Double(user.maxRepsInSingleSet), "reps", Double.random(in: 5.0...15.0)),
            ("Longest Workout", user.longestWorkoutDuration / 60.0, "min", Double.random(in: 8.0...15.0)),
            ("Sessions This Month", Double(user.totalWorkouts), "sessions", Double.random(in: 20.0...30.0))
        ]
        
        for (index, (name, value, unit, mockImprovement)) in volumeMetrics.enumerated() {
            guard let prValue = value, prValue > 0 else { continue }
            
            let daysAgo = index * 8 + Int.random(in: 3...18)
            let prDate = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            
            records.append(PRRecord(
                exerciseName: name,
                value: prValue,
                unit: unit,
                date: prDate,
                category: .volume,
                improvement: mockImprovement,
                isRecent: calendar.isDate(prDate, equalTo: Date(), toGranularity: .weekOfYear)
            ))
        }
        
        return records
    }
    
    // MARK: - Helper Calculations
    
    private func calculateBest5KTime() -> Double? {
        // Mock 5K time based on user's cardio experience
        guard user.totalCardioSessions > 0 else { return nil }
        let baseTime = 30.0 // 30 minutes base
        let experienceBonus = min(Double(user.totalCardioSessions) * 0.2, 8.0)
        return max(baseTime - experienceBonus, 18.0) // 18-30 minute range
    }
    
    private func calculateBest10KTime() -> Double? {
        guard let time5K = calculateBest5KTime() else { return nil }
        return time5K * 2.1 // ~2.1x multiplier for 10K
    }
    
    private func calculateBestPace() -> Double? {
        guard user.totalCardioDistance > 0 && user.totalCardioTime > 0 else { return nil }
        let avgPace = (user.totalCardioTime / 60.0) / (user.totalCardioDistance / 1000.0)
        return max(avgPace * 0.85, 3.5) // 15% improvement from average, min 3:30/km
    }
    
    private func calculateMaxWeeklyDistance() -> Double? {
        guard user.totalCardioDistance > 0 else { return nil }
        // Estimate max weekly distance as 1.3x of average weekly
        let avgWeekly = user.totalCardioDistance / 1000.0 / 12.0 // Assume 12 weeks of data
        return avgWeekly * 1.3
    }
    
    private func calculateWeeklyVolume() -> Double? {
        // Estimate weekly volume from total lift stats
        guard user.totalWorkouts > 0 else { return nil }
        let avgSessionVolume = user.totalVolumeLifted / Double(user.totalWorkouts)
        let weeklyFrequency = 3.5 // Assume 3-4 sessions per week
        return avgSessionVolume * weeklyFrequency
    }
    
    private func formatPRDate(_ date: Date, short: Bool = false) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Bugün"
        } else if calendar.isDateInYesterday(date) {
            return "Dün"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else if short {
            if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
                return "\(calendar.component(.day, from: date)) \(calendar.shortMonthSymbols[calendar.component(.month, from: date) - 1])"
            } else {
                return "\(calendar.component(.month, from: date))/\(calendar.component(.year, from: date) % 100)"
            }
        } else {
            if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
                formatter.dateFormat = "d MMM"
            } else {
                formatter.dateFormat = "d MMM yy"
            }
            return formatter.string(from: date)
        }
    }
}
