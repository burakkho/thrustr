import Foundation
import SwiftUI
import MapKit
import SwiftData

@MainActor
@Observable
class CardioSessionSummaryViewModel {

    // MARK: - State Properties
    var formattedDuration: String = ""
    var formattedDistance: String = ""
    var formattedDate: String = ""
    var formattedTime: String = ""
    var averageSpeed: String = ""
    var routeCoordinates: [CLLocationCoordinate2D] = []
    var mapRegion: MKCoordinateRegion = MKCoordinateRegion()
    var mapCameraPosition: MapCameraPosition = .automatic

    // Edit state
    var editHours: Int = 0
    var editMinutes: Int = 0
    var editSeconds: Int = 0
    var editDistance: Double = 0.0
    var editCalories: Int = 0
    var editAvgHeartRate: Int = 0
    var editMaxHeartRate: Int = 0
    var isHeartRateEdited = false

    // UI state
    var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies
    private let unitSettings: UnitSettings

    // MARK: - Initialization
    init(unitSettings: UnitSettings) {
        self.unitSettings = unitSettings
    }

    // MARK: - Share Methods

    func createShareText(for session: CardioSession) -> String {
        var text = "🏃‍♀️ Workout Completed!\n\n"
        text += "⏱️ Duration: \(session.formattedDuration)\n"
        text += "📍 Distance: \(session.formattedDistance(using: unitSettings.unitSystem))\n"
        text += "🔥 Calories: \(session.totalCaloriesBurned ?? 0) kcal\n"

        if let pace = session.formattedAveragePace(using: unitSettings.unitSystem) {
            text += "⚡ Pace: \(pace)\n"
        }

        text += "\n#Thrustr #Fitness"

        return text
    }

    func createShareImage(for session: CardioSession) -> UIImage? {
        let cardSize = CGSize(width: 400, height: 500)
        let hostingController = UIHostingController(
            rootView: CardioShareCard(session: session)
                .frame(width: cardSize.width, height: cardSize.height)
                .background(Color.white)
        )
        hostingController.view.bounds = CGRect(origin: .zero, size: cardSize)

        let renderer = UIGraphicsImageRenderer(size: cardSize)
        return renderer.image { _ in
            hostingController.view.drawHierarchy(in: hostingController.view.bounds, afterScreenUpdates: true)
        }
    }

    // MARK: - Public Methods

    func loadSessionData(for session: CardioSession) {
        isLoading = true
        errorMessage = nil

        // Load route data
        loadRouteData(for: session)

        // Load formatted data
        updateFormattedData(for: session)

        // Initialize edit values
        initializeEditValues(for: session)

        isLoading = false
    }

    func updateFormattedData(for session: CardioSession) {
        formattedDuration = formatDuration(for: session)
        formattedDistance = formatDistance(for: session)
        formattedDate = formatDate(session.startDate)
        formattedTime = formatTime(session.startDate)
        averageSpeed = calculateAverageSpeed(for: session)
    }

    // MARK: - Route Management

    private func loadRouteData(for session: CardioSession) {
        // Extract route coordinates using service
        routeCoordinates = CardioSessionSummaryService.extractRouteCoordinates(from: session)

        // Calculate map region
        if !routeCoordinates.isEmpty {
            mapRegion = CardioSessionSummaryService.calculateMapRegion(for: routeCoordinates)
            mapCameraPosition = .region(mapRegion)
        }
    }

    // MARK: - Edit Management

    private func initializeEditValues(for session: CardioSession) {
        let duration = session.totalDuration
        editHours = duration / 3600
        editMinutes = (duration % 3600) / 60
        editSeconds = duration % 60

        editDistance = session.totalDistance / 1000.0 // Convert to km
        editCalories = session.totalCaloriesBurned ?? 0
        editAvgHeartRate = session.averageHeartRate ?? 0
        editMaxHeartRate = session.maxHeartRate ?? 0
    }

    func updateSessionDuration(_ session: CardioSession) {
        CardioSessionSummaryService.updateSessionDuration(
            session,
            hours: editHours,
            minutes: editMinutes,
            seconds: editSeconds
        )
        updateFormattedData(for: session)
    }

    func updateSessionDistance(_ session: CardioSession) {
        let distanceInMeters = editDistance * 1000.0
        CardioSessionSummaryService.updateSessionDistance(session, distance: distanceInMeters)
        updateFormattedData(for: session)
    }

    func updateSessionCalories(_ session: CardioSession) {
        if editCalories != (session.totalCaloriesBurned ?? 0) {
            session.updateCaloriesManually(editCalories > 0 ? editCalories : nil)
        }
    }

    func updateSessionHeartRate(_ session: CardioSession) {
        let originalAvg = session.averageHeartRate ?? 0
        let originalMax = session.maxHeartRate ?? 0

        if editAvgHeartRate != originalAvg || editMaxHeartRate != originalMax {
            isHeartRateEdited = true
            session.averageHeartRate = editAvgHeartRate > 0 ? editAvgHeartRate : nil
            session.maxHeartRate = editMaxHeartRate > 0 ? editMaxHeartRate : nil
        }
    }

    // MARK: - Edit Modal Operations

    func prepareDurationEdit(for session: CardioSession) {
        let duration = session.totalDuration
        editHours = duration / 3600
        editMinutes = (duration % 3600) / 60
        editSeconds = duration % 60
    }

    func prepareDistanceEdit(for session: CardioSession, unitSystem: UnitSystem) {
        switch unitSystem {
        case .metric:
            editDistance = session.totalDistance / 1000.0 // meters to km
        case .imperial:
            editDistance = session.totalDistance / 1609.34 // meters to miles
        }
    }

    func prepareCaloriesEdit(for session: CardioSession) {
        editCalories = session.totalCaloriesBurned ?? 0
    }

    func prepareHeartRateEdit(for session: CardioSession) {
        editAvgHeartRate = session.averageHeartRate ?? 0
        editMaxHeartRate = session.maxHeartRate ?? 0
    }

    func saveSession(
        _ session: CardioSession,
        feeling: SessionFeeling,
        notes: String,
        user: User,
        modelContext: ModelContext,
        healthKitService: HealthKitService
    ) async {
        isLoading = true
        await CardioSessionSummaryService.saveSession(
            session,
            feeling: feeling,
            notes: notes,
            user: user,
            modelContext: modelContext,
            healthKitService: healthKitService
        )
        isLoading = false
    }

    // MARK: - Validation Properties (using Core validators)

    var isValidEditDuration: Bool {
        let totalSeconds = editHours * 3600 + editMinutes * 60 + editSeconds
        return totalSeconds >= 60 // Minimum 1 minute, consistent with DurationValidator
    }

    var isValidEditDistance: Bool {
        let result = MesafeValidator.validateDistance(String(editDistance))
        return result.isValid
    }

    var isValidEditCalories: Bool {
        let result = CaloriesValidator.validateCalories(String(editCalories))
        return result.isValid
    }

    var isValidEditHeartRate: Bool {
        let avgResult = HeartRateValidator.validateHeartRate(String(editAvgHeartRate))
        let maxResult = HeartRateValidator.validateHeartRate(String(editMaxHeartRate))

        // Both must be valid and max >= avg
        return avgResult.isValid && maxResult.isValid && editMaxHeartRate >= editAvgHeartRate
    }

    // MARK: - Business Logic (moved from View)

    private func formatDuration(for session: CardioSession) -> String {
        CardioSessionSummaryService.formatDuration(TimeInterval(session.totalDuration))
    }

    private func formatDistance(for session: CardioSession) -> String {
        UnitsFormatter.formatDistance(meters: session.totalDistance, system: unitSettings.unitSystem)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func calculateAverageSpeed(for session: CardioSession) -> String {
        guard session.totalDistance > 0 && session.totalDuration > 0 else { return "0" }
        let speedKmh = (session.totalDistance / 1000.0) / (Double(session.totalDuration) / 3600.0)
        return UnitsFormatter.formatSpeed(kmh: speedKmh, system: unitSettings.unitSystem)
    }
}