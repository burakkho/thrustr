import SwiftUI
import SwiftData

struct NavyMethodCalculatorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(UnitSettings.self) var unitSettings
    @State private var viewModel = NavyMethodCalculatorViewModel()

    let user: User?
    @State private var showingSaveSuccessToast = false

    init(user: User? = nil) {
        self.user = user
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                NavyMethodHeaderSection()
                
                // Gender Selection
                NavyGenderSection(selectedGender: $viewModel.gender)

                // Input Section
                NavyInputSection(
                    unitSystem: unitSettings.unitSystem,
                    gender: viewModel.gender,
                    age: $viewModel.age,
                    height: $viewModel.height,
                    heightFeet: $viewModel.heightFeet,
                    heightInches: $viewModel.heightInches,
                    waist: $viewModel.waist,
                    neck: $viewModel.neck,
                    hips: $viewModel.hips
                )

                // Calculate Button
                Button {
                    viewModel.calculateBodyFat()
                } label: {
                    Text(ProfileKeys.NavyMethodCalculator.calculate.localized)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isFormValid ? Color.orange : Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!viewModel.isFormValid)
                .padding(.horizontal)

                // Error Message Section
                if let errorMessage = viewModel.errorMessage {
                    ErrorMessageSection(message: errorMessage)
                }

                // Results Section
                if let bodyFat = viewModel.calculatedBodyFat {
                    NavyResultsSection(bodyFat: bodyFat, gender: viewModel.gender)
                    
                    // Save to Profile Button
                    if user != nil {
                        saveToProfileButton
                    }
                }
                
                // Body Fat Scale Section
                BodyFatScaleSection(gender: viewModel.gender)
                
                
                // Info Section
                NavyInfoSection()
            }
            .padding()
        }
        .navigationTitle(ProfileKeys.NavyMethodCalculator.title.localized)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button(CommonKeys.Onboarding.Common.close.localized) { dismiss() })
        .background(Color(.systemGroupedBackground))
        .onAppear {
            // Initialize with modern NVVM pattern and prefill user data
            viewModel.prefillFromUser(user)
        }
        .overlay(
            Group {
                if showingSaveSuccessToast {
                    ToastView(
                        text: ProfileKeys.Messages.measurementsSaved.localized, 
                        icon: "checkmark.circle.fill"
                    )
                        .padding(.top, 50)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showingSaveSuccessToast = false
                            }
                        }
                }
            }, alignment: .top
        )
    }
    
    // MARK: - UI Components
    
    private var saveToProfileButton: some View {
        Button {
            if let user = user {
                viewModel.saveToProfile(user: user, modelContext: modelContext)
                showingSaveSuccessToast = true
            }
        } label: {
            HStack {
                Image(systemName: "person.crop.circle")
                Text(ProfileKeys.Messages.saveToProfile.localized)
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.orange)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
    }
}

// MARK: - Header Section
struct NavyMethodHeaderSection: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "percent")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("Navy Method")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(CommonKeys.Calculator.navyMethodSubtitle.localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Gender Selection Section
struct NavyGenderSection: View {
    @Binding var selectedGender: NavyGender
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(CommonKeys.PersonalInfoExtended.gender.localized)
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                ForEach(NavyGender.allCases, id: \.self) { gender in
                    Button {
                        selectedGender = gender
                    } label: {
                        HStack {
                            Image(systemName: gender.icon)
                                .font(.title2)
                                .foregroundColor(selectedGender == gender ? .white : gender.color)
                            
                            Text(gender.displayName)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(selectedGender == gender ? .white : .primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedGender == gender ? gender.color : Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - Input Section
struct NavyInputSection: View {
    let unitSystem: UnitSystem
    let gender: NavyGender
    @Binding var age: String
    @Binding var height: String
    @Binding var heightFeet: String
    @Binding var heightInches: String
    @Binding var waist: String
    @Binding var neck: String
    @Binding var hips: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(CommonKeys.Calculator.measurementsSection.localized)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // Age Input
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        Text(CommonKeys.Calculator.ageLabel.localized)
                            .fontWeight(.medium)
                    }
                    
                    TextField("25", text: $age)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title3)
                }
                
                // Height Input
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "ruler.fill")
                            .foregroundColor(.green)
                        Text(unitSystem == .metric ? CommonKeys.PersonalInfoExtended.height.localized + " (cm)" : CommonKeys.PersonalInfoExtended.height.localized + " (ft'in\")")
                            .fontWeight(.medium)
                    }
                    
                    if unitSystem == .metric {
                        TextField("175", text: $height)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.title3)
                    } else {
                        // Imperial: feet and inches input
                        HStack(spacing: 12) {
                            VStack {
                                Text("Feet")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("5", text: $heightFeet)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.title3)
                            }
                            VStack {
                                Text(CommonKeys.Calculator.inchesLabel.localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("10", text: $heightInches)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.title3)
                            }
                        }
                    }
                }
                
                // Waist Input
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "oval.fill")
                            .foregroundColor(.orange)
                        Text(unitSystem == .metric ? CommonKeys.Calculator.waistCircumference.localized + " (cm)" : CommonKeys.Calculator.waistCircumference.localized + " (in)")
                            .fontWeight(.medium)
                    }
                    
                    TextField(unitSystem == .metric ? "85" : "33", text: $waist)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title3)
                }
                
                // Neck Input
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "person.crop.circle")
                            .foregroundColor(.purple)
                        Text(unitSystem == .metric ? CommonKeys.Calculator.neckCircumference.localized + " (cm)" : CommonKeys.Calculator.neckCircumference.localized + " (in)")
                            .fontWeight(.medium)
                    }
                    
                    TextField(unitSystem == .metric ? "38" : "15", text: $neck)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title3)
                }
                
                // Hips Input (only for females)
                if gender == .female {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "circle.fill")
                                .foregroundColor(.pink)
                            Text(unitSystem == .metric ? CommonKeys.Calculator.hipCircumference.localized + " (cm)" : CommonKeys.Calculator.hipCircumference.localized + " (in)")
                                .fontWeight(.medium)
                        }
                        
                        TextField(unitSystem == .metric ? "95" : "37", text: $hips)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.title3)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - Results Section
struct NavyResultsSection: View {
    let bodyFat: Double
    let gender: NavyGender
    
    private var bodyFatCategory: BodyFatCategory {
        BodyFatCategory.category(for: bodyFat, gender: gender)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(CommonKeys.Calculator.resultsSection.localized)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // Body Fat Result
                VStack(spacing: 8) {
                    Text(CommonKeys.Calculator.bodyFatPercentageTitle.localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(String(format: "%.1f", bodyFat))%")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(bodyFatCategory.color)
                    
                    Text(bodyFatCategory.description)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(bodyFatCategory.color)
                    
                    Text(bodyFatCategory.interpretation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(bodyFatCategory.color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - Body Fat Scale Section
struct BodyFatScaleSection: View {
    let gender: NavyGender
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(gender.displayName) " + CommonKeys.Calculator.bodyFatScaleTitle.localized)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(BodyFatCategory.allCases, id: \.self) { category in
                    BodyFatScaleRow(category: category, gender: gender)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

struct BodyFatScaleRow: View {
    let category: BodyFatCategory
    let gender: NavyGender
    
    var body: some View {
        HStack {
            Circle()
                .fill(category.color)
                .frame(width: 12, height: 12)
            
            Text(category.description)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(category.range(for: gender))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Info Section
struct NavyInfoSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(CommonKeys.Calculator.aboutSection.localized)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                NavyInfoRow(
                    icon: "info.circle.fill",
                    title: CommonKeys.Calculator.reliabilityTitle.localized,
                    description: CommonKeys.Calculator.reliabilityDescription.localized
                )
                
                NavyInfoRow(
                    icon: "ruler.fill",
                    title: CommonKeys.Calculator.accuracyTitle.localized,
                    description: CommonKeys.Calculator.accuracyDescription.localized
                )
                
                NavyInfoRow(
                    icon: "exclamationmark.triangle.fill",
                    title: CommonKeys.Calculator.importantNoteTitle.localized,
                    description: CommonKeys.Calculator.importantNoteDescription.localized
                )
                
                NavyInfoRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: CommonKeys.Calculator.trackingTitle.localized,
                    description: CommonKeys.Calculator.trackingDescription.localized
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

struct NavyInfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.orange)
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



#Preview {
    NavigationStack {
        NavyMethodCalculatorView(user: nil)
    }
    .modelContainer(for: [User.self], inMemory: true)
    .environment(UnitSettings.shared)
}
