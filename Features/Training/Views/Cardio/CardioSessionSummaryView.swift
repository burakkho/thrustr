import SwiftUI
import MapKit
import SwiftData

struct CardioSessionSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    
    let session: CardioSession
    let user: User
    let onDismiss: (() -> Void)?
    
    init(session: CardioSession, user: User, onDismiss: (() -> Void)? = nil) {
        self.session = session
        self.user = user
        self.onDismiss = onDismiss
    }
    
    @State private var feeling: SessionFeeling = .good
    @State private var notes: String = ""
    @State private var showingShareSheet = false
    @State private var mapSnapshot: UIImage?
    @State private var mapCameraPosition = MapCameraPosition.automatic
    
    private var routeCoordinates: [CLLocationCoordinate2D] {
        guard let routeData = session.routeData,
              let routePoints = try? JSONSerialization.jsonObject(with: routeData) as? [[String: Double]] else {
            return []
        }
        
        return routePoints.compactMap { point in
            guard let lat = point["lat"], let lng = point["lng"] else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.l) {
                    // Success Header
                    successHeader
                    
                    // Main Stats
                    mainStatsSection
                    
                    // Route Map (if available)
                    if !routeCoordinates.isEmpty {
                        routeMapSection
                    }
                    
                    // Detailed Stats
                    detailedStatsSection
                    
                    // Heart Rate Stats (if available)
                    if let avgHR = session.averageHeartRate, avgHR > 0 {
                        heartRateStatsSection
                    }
                    
                    // Feeling Selection
                    feelingSection
                    
                    // Notes
                    notesSection
                    
                    // Action Buttons
                    actionButtons
                }
                .padding(theme.spacing.m)
            }
            .navigationTitle("Antrenman Özeti")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = createShareImage() {
                CardioShareSheet(items: [image, createShareText()])
            }
        }
    }
    
    // MARK: - Success Header
    private var successHeader: some View {
        VStack(spacing: theme.spacing.m) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(theme.colors.success)
                .symbolRenderingMode(.hierarchical)
            
            Text("Tebrikler!")
                .font(theme.typography.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.textPrimary)
            
            Text("Antrenmanını tamamladın")
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
        }
        .padding(.vertical, theme.spacing.l)
    }
    
    // MARK: - Main Stats
    private var mainStatsSection: some View {
        HStack(spacing: theme.spacing.m) {
            MainStatCard(
                icon: "timer",
                value: session.formattedDuration,
                label: "Süre",
                color: theme.colors.accent
            )
            
            MainStatCard(
                icon: "location.fill",
                value: session.formattedDistance,
                label: "Mesafe",
                color: theme.colors.success
            )
            
            MainStatCard(
                icon: "flame.fill",
                value: "\(session.totalCaloriesBurned ?? 0)",
                label: "Kalori",
                color: theme.colors.warning
            )
        }
    }
    
    // MARK: - Route Map
    private var routeMapSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Image(systemName: "map.fill")
                    .foregroundColor(theme.colors.accent)
                Text("Rotanız")
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
            }
            
            Map(position: $mapCameraPosition) {
                MapPolyline(coordinates: routeCoordinates)
                    .stroke(.blue, lineWidth: 4)
                
                if let start = routeCoordinates.first {
                    Marker("Başlangıç", coordinate: start)
                        .tint(.green)
                }
                
                if let end = routeCoordinates.last {
                    Marker("Bitiş", coordinate: end)
                        .tint(.red)
                }
            }
            .frame(height: 300)
            .cornerRadius(theme.radius.m)
            .onAppear {
                if !routeCoordinates.isEmpty {
                    let region = calculateRegion(for: routeCoordinates)
                    mapCameraPosition = .region(region)
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Detailed Stats
    private var detailedStatsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(theme.colors.accent)
                Text("Detaylı İstatistikler")
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
            }
            
            VStack(spacing: theme.spacing.s) {
                DetailStatRow(label: "Ortalama Tempo", value: session.formattedAveragePace ?? "--:--")
                Divider()
                DetailStatRow(label: "Ortalama Hız", value: session.formattedSpeed ?? "-- km/h")
                
                if let elevation = session.elevationGain, elevation > 0 {
                    Divider()
                    DetailStatRow(label: "Yükseliş", value: String(format: "%.0f m", elevation))
                }
                
                if let effort = session.perceivedEffort {
                    Divider()
                    DetailStatRow(label: "Algılanan Zorluk", value: "\(effort)/10")
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Heart Rate Stats
    private var heartRateStatsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(theme.colors.error)
                Text("Nabız İstatistikleri")
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
            }
            
            HStack(spacing: theme.spacing.xl) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ortalama")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(session.averageHeartRate ?? 0)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(theme.colors.textPrimary)
                        Text("bpm")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Maksimum")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(session.maxHeartRate ?? 0)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(theme.colors.error)
                        Text("bpm")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
                
                Spacer()
            }
        }
        .cardStyle()
    }
    
    // MARK: - Feeling Section
    private var feelingSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text("Nasıl Hissediyorsun?")
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
            
            HStack(spacing: theme.spacing.s) {
                ForEach(SessionFeeling.allCases, id: \.self) { feelingOption in
                    Button(action: { feeling = feelingOption }) {
                        VStack(spacing: 4) {
                            Text(feelingOption.emoji)
                                .font(.title2)
                            Text(feelingOption.displayName)
                                .font(.caption2)
                                .fontWeight(feeling == feelingOption ? .semibold : .regular)
                        }
                        .foregroundColor(feeling == feelingOption ? .white : theme.colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, theme.spacing.s)
                        .background(
                            RoundedRectangle(cornerRadius: theme.radius.s)
                                .fill(feeling == feelingOption ? theme.colors.accent : theme.colors.backgroundSecondary)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            Text("Notlar (Opsiyonel)")
                .font(theme.typography.body)
                .fontWeight(.medium)
                .foregroundColor(theme.colors.textPrimary)
            
            TextField("Antrenman hakkında notlarınız...", text: $notes, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(theme.spacing.m)
                .background(theme.colors.backgroundSecondary)
                .cornerRadius(theme.radius.m)
                .lineLimit(3...5)
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: theme.spacing.m) {
            Button(action: saveSession) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                    Text("Kaydet")
                        .font(theme.typography.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(theme.spacing.l)
                .background(theme.colors.accent)
                .cornerRadius(theme.radius.m)
            }
            
            Button(action: discardSession) {
                Text("Kaydetmeden Çık")
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
        .padding(.vertical, theme.spacing.l)
    }
    
    // MARK: - Helper Methods
    private func calculateRegion(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard !coordinates.isEmpty else {
            return MKCoordinateRegion()
        }
        
        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }
        
        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.3,
            longitudeDelta: (maxLon - minLon) * 1.3
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
    
    private func saveSession() {
        // Update session with feeling and notes
        session.feeling = feeling.rawValue
        session.sessionNotes = notes.isEmpty ? nil : notes
        session.completeSession()
        
        // Save to context
        modelContext.insert(session)
        
        // Update user stats
        user.addCardioSession(
            duration: TimeInterval(session.totalDuration),
            distance: session.totalDistance
        )
        
        do {
            try modelContext.save()
            Logger.info("Cardio session saved successfully")
            
            // Dismiss with callback
            if let onDismiss = onDismiss {
                onDismiss()
            } else {
                dismiss()
            }
        } catch {
            Logger.error("Failed to save cardio session: \(error)")
        }
    }
    
    private func discardSession() {
        if let onDismiss = onDismiss {
            onDismiss()
        } else {
            dismiss()
        }
    }
    
    private func createShareText() -> String {
        var text = "🏃 Antrenmanımı tamamladım!\n\n"
        text += "⏱ Süre: \(session.formattedDuration)\n"
        text += "📍 Mesafe: \(session.formattedDistance)\n"
        text += "🔥 Kalori: \(session.totalCaloriesBurned ?? 0) kcal\n"
        
        if let pace = session.formattedAveragePace {
            text += "⚡ Tempo: \(pace)\n"
        }
        
        text += "\n#Thrustr #Fitness"
        
        return text
    }
    
    private func createShareImage() -> UIImage? {
        // TODO: Create a nice share image with stats
        return nil
    }
}

// MARK: - Main Stat Card
struct MainStatCard: View {
    @Environment(\.theme) private var theme
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: theme.spacing.s) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(theme.colors.textPrimary)
            
            Text(label)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(theme.spacing.m)
        .background(theme.colors.backgroundSecondary)
        .cornerRadius(theme.radius.m)
    }
}

// MARK: - Detail Stat Row
struct DetailStatRow: View {
    @Environment(\.theme) private var theme
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(theme.typography.body)
                .foregroundColor(theme.colors.textSecondary)
            Spacer()
            Text(value)
                .font(theme.typography.body)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)
        }
        .padding(.vertical, theme.spacing.xs)
    }
}

// MARK: - Share Sheet
struct CardioShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}