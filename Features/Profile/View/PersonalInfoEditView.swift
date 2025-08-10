import SwiftUI
import SwiftData

struct PersonalInfoEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let user: User?
    
    @State private var name: String = ""
    @State private var age: String = ""
    @State private var height: String = ""
    @State private var currentWeight: String = ""
    @State private var selectedGender: Gender = .male
    @State private var selectedFitnessGoal: FitnessGoal = .maintain
    @State private var selectedActivityLevel: ActivityLevel = .moderate
    
    @State private var showingSaveAlert = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    HeaderSection()
                    
                    // Basic Info Section
                    BasicInfoSection(
                        name: $name,
                        age: $age,
                        selectedGender: $selectedGender
                    )
                    
                    // Physical Measurements Section
                    PhysicalMeasurementsSection(
                        height: $height,
                        currentWeight: $currentWeight
                    )
                    
                    // Goals Section
                    GoalsSection(
                        selectedFitnessGoal: $selectedFitnessGoal,
                        selectedActivityLevel: $selectedActivityLevel
                    )
                    
                    // Calculated Values Preview
                    if let user = user {
                        CalculatedValuesPreview(
                            user: user,
                            fitnessGoal: selectedFitnessGoal,
                            activityLevel: selectedActivityLevel,
                            weight: Double(currentWeight) ?? user.currentWeight,
                            height: Double(height) ?? user.height,
                            age: Int(age) ?? user.age,
                            gender: selectedGender
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("personal_info.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("personal_info.cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("personal_info.save".localized) {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .disabled(isLoading || !isFormValid)
                }
            }
            .background(Color(.systemGroupedBackground))
        }
        .onAppear {
            loadUserData()
        }
        .alert("personal_info.info_updated".localized, isPresented: $showingSaveAlert) {
            Button("common.ok".localized) {
                dismiss()
            }
        } message: {
            Text("personal_info.update_success".localized)
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty &&
        !age.isEmpty &&
        !height.isEmpty &&
        !currentWeight.isEmpty &&
        (Int(age) ?? 0) > 0 &&
        (Double(height) ?? 0) > 0 &&
        (Double(currentWeight) ?? 0) > 0
    }
    
    private func loadUserData() {
        guard let user = user else { return }
        
        name = user.name
        age = String(user.age)
        height = String(Int(user.height))
        currentWeight = String(Int(user.currentWeight))
        selectedGender = user.genderEnum
        selectedFitnessGoal = user.fitnessGoalEnum
        selectedActivityLevel = user.activityLevelEnum
    }
    
    private func saveChanges() {
        guard let user = user, isFormValid else { return }
        
        isLoading = true
        
        // Update user data
        user.name = name
        user.age = Int(age) ?? user.age
        user.height = Double(height) ?? user.height
        user.currentWeight = Double(currentWeight) ?? user.currentWeight
        user.gender = selectedGender.rawValue
        user.fitnessGoal = selectedFitnessGoal.rawValue
        user.activityLevel = selectedActivityLevel.rawValue
        
        // Recalculate metrics
        user.calculateMetrics()
        
        // Save to database
        do {
            try modelContext.save()
            isLoading = false
            showingSaveAlert = true
        } catch {
            isLoading = false
            print("Error saving user data: \(error)")
        }
    }
}

// MARK: - Header Section
struct HeaderSection: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("personal_info.update_title".localized)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text("personal_info.update_subtitle".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Basic Info Section
struct BasicInfoSection: View {
    @Binding var name: String
    @Binding var age: String
    @Binding var selectedGender: Gender
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "personal_info.basic_info".localized, icon: "info.circle.fill")
            
            VStack(spacing: 12) {
                InputField(
                    title: "personal_info.name".localized,
                    text: $name,
                    placeholder: "personal_info.name_placeholder".localized,
                    icon: "person.fill"
                )
                
                InputField(
                    title: "personal_info.age".localized,
                    text: $age,
                    placeholder: "25",
                    icon: "calendar",
                    keyboardType: .numberPad
                )
                
                GenderSelector(selectedGender: $selectedGender)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Physical Measurements Section
struct PhysicalMeasurementsSection: View {
    @Binding var height: String
    @Binding var currentWeight: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "personal_info.physical_measurements".localized, icon: "ruler.fill")
            
            VStack(spacing: 12) {
                InputField(
                    title: "personal_info.height".localized,
                    text: $height,
                    placeholder: "175",
                    icon: "ruler",
                    keyboardType: .numberPad
                )
                
                InputField(
                    title: "personal_info.current_weight".localized,
                    text: $currentWeight,
                    placeholder: "70",
                    icon: "scalemass",
                    keyboardType: .decimalPad
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Goals Section
struct GoalsSection: View {
    @Binding var selectedFitnessGoal: FitnessGoal
    @Binding var selectedActivityLevel: ActivityLevel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "personal_info.goals_activity".localized, icon: "target")
            
            VStack(spacing: 16) {
                FitnessGoalSelector(selectedGoal: $selectedFitnessGoal)
                ActivityLevelSelector(selectedLevel: $selectedActivityLevel)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Calculated Values Preview
struct CalculatedValuesPreview: View {
    let user: User
    let fitnessGoal: FitnessGoal
    let activityLevel: ActivityLevel
    let weight: Double
    let height: Double
    let age: Int
    let gender: Gender
    
    private var previewBMR: Double {
        // Mifflin-St Jeor formula
        let baseBMR = (10 * weight) + (6.25 * height) - (5 * Double(age))
        return gender == .male ? baseBMR + 5 : baseBMR - 161
    }
    
    private var previewTDEE: Double {
        previewBMR * activityLevel.multiplier
    }
    
    private var previewCalorieGoal: Double {
        previewTDEE * fitnessGoal.calorieMultiplier
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "personal_info.calculated_values".localized, icon: "calculator")
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                CalculatedValueCard(
                    title: "calculators.bmr".localized,
                    value: "\(Int(previewBMR))",
                    unit: "nutrition.units.kcal".localized,
                    subtitle: "personal_info.basal_metabolism".localized,
                    color: .green
                )
                
                CalculatedValueCard(
                    title: "calculators.tdee".localized,
                    value: "\(Int(previewTDEE))",
                    unit: "nutrition.units.kcal".localized,
                    subtitle: "personal_info.daily_expenditure".localized,
                    color: .blue
                )
                
                CalculatedValueCard(
                    title: "personal_info.calorie_goal".localized,
                    value: "\(Int(previewCalorieGoal))",
                    unit: "nutrition.units.kcal".localized,
                    subtitle: fitnessGoal.displayName,
                    color: .orange
                )
                
                CalculatedValueCard(
                    title: "nutrition.dailySummary.protein".localized,
                    value: "\(Int(weight * 2))",
                    unit: "nutrition.units.g".localized,
                    subtitle: "personal_info.daily_target".localized,
                    color: .red
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct CalculatedValueCard: View {
    let title: String
    let value: String
    let unit: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Reusable Components
struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
        }
    }
}

struct InputField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct GenderSelector: View {
    @Binding var selectedGender: Gender
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text("personal_info.gender".localized)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Picker("personal_info.gender".localized, selection: $selectedGender) {
                ForEach(Gender.allCases, id: \.self) { gender in
                    Text(gender.displayName).tag(gender)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
}

struct FitnessGoalSelector: View {
    @Binding var selectedGoal: FitnessGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "target")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text("personal_info.fitness_goal".localized)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            VStack(spacing: 8) {
                ForEach(FitnessGoal.allCases, id: \.self) { goal in
                    GoalOptionRow(
                        goal: goal,
                        isSelected: selectedGoal == goal,
                        action: { selectedGoal = goal }
                    )
                }
            }
        }
    }
}

struct GoalOptionRow: View {
    let goal: FitnessGoal
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(goal.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ActivityLevelSelector: View {
    @Binding var selectedLevel: ActivityLevel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "figure.walk")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text("personal_info.activity_level".localized)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            VStack(spacing: 8) {
                ForEach(ActivityLevel.allCases, id: \.self) { level in
                    ActivityLevelRow(
                        level: level,
                        isSelected: selectedLevel == level,
                        action: { selectedLevel = level }
                    )
                }
            }
        }
    }
}

struct ActivityLevelRow: View {
    let level: ActivityLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(level.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(level.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PersonalInfoEditView(user: nil)
        .modelContainer(for: [User.self], inMemory: true)
}
