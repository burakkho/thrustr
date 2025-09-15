import SwiftUI
import SwiftData

struct BodyMeasurementsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(UnitSettings.self) var unitSettings

    let user: User?
    @State private var viewModel = BodyMeasurementsViewModel()
    
    // Fixed: Remove date predicates that aren't supported
    @Query(sort: \BodyMeasurement.date, order: .reverse)
    private var allMeasurements: [BodyMeasurement]
    
    @Query(sort: \WeightEntry.date, order: .reverse)
    private var allWeightEntries: [WeightEntry]
    
    // Computed properties for filtering
    private var recentMeasurements: [BodyMeasurement] {
        return viewModel.filterRecentMeasurements(allMeasurements)
    }

    private var weightEntries: [WeightEntry] {
        return viewModel.filterRecentWeightEntries(allWeightEntries)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    MeasurementsHeaderSection()
                    
                    // Current Measurements Overview
                    CurrentMeasurementsSection(viewModel: viewModel, measurements: recentMeasurements)
                    
                    // Progress Charts Section (Simplified)
                    if viewModel.shouldShowProgress(measurements: recentMeasurements, weightEntries: weightEntries) {
                        ProgressOverviewSection(
                            viewModel: viewModel,
                            measurements: recentMeasurements,
                            weightEntries: weightEntries
                        )
                    }

                    // Recent Measurements List
                    if viewModel.shouldShowProgress(measurements: recentMeasurements, weightEntries: weightEntries) {
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
            .navigationTitle("measurements.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.close".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showAddMeasurementForm()
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
        }
        .sheet(isPresented: $viewModel.showingAddMeasurement) {
            AddMeasurementView(
                selectedMeasurement: $viewModel.selectedMeasurement,
                measurementValue: $viewModel.measurementValue,
                selectedDate: $viewModel.selectedDate,
                notes: $viewModel.notes,
                onSave: { viewModel.saveMeasurement(user: user, modelContext: modelContext) }
            )
        }
        .alert("body_measurements.measurement_saved".localized, isPresented: $viewModel.showingSuccessAlert) {
            Button("common.ok".localized) { }
        } message: {
            Text("body_measurements.saved_message".localized)
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
                Text("measurements.title".localized)
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
    let viewModel: BodyMeasurementsViewModel
    let measurements: [BodyMeasurement]

    private func latestMeasurement(for type: MeasurementType) -> BodyMeasurement? {
        return viewModel.getLatestMeasurement(for: type, from: measurements)
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
    @Environment(UnitSettings.self) var unitSettings
    
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
                let formatted = UnitsFormatter.formatHeight(cm: measurement.value, system: unitSettings.unitSystem)
                Text(formatted)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(type.color)
                
                Text(formatDate(measurement.date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                let unit = unitSettings.unitSystem == .metric ? "cm" : "in"
                Text("-- \(unit)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("measurements.no_measurements".localized)
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
    let viewModel: BodyMeasurementsViewModel
    let measurements: [BodyMeasurement]
    let weightEntries: [WeightEntry]

    private var progressStats: ProgressStats {
        return viewModel.calculateProgressStats(measurements: measurements, weightEntries: weightEntries)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("body_measurements.progress_summary".localized)
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ProgressStatCard(
                    title: "body_measurements.total_measurements".localized,
                    value: "\(progressStats.totalMeasurements)",
                    subtitle: "body_measurements.last_6_months".localized,
                    color: .blue
                )
                
                ProgressStatCard(
                    title: "body_measurements.weight_entries".localized,
                    value: "\(progressStats.totalWeightEntries)",
                    subtitle: "body_measurements.last_6_months".localized,
                    color: .green
                )
                
                ProgressStatCard(
                    title: "body_measurements.last_measurement".localized,
                    value: progressStats.latestMeasurementDate,
                    subtitle: "measurements.date".localized,
                    color: .orange
                )
                
                ProgressStatCard(
                    title: "body_measurements.active_tracking".localized,
                    value: "\(progressStats.activeMeasurementTypes)",
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
                    EmptyStateView(
                        systemImage: "ruler.circle",
                        title: "body_measurements.no_measurements".localized,
                        message: "body_measurements.first_tip".localized,
                        primaryTitle: "body_measurements.add_measurement".localized,
                        primaryAction: { /* Show measurement entry */ }
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

struct RecentMeasurementRow: View {
    let measurement: BodyMeasurement
    @Environment(UnitSettings.self) var unitSettings
    
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
            
            let formatted = UnitsFormatter.formatHeight(cm: measurement.value, system: unitSettings.unitSystem)
            Text(formatted)
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
                Text("measurements.weight".localized)
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

struct MeasurementsEmptyStateView: View {
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
                                Text("measurements.date".localized)
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
                                Text("measurements.notes".localized)
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
            .navigationTitle("measurements.add_measurement".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.save".localized) {
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
