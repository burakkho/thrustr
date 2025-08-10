import SwiftUI
import SwiftData

struct GoalTrackingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @Query private var goals: [Goal]
    
    @State private var showingAddGoal = false
    @State private var selectedGoalType: GoalType = .weight
    
    private var currentUser: User? {
        users.first
    }
    
    private var activeGoals: [Goal] {
        goals.filter { !$0.isCompleted && !$0.isExpired }
    }
    
    private var completedGoals: [Goal] {
        goals.filter { $0.isCompleted }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Section
                GoalTrackingHeaderSection(
                    activeCount: activeGoals.count,
                    completedCount: completedGoals.count
                )
                
                // Quick Stats
                QuickGoalStats(goals: goals, user: currentUser)
                
                // Active Goals Section
                if !activeGoals.isEmpty {
                    ActiveGoalsSection(goals: activeGoals)
                }
                
                // Add Goal Section
                AddGoalSection(showingAddGoal: $showingAddGoal)
                
                // Completed Goals Section
                if !completedGoals.isEmpty {
                    CompletedGoalsSection(goals: completedGoals)
                }
                
                // Goal Tips Section
                GoalTipsSection()
            }
            .padding()
        }
        .navigationTitle("Hedef Takibi")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingAddGoal) {
            AddGoalView(selectedGoalType: $selectedGoalType)
        }
    }
}

// MARK: - Header Section
struct GoalTrackingHeaderSection: View {
    let activeCount: Int
    let completedCount: Int
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("Hedef Takibi")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Hedeflerini belirle ve ilerlemenizi takip et")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("\(activeCount)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("Aktif")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("\(completedCount)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("Tamamlanan")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Quick Goal Stats (FIXED)
struct QuickGoalStats: View {
    let goals: [Goal]
    let user: User?
    
    private var averageProgress: Double {
        let activeGoals = goals.filter { !$0.isCompleted && !$0.isExpired }
        guard !activeGoals.isEmpty else { return 0 }
        return activeGoals.map { $0.progressPercentage }.reduce(0, +) / Double(activeGoals.count)
    }
    
    private var daysUntilNextDeadline: Int {
        let activeGoalsWithDeadline = goals.filter { !$0.isCompleted && !$0.isExpired && $0.deadline != nil }
        guard let nextDeadline = activeGoalsWithDeadline.compactMap({ $0.deadline }).min() else { return 0 }
        return Calendar.current.dateComponents([.day], from: Date(), to: nextDeadline).day ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Özet")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickStatCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Ortalama İlerleme",
                    value: "\(Int(averageProgress))%",
                    subtitle: "ilerleme",
                    color: .blue
                )
                
                QuickStatCard(
                    icon: "clock.fill",
                    title: "Sonraki Deadline",
                    value: daysUntilNextDeadline > 0 ? "\(daysUntilNextDeadline) gün" : "Yok",
                    subtitle: "kalan süre",
                    color: .orange
                )
                
                QuickStatCard(
                    icon: "checkmark.circle.fill",
                    title: "Bu Ay Tamamlanan",
                    value: "\(goalsCompletedThisMonth)",
                    subtitle: "hedef",
                    color: .green
                )
                
                QuickStatCard(
                    icon: "target",
                    title: "Başarı Oranı",
                    value: "\(Int(successRate))%",
                    subtitle: "başarı",
                    color: .purple
                )
            }
        }
    }
    
    private var goalsCompletedThisMonth: Int {
        let thisMonth = Calendar.current.dateInterval(of: .month, for: Date())
        return goals.filter { goal in
            guard let completedDate = goal.completedDate,
                  let monthInterval = thisMonth else { return false }
            return monthInterval.contains(completedDate)
        }.count
    }
    
    private var successRate: Double {
        let completedGoals = goals.filter { $0.isCompleted }.count
        let totalGoals = goals.count
        return totalGoals > 0 ? Double(completedGoals) / Double(totalGoals) * 100 : 0
    }
}

// MARK: - Active Goals Section
struct ActiveGoalsSection: View {
    let goals: [Goal]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Aktif Hedefler")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 12) {
                ForEach(goals, id: \.id) { goal in
                    GoalCard(goal: goal)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - Goal Card (FIXED)
struct GoalCard: View {
    let goal: Goal
    
    // Convert String to GoalType enum
    private var goalType: GoalType {
        GoalType(rawValue: goal.type) ?? .weight
    }
    
    private var daysRemaining: Int {
        guard let deadline = goal.deadline else { return 0 }
        return Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
    }
    
    private var isUrgent: Bool {
        daysRemaining <= 7 && daysRemaining > 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: goalType.icon)
                    .font(.title2)
                    .foregroundColor(goalType.color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(goal.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if goal.deadline != nil {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(daysRemaining)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(isUrgent ? .red : .secondary)
                        
                        Text("gün kaldı")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Progress Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("İlerleme")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(Int(goal.progressPercentage * 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(goalType.color)
                }
                
                ProgressView(value: goal.progressPercentage, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: goalType.color))
                    .scaleEffect(x: 1, y: 1.5)
                
                HStack {
                    Text("\(formatValue(goal.currentValue)) / \(formatValue(goal.targetValue)) \(goal.unit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if goal.progressPercentage >= 1.0 {
                        Text("Tamamlandı! 🎉")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding()
        .background(goal.progressPercentage >= 1.0 ? Color.green.opacity(0.1) : Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isUrgent ? Color.red.opacity(0.5) : Color.clear, lineWidth: 2)
        )
    }
    
    private func formatValue(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }
}

// MARK: - Add Goal Section
struct AddGoalSection: View {
    @Binding var showingAddGoal: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Yeni Hedef Ekle")
                .font(.headline)
                .fontWeight(.semibold)
            
            Button {
                showingAddGoal = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text("Hedef Ekle")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
        }
    }
}

// MARK: - Completed Goals Section
struct CompletedGoalsSection: View {
    let goals: [Goal]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tamamlanan Hedefler")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 8) {
                ForEach(goals.prefix(5), id: \.id) { goal in
                    CompletedGoalRow(goal: goal)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - Completed Goal Row (FIXED)
struct CompletedGoalRow: View {
    let goal: Goal
    
    // Convert String to GoalType enum
    private var goalType: GoalType {
        GoalType(rawValue: goal.type) ?? .weight
    }
    
    var body: some View {
        HStack {
            Image(systemName: goalType.icon)
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(goal.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough()
                    .foregroundColor(.secondary)
                
                if let completedDate = goal.completedDate {
                    Text("Tamamlandı: \(formatDate(completedDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text("✅")
                .font(.title3)
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "tr")
        return formatter.string(from: date)
    }
}

// MARK: - Goal Tips Section
struct GoalTipsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hedef Belirleme İpuçları")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                GoalTipRow(
                    icon: "target",
                    title: "SMART Hedefler",
                    description: "Spesifik, Ölçülebilir, Ulaşılabilir, Gerçekçi ve Zamanlı hedefler belirle"
                )
                
                GoalTipRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Küçük Adımlar",
                    description: "Büyük hedefleri küçük, yönetilebilir parçalara böl"
                )
                
                GoalTipRow(
                    icon: "calendar.badge.checkmark",
                    title: "Düzenli Takip",
                    description: "İlerlemenizi düzenli olarak kontrol edin ve gerektiğinde ayarlama yapın"
                )
                
                GoalTipRow(
                    icon: "heart.fill",
                    title: "Motivasyon",
                    description: "Başarılarınızı kutlayın ve kendinizi ödüllendirin"
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

struct GoalTipRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Add Goal View (FIXED)
struct AddGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Binding var selectedGoalType: GoalType
    @State private var title = ""
    @State private var description = ""
    @State private var targetValue = ""
    @State private var hasDeadline = false
    @State private var deadline = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days from now
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "target")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Yeni Hedef Ekle")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    // Goal Type Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Hedef Türü")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(GoalType.allCases, id: \.self) { type in
                                Button {
                                    selectedGoalType = type
                                } label: {
                                    VStack(spacing: 8) {
                                        Image(systemName: type.icon)
                                            .font(.title2)
                                            .foregroundColor(selectedGoalType == type ? .white : type.color)
                                        
                                        Text(type.displayName)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(selectedGoalType == type ? .white : .primary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(selectedGoalType == type ? type.color : Color(.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }
                    
                    // Goal Details
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hedef Başlığı")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("Örn: 5 kg vermek", text: $title)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Açıklama")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("Hedef hakkında detaylar", text: $description, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hedef Değer")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            HStack {
                                TextField("0", text: $targetValue)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                Text(selectedGoalType.unit)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(width: 60, alignment: .leading)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Son Tarih Belirle", isOn: $hasDeadline)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            if hasDeadline {
                                DatePicker("Son Tarih", selection: $deadline, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
                .padding()
            }
            .navigationTitle("Hedef Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        saveGoal()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }
    
    private var isFormValid: Bool {
        !title.isEmpty && !targetValue.isEmpty && Double(targetValue.replacingOccurrences(of: ",", with: ".")) != nil
    }
    
    private func saveGoal() {
        guard let targetVal = Double(targetValue.replacingOccurrences(of: ",", with: ".")) else { return }
        
        let goal = Goal(
            title: title,
            description: description.isEmpty ? nil : description,
            type: selectedGoalType,  // ← GoalType enum geç
            targetValue: targetVal,
            currentValue: 0,
            deadline: hasDeadline ? deadline : nil
        )
        
        modelContext.insert(goal)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving goal: \(error)")
        }
    }
}

#Preview {
    NavigationView {
        GoalTrackingView()
    }
}
