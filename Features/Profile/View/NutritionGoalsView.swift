import SwiftUI
import SwiftData

struct NutritionGoalsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(UnitSettings.self) var unitSettings
    
    let user: User
    
    @State private var dailyCalorieGoal: Double
    @State private var dailyProteinGoal: Double
    @State private var dailyCarbGoal: Double
    @State private var dailyFatGoal: Double
    @State private var useCalculatedGoals: Bool = true
    @State private var saveErrorMessage: String? = nil
    
    init(user: User) {
        self.user = user
        self._dailyCalorieGoal = State(initialValue: user.dailyCalorieGoal)
        self._dailyProteinGoal = State(initialValue: user.dailyProteinGoal)
        self._dailyCarbGoal = State(initialValue: user.dailyCarbGoal)
        self._dailyFatGoal = State(initialValue: user.dailyFatGoal)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.xl) {
                    // Header Info
                    VStack(spacing: theme.spacing.s) {
                        Text(NutritionKeys.Goals.setDailyGoals.localized)
                            .font(theme.typography.title3)
                            .fontWeight(.bold)
                            .foregroundColor(theme.colors.textPrimary)
                        
                        Text(NutritionKeys.Goals.personalizeNutrition.localized)
                            .font(theme.typography.body)
                            .foregroundColor(theme.colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, theme.spacing.l)
                    
                    // Calculated vs Manual Toggle
                    VStack(alignment: .leading, spacing: theme.spacing.m) {
                        goalSectionHeader("🎯 " + NutritionKeys.Goals.goalMode.localized, NutritionKeys.Goals.goalModeDesc.localized)
                        
                        VStack(spacing: theme.spacing.s) {
                            Button(action: { 
                                useCalculatedGoals = true
                                recalculateGoals()
                            }) {
                                HStack {
                                    Image(systemName: useCalculatedGoals ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(useCalculatedGoals ? theme.colors.success : theme.colors.textSecondary)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(NutritionKeys.Goals.calculatedGoals.localized)
                                            .font(theme.typography.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(theme.colors.textPrimary)
                                        Text(NutritionKeys.Goals.calculatedGoalsDesc.localized)
                                            .font(theme.typography.caption)
                                            .foregroundColor(theme.colors.textSecondary)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(theme.spacing.m)
                                .background(useCalculatedGoals ? theme.colors.success.opacity(0.1) : theme.colors.cardBackground)
                                .cornerRadius(theme.radius.s)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: { useCalculatedGoals = false }) {
                                HStack {
                                    Image(systemName: !useCalculatedGoals ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(!useCalculatedGoals ? theme.colors.accent : theme.colors.textSecondary)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(NutritionKeys.Goals.customGoals.localized)
                                            .font(theme.typography.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(theme.colors.textPrimary)
                                        Text(NutritionKeys.Goals.customGoalsDesc.localized)
                                            .font(theme.typography.caption)
                                            .foregroundColor(theme.colors.textSecondary)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(theme.spacing.m)
                                .background(!useCalculatedGoals ? theme.colors.accent.opacity(0.1) : theme.colors.cardBackground)
                                .cornerRadius(theme.radius.s)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(theme.spacing.l)
                    .background(theme.colors.cardBackground)
                    .cornerRadius(theme.radius.m)
                    .shadow(color: theme.shadows.card.opacity(0.05), radius: 2)
                    
                    // Macro Goals Section
                    VStack(spacing: theme.spacing.xl) {
                        goalSectionHeader("🍎 " + NutritionKeys.Goals.dailyTargets.localized, NutritionKeys.Goals.dailyTargetsDesc.localized)
                        
                        goalSettingCard(
                            title: NutritionKeys.calories.localized,
                            description: useCalculatedGoals ? NutritionKeys.GoalsDesc.dailyCalorieTarget.localized : "Calculated from macros below",
                            icon: "flame.fill",
                            color: .orange,
                            value: $dailyCalorieGoal,
                            range: 1000...4000,
                            step: 50,
                            suffix: " " + NutritionKeys.Units.kcal.localized,
                            isEnabled: false
                        )
                        
                        goalSettingCard(
                            title: NutritionKeys.CustomFood.protein.localized,
                            description: NutritionKeys.GoalsDesc.dailyProteinTarget.localized,
                            icon: "leaf.fill",
                            color: .red,
                            value: $dailyProteinGoal,
                            range: 50...300,
                            step: 5,
                            suffix: " " + NutritionKeys.Units.g.localized,
                            isEnabled: !useCalculatedGoals
                        )
                        
                        goalSettingCard(
                            title: NutritionKeys.CustomFood.carbs.localized,
                            description: NutritionKeys.GoalsDesc.dailyCarbTarget.localized,
                            icon: "bolt.fill",
                            color: .blue,
                            value: $dailyCarbGoal,
                            range: 50...500,
                            step: 10,
                            suffix: " " + NutritionKeys.Units.g.localized,
                            isEnabled: !useCalculatedGoals
                        )
                        
                        goalSettingCard(
                            title: NutritionKeys.CustomFood.fat.localized,
                            description: NutritionKeys.GoalsDesc.dailyFatTarget.localized,
                            icon: "drop.fill",
                            color: .yellow,
                            value: $dailyFatGoal,
                            range: 30...200,
                            step: 5,
                            suffix: " " + NutritionKeys.Units.g.localized,
                            isEnabled: !useCalculatedGoals
                        )
                    }
                    
                    // Current Macros Distribution
                    if dailyCalorieGoal > 0 {
                        macroDistributionCard
                    }
                    
                    // Save Button
                    Button(action: saveGoals) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                            Text(NutritionKeys.Goals.saveGoals.localized)
                                .font(theme.typography.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(theme.spacing.l)
                        .background(theme.colors.accent)
                        .cornerRadius(theme.radius.m)
                    }
                    .padding(.bottom, theme.spacing.xl)
                }
                .padding(.horizontal, theme.spacing.l)
                .padding(.bottom, theme.spacing.xl)
            }
            .onChange(of: dailyProteinGoal) { _, _ in updateCalculatedCalories() }
            .onChange(of: dailyCarbGoal) { _, _ in updateCalculatedCalories() }
            .onChange(of: dailyFatGoal) { _, _ in updateCalculatedCalories() }
            .navigationTitle(NutritionKeys.Goals.nutritionGoals.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(CommonKeys.Onboarding.Common.cancel.localized) { dismiss() }
                }
            }
        }
        .alert(isPresented: Binding<Bool>(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Alert(
                title: Text(CommonKeys.Onboarding.Common.error.localized),
                message: Text(saveErrorMessage ?? ""),
                dismissButton: .default(Text(CommonKeys.Onboarding.Common.ok.localized))
            )
        }
    }
    
    private var macroDistributionCard: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            goalSectionHeader("📊 " + NutritionKeys.Goals.macroDistribution.localized, NutritionKeys.Goals.macroDistributionDesc.localized)
            
            let proteinCals = dailyProteinGoal * 4
            let carbsCals = dailyCarbGoal * 4
            let fatCals = dailyFatGoal * 9
            let totalCals = proteinCals + carbsCals + fatCals
            
            VStack(spacing: theme.spacing.s) {
                macroPercentageRow(
                    name: NutritionKeys.CustomFood.protein.localized,
                    calories: proteinCals,
                    total: totalCals,
                    color: .red
                )
                macroPercentageRow(
                    name: NutritionKeys.CustomFood.carbs.localized,
                    calories: carbsCals,
                    total: totalCals,
                    color: .blue
                )
                macroPercentageRow(
                    name: NutritionKeys.CustomFood.fat.localized,
                    calories: fatCals,
                    total: totalCals,
                    color: .yellow
                )
            }
        }
        .padding(theme.spacing.l)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
        .shadow(color: theme.shadows.card.opacity(0.05), radius: 2)
    }
    
    private func macroPercentageRow(name: String, calories: Double, total: Double, color: Color) -> some View {
        HStack {
            Text(name)
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textPrimary)
            
            Spacer()
            
            let percentage = total > 0 ? (calories / total * 100) : 0
            Text("\(Int(percentage))%")
                .font(theme.typography.body)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
    
    private func goalSettingCard(
        title: String,
        description: String,
        icon: String,
        color: Color,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        suffix: String,
        isEnabled: Bool = true
    ) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            // Header
            HStack(spacing: theme.spacing.m) {
                ZStack {
                    Circle()
                        .fill(color.opacity(isEnabled ? 0.15 : 0.05))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(isEnabled ? color : theme.colors.textSecondary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(theme.typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isEnabled ? theme.colors.textPrimary : theme.colors.textSecondary)
                    
                    Text(description)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
                
                Spacer()
            }
            
            // Slider and Value
            VStack(spacing: theme.spacing.s) {
                HStack {
                    Text("\(Int(value.wrappedValue))\(suffix)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(isEnabled ? color : theme.colors.textSecondary)
                    Spacer()
                }
                
                Slider(value: value, in: range, step: step)
                    .accentColor(isEnabled ? color : theme.colors.textSecondary)
                    .disabled(!isEnabled)
                
                HStack {
                    Text("\(Int(range.lowerBound))")
                        .font(.caption2)
                        .foregroundColor(theme.colors.textSecondary)
                    Spacer()
                    Text("\(Int(range.upperBound))")
                        .font(.caption2)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
        .padding(theme.spacing.l)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
        .shadow(color: theme.shadows.card.opacity(isEnabled ? 0.05 : 0.02), radius: 2)
    }
    
    private func recalculateGoals() {
        user.calculateMetrics()
        dailyCalorieGoal = user.dailyCalorieGoal
        dailyProteinGoal = user.dailyProteinGoal
        dailyCarbGoal = user.dailyCarbGoal
        dailyFatGoal = user.dailyFatGoal
    }
    
    private var calculatedCaloriesFromMacros: Double {
        return (dailyProteinGoal * 4) + (dailyCarbGoal * 4) + (dailyFatGoal * 9)
    }
    
    private func updateCalculatedCalories() {
        if !useCalculatedGoals {
            dailyCalorieGoal = calculatedCaloriesFromMacros
        }
    }
    
    private func saveGoals() {
        // Update user nutrition goals
        // In custom mode, ensure calories match macros
        if !useCalculatedGoals {
            dailyCalorieGoal = calculatedCaloriesFromMacros
        }
        
        user.dailyCalorieGoal = dailyCalorieGoal
        user.dailyProteinGoal = dailyProteinGoal
        user.dailyCarbGoal = dailyCarbGoal
        user.dailyFatGoal = dailyFatGoal
        
        // Save changes
        do {
            try modelContext.save()
            HapticManager.shared.notification(.success)
            dismiss()
        } catch {
            saveErrorMessage = error.localizedDescription
            HapticManager.shared.notification(.error)
        }
    }
    
    private func goalSectionHeader(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(theme.typography.title3)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)
            Text(subtitle)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: User.self, configurations: config)
    
    let user = User(name: "Test User")
    user.dailyCalorieGoal = 2200
    user.dailyProteinGoal = 120
    user.dailyCarbGoal = 250
    user.dailyFatGoal = 80
    container.mainContext.insert(user)
    
    return NutritionGoalsView(user: user)
        .modelContainer(container)
        .environment(ThemeManager())
        .environment(UnitSettings.shared)
}