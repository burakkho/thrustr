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
            .navigationTitle("Vücut Ölçüleri")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") {
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
        .alert("Ölçü Kaydedildi", isPresented: $showingSuccessAlert) {
            Button("Tamam") { }
        } message: {
            Text("Yeni ölçünüz başarıyla kaydedildi.")
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
                Text("Vücut Ölçüleri")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("İlerlemenizi ölçümlerle takip edin")
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
            Text("Güncel Ölçüler")
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
                
                Text("Ölçüm yok")
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
        formatter.locale = Locale(identifier: "tr")
        return formatter.string(from: date)
    }
}

// MARK: - Progress Overview Section (Simplified)
struct ProgressOverviewSection: View {
    let measurements: [BodyMeasurement]
    let weightEntries: [WeightEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("İlerleme Özeti")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ProgressStatCard(
                    title: "Toplam Ölçüm",
                    value: "\(measurements.count)",
                    subtitle: "Son 6 ay",
                    color: .blue
                )
                
                ProgressStatCard(
                    title: "Kilo Girişi",
                    value: "\(weightEntries.count)",
                    subtitle: "Son 6 ay",
                    color: .green
                )
                
                ProgressStatCard(
                    title: "En Son Ölçüm",
                    value: latestMeasurementDate,
                    subtitle: "Tarih",
                    color: .orange
                )
                
                ProgressStatCard(
                    title: "Aktif Takip",
                    value: "\(activeMeasurementTypes)",
                    subtitle: "Ölçüm türü",
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
        guard let date = latest?.date else { return "Yok" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "tr")
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
            Text("Son Girişler")
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
        formatter.locale = Locale(identifier: "tr")
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
                Text("Kilo")
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
        formatter.locale = Locale(identifier: "tr")
        return formatter.string(from: date)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "ruler.circle")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("Henüz ölçüm yok")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("İlk ölçümünüzü eklemek için + butonuna dokunun")
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
            Text("Ölçüm İpuçları")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                MeasurementTip(
                    icon: "clock.fill",
                    title: "Doğru Zamanlama",
                    description: "Ölçümlerinizi hep aynı saatte yapın, tercihen sabah açken.",
                    color: .blue
                )
                
                MeasurementTip(
                    icon: "ruler.fill",
                    title: "Doğru Teknik",
                    description: "Mezura gevşek değil, çok sıkı da değil, kasların üzerinde olmalı.",
                    color: .green
                )
                
                MeasurementTip(
                    icon: "calendar.circle.fill",
                    title: "Düzenli Takip",
                    description: "Haftada bir veya iki haftada bir ölçüm yapmak yeterli.",
                    color: .orange
                )
                
                MeasurementTip(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Trend Odağı",
                    description: "Günlük değişimlere değil, uzun vadeli trende odaklanın.",
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
                        
                        Text("Yeni Ölçüm Ekle")
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
                                Text("Ölçüm Tarihi")
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
                                Text("Notlar (İsteğe Bağlı)")
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
            .navigationTitle("Ölçüm Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
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
