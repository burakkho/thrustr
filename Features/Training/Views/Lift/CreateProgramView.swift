import SwiftUI
import SwiftData

struct CreateProgramView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    
    @State private var programName = ""
    @State private var programDescription = ""
    @State private var weeks = 4
    @State private var daysPerWeek = 3
    @State private var level = "beginner"
    @State private var category = "general"
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Program Details") {
                    TextField("Program Name", text: $programName)
                    TextField("Description", text: $programDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Structure") {
                    Stepper("Weeks: \(weeks)", value: $weeks, in: 1...12)
                    Stepper("Days per week: \(daysPerWeek)", value: $daysPerWeek, in: 1...7)
                }
                
                Section("Settings") {
                    Picker("Level", selection: $level) {
                        Text("Beginner").tag("beginner")
                        Text("Intermediate").tag("intermediate")
                        Text("Advanced").tag("advanced")
                    }
                    
                    Picker("Category", selection: $category) {
                        Text("General").tag("general")
                        Text("Strength").tag("strength")
                        Text("Hypertrophy").tag("hypertrophy")
                        Text("Powerlifting").tag("powerlifting")
                    }
                }
            }
            .navigationTitle("Create Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createProgram()
                    }
                    .disabled(programName.isEmpty)
                }
            }
        }
    }
    
    private func createProgram() {
        let program = LiftProgram(
            name: programName,
            description: programDescription.isEmpty ? "Custom program" : programDescription,
            weeks: weeks,
            daysPerWeek: daysPerWeek,
            level: level,
            category: category,
            isCustom: true
        )
        
        modelContext.insert(program)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            Logger.error("Failed to create program: \(error)")
        }
    }
}