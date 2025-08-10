import SwiftUI
import SwiftData

struct BodyMeasurementsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let user: User?
    
    @State private var selectedMeasurement: MeasurementType = .chest
    @State private var measurementValue = ""
    @State private var selectedDate = Date()
    @State private var notes = ""
    @State private var showingAddMeasurement = false
    @State private var showingSuccessAlert = false
    
    // Fixed: Remove date predicates that aren't supported
    @Query(sort: \BodyMeasurement.date, order: .reverse)
    private var allMeasurements: [BodyMeasurement]
    
    @Query(sort: \WeightEntry.date, order: .reverse)
    private var allWeightEntries: [WeightEntry]
    
    // Computed properties for filtering
    private var recentMeasurements: [BodyMeasurement] {
        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        return allMeasurements.filter { $0.date >= sixMonthsAgo }
    }
    
    private var weightEntries: [WeightEntry] {
        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        return allWeightEntries.filter { $0.date >= sixMonthsAgo }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    MeasurementsHeaderSection()
                    
                    // Current Measurements Overview
                    CurrentMeasurementsSection(measurements: recentMeasurements)
                    
                    // Progress Charts Section (Simplified)
                    if !recentMeasurements.isEmpty || !weightEntries.isEmpty {
                        ProgressOverviewSection(
                            measurements: recentMeasurements,
                            weightEntries: weightEntries
                        )
                    }
                    
                    // Recent Measurements List
                    if !recentMeasurements.isEmpty || !weightEntries.isEmpty {
                        RecentEntriesSection(
                            measurements: recentMeasurements,
                            weightEntries: weightEntries
                        )
                    }
                    
                    // Tips Section
                    MeasurementGuideSection()
                }
                .padding()
            }
            .navigationTitle(LocalizationKeys.Measurements.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationKeys.Common.close) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddMeasurement = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
        }
        .sheet(isPresented: $showingAddMeasurement) {
            AddMeasurementView(
                selectedMeasurement: $selectedMeasurement,
                measurementValue: $measurementValue,
                selectedDate: $selectedDate,
                notes: $notes,
                onSave: { saveMeasurement() }
            )
        }
        .alert("body_measurements.measurement_saved".localized, isPresented: $showingSuccessAlert) {
            Button(LocalizationKeys.Common.ok) { }
        } message: {
            Text("body_measurements.saved_message".localized)
        }
    }
    
    private func saveMeasurement() {
        guard let value = Double(measurementValue.replacingOccurrences(of: ",", with: ".")) else { return }
        
        let measurement = BodyMeasurement(
            type: selectedMeasurement.rawValue,
            value: value,
            date: selectedDate,
            notes: notes.isEmpty ? nil : notes
        )
        
        modelContext.insert(measurement)
        
        do {
            try modelContext.save()
            showingSuccessAlert = true
            
            // Reset form
            measurementValue = ""
            notes = ""
            selectedDate = Date()
            showingAddMeasurement = false
        } catch {
            print("Error saving measurement: \(error)")
        }
    }
}

// MARK: - Measurements Header Section
struct MeasurementsHeaderSection: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "ruler.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text(LocalizationKeys.Measurements.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("body_measurements.subtitle".localized)
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

// MARK: - Current Measurements Section
struct CurrentMeasurementsSection: View {
    let measurements: [BodyMeasurement]
    
    private func latestMeasurement(for type: MeasurementType) -> BodyMeasurement? {
        measurements.first { $0.typeEnum == type }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("body_measurements.current_measurements".localized)
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(MeasurementType.allCases, id: \.self) { type in
                    MeasurementCard(
                        type: type,
                        measurement: latestMeasurement(for: type)
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct MeasurementCard: View {
    let type: MeasurementType
    let measurement: BodyMeasurement?
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: type.icon)
                .font(.title2)
                .foregroundColor(type.color)
            
            Text(type.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
            
            if let measurement = measurement {
                Text("\(String(format: "%.1f", measurement.value)) cm")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(type.color)
                
                Text(formatDate(measurement.date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                Text("-- cm")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(LocalizationKeys.Measurements.noMeasurements)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Progress Overview Section (Simplified)
struct ProgressOverviewSection: View {
    let measurements: [BodyMeasurement]
    let weightEntries: [WeightEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("body_measurements.progress_summary".localized)
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ProgressStatCard(
                    title: "body_measurements.total_measurements".localized,
                    value: "\(measurements.count)",
                    subtitle: "body_measurements.last_6_months".localized,
                    color: .blue
                )
                
                ProgressStatCard(
                    title: "body_measurements.weight_entries".localized,
                    value: "\(weightEntries.count)",
                    subtitle: "body_measurements.last_6_months".localized,
                    color: .green
                )
                
                ProgressStatCard(
                    title: "body_measurements.last_measurement".localized,
                    value: latestMeasurementDate,
                    subtitle: LocalizationKeys.Measurements.date,
                    color: .orange
                )
                
                ProgressStatCard(
                    title: "body_measurements.active_tracking".localized,
                    value: "\(activeMeasurementTypes)",
                    subtitle: "body_measurements.measurement_types".localized,
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var latestMeasurementDate: String {
        let latest = measurements.max(by: { $0.date < $1.date })
        guard let date = latest?.date else { return LocalizationKeys.Analytics.noData }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    private var activeMeasurementTypes: Int {
        let types = Set(measurements.map { $0.type })
        return types.count
    }
}

struct ProgressStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Recent Entries Section
struct RecentEntriesSection: View {
    let measurements: [BodyMeasurement]
    let weightEntries: [WeightEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("body_measurements.recent_entries".localized)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // Recent measurements
                ForEach(measurements.prefix(5), id: \.id) { measurement in
                    RecentMeasurementRow(measurement: measurement)
                }
                
                // Recent weight entries
                ForEach(weightEntries.prefix(3), id: \.id) { entry in
                    RecentWeightRow(entry: entry)
                }
                
                if measurements.isEmpty && weightEntries.isEmpty {
                    EmptyStateView()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct RecentMeasurementRow: View {
    let measurement: BodyMeasurement
    
    var body: some View {
        HStack {
            Image(systemName: measurement.typeEnum.icon)
                .font(.title3)
                .foregroundColor(measurement.typeEnum.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(measurement.typeEnum.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(formatDate(measurement.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(String(format: "%.1f", measurement.value)) cm")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(measurement.typeEnum.color)
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct RecentWeightRow: View {
    let entry: WeightEntry
    
    var body: some View {
        HStack {
            Image(systemName: "scalemass.fill")
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizationKeys.Measurements.weight)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(formatDate(entry.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(String(format: "%.1f", entry.weight)) kg")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "ruler.circle")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("body_measurements.no_measurements".localized)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("body_measurements.first_tip".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Measurement Guide Section
struct MeasurementGuideSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("body_measurements.measurement_tips".localized)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                MeasurementTip(
                    icon: "clock.fill",
                    title: "body_measurements.correct_timing".localized,
                    description: "body_measurements.timing_desc".localized,
                    color: .blue
                )
                
                MeasurementTip(
                    icon: "ruler.fill",
                    title: "body_measurements.correct_technique".localized,
                    description: "body_measurements.technique_desc".localized,
                    color: .green
                )
                
                MeasurementTip(
                    icon: "calendar.circle.fill",
                    title: "body_measurements.regular_tracking".localized,
                    description: "body_measurements.tracking_desc".localized,
                    color: .orange
                )
                
                MeasurementTip(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "body_measurements.trend_focus".localized,
                    description: "body_measurements.trend_desc".localized,
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct MeasurementTip: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Add Measurement View
struct AddMeasurementView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedMeasurement: MeasurementType
    @Binding var measurementValue: String
    @Binding var selectedDate: Date
    @Binding var notes: String
    
    let onSave: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("body_measurements.add_new".localized)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .padding()
                    
                    // Form
                    VStack(spacing: 20) {
                        // Measurement Type Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Ölçüm Türü")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                ForEach(MeasurementType.allCases, id: \.self) { type in
                                    Button {
                                        selectedMeasurement = type
                                    } label: {
                                        VStack(spacing: 8) {
                                            Image(systemName: type.icon)
                                                .font(.title2)
                                                .foregroundColor(selectedMeasurement == type ? .white : type.color)
                                            
                                            Text(type.displayName)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(selectedMeasurement == type ? .white : .primary)
                                                .multilineTextAlignment(.center)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(selectedMeasurement == type ? type.color : Color(.secondarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }
                        }
                        
                        // Value Input
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: selectedMeasurement.icon)
                                    .foregroundColor(selectedMeasurement.color)
                                Text("\(selectedMeasurement.displayName) (cm)")
                                    .fontWeight(.medium)
                            }
                            
                            TextField("Örn: 95.5", text: $measurementValue)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.title3)
                        }
                        
                        // Date Selection
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.blue)
                                Text(LocalizationKeys.Measurements.date)
                                    .fontWeight(.medium)
                            }
                            
                            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "note.text")
                                    .foregroundColor(.green)
                                Text(LocalizationKeys.Measurements.notes)
                                    .fontWeight(.medium)
                            }
                            
                            TextField("Antrenman öncesi, sabah açken vs.", text: $notes, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(2...4)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
                .padding()
            }
            .navigationTitle(LocalizationKeys.Measurements.addMeasurement)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationKeys.Common.cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationKeys.Common.save) {
                        onSave()
                    }
                    .fontWeight(.semibold)
                    .disabled(measurementValue.isEmpty)
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

#Preview {
    BodyMeasurementsView(user: nil)
}
