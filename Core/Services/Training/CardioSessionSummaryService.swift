import Foundation
import MapKit
import SwiftData
import UIKit

/**
 * Business logic service for Cardio Session Summary functionality.
 *
 * Handles all business operations for session summary including route processing,
 * session editing, performance calculations, and share content generation.
 * Separates business logic from UI presentation for better maintainability.
 *
 * Features:
 * - Route data processing and map utilities
 * - Session saving and editing operations
 * - Performance metrics calculations
 * - Share content generation
 * - Data validation and formatting
 */
struct CardioSessionSummaryService: Sendable {

    // MARK: - Route Processing

    /**
     * Extracts route coordinates from session route data.
     *
     * - Parameter session: CardioSession with route data
     * - Returns: Array of CLLocationCoordinate2D for map display
     */
    static func extractRouteCoordinates(from session: CardioSession) -> [CLLocationCoordinate2D] {
        guard let routeData = session.routeData,
              let routePoints = try? JSONSerialization.jsonObject(with: routeData) as? [[String: Double]] else {
            return []
        }

        return routePoints.compactMap { point in
            guard let latitude = point["latitude"],
                  let longitude = point["longitude"] else {
                return nil
            }
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }

    /**
     * Calculates optimal map region for route display.
     *
     * - Parameter coordinates: Array of route coordinates
     * - Returns: MKCoordinateRegion for map display
     */
    static func calculateMapRegion(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard !coordinates.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784), // Istanbul
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }

        if coordinates.count == 1 {
            return MKCoordinateRegion(
                center: coordinates[0],
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
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
            latitudeDelta: max(maxLat - minLat, 0.01) * 1.2,
            longitudeDelta: max(maxLon - minLon, 0.01) * 1.2
        )

        return MKCoordinateRegion(center: center, span: span)
    }

    // MARK: - Session Operations

    /**
     * Saves session with updated metadata, user stats update, activity logging and HealthKit sync.
     *
     * - Parameters:
     *   - session: CardioSession to save
     *   - feeling: User's session feeling
     *   - notes: User's session notes
     *   - user: User for stats update
     *   - modelContext: SwiftData model context
     *   - healthKitService: HealthKit service for sync
     */
    static func saveSession(
        _ session: CardioSession,
        feeling: SessionFeeling,
        notes: String,
        user: User,
        modelContext: ModelContext,
        healthKitService: HealthKitService
    ) async {
        // Update session metadata
        session.feeling = feeling.rawValue
        session.sessionNotes = notes.isEmpty ? nil : notes

        // Mark as completed if not already (without recalculating totals)
        if !session.isCompleted {
            session.completedAt = Date()
            session.isCompleted = true
        }

        // Update user stats (use final edited values)
        user.addCardioSession(
            duration: TimeInterval(session.totalDuration),
            distance: session.totalDistance,
            calories: session.totalCaloriesBurned
        )

        do {
            // Save to SwiftData
            try modelContext.save()

            // Log activity for dashboard
            let workoutName = session.workoutName
            let totalDistance = session.totalDistance
            let totalDuration = TimeInterval(session.totalDuration)
            let totalCalories = Double(session.totalCaloriesBurned ?? 0)

            await MainActor.run { [user] in
                ActivityLoggerService.shared.logCardioCompleted(
                    activityType: workoutName,
                    distance: totalDistance,
                    duration: totalDuration,
                    calories: totalCalories,
                    user: user
                )
            }

            // Save to HealthKit
            let success = await healthKitService.saveCardioWorkout(
                activityType: session.workoutName,
                duration: TimeInterval(session.totalDuration),
                distance: session.totalDistance > 0 ? session.totalDistance : nil,
                caloriesBurned: session.totalCaloriesBurned.map { Double($0) },
                averageHeartRate: session.averageHeartRate.map { Double($0) },
                maxHeartRate: session.maxHeartRate.map { Double($0) },
                startDate: session.startDate,
                endDate: session.completedAt ?? Date()
            )

            if success {
                Logger.info("Cardio workout successfully synced to HealthKit")
            }

            Logger.info("Session saved successfully")

        } catch {
            Logger.error("Failed to save session: \(error)")
        }
    }

    /**
     * Discards session by deleting from context.
     *
     * - Parameters:
     *   - session: CardioSession to discard
     *   - modelContext: SwiftData model context
     */
    static func discardSession(_ session: CardioSession, modelContext: ModelContext) {
        modelContext.delete(session)

        do {
            try modelContext.save()
            Logger.info("Session discarded successfully")
        } catch {
            Logger.error("Failed to discard session: \(error)")
        }
    }

    // MARK: - Session Editing

    /**
     * Updates session duration with validation.
     *
     * - Parameters:
     *   - session: CardioSession to update
     *   - hours: New hours value
     *   - minutes: New minutes value
     *   - seconds: New seconds value
     */
    static func updateSessionDuration(
        _ session: CardioSession,
        hours: Int,
        minutes: Int,
        seconds: Int
    ) {
        let newDuration = TimeInterval(hours * 3600 + minutes * 60 + seconds)

        // Validate duration (minimum 1 minute, maximum 24 hours)
        guard newDuration >= 60 && newDuration <= 86400 else {
            Logger.warning("Invalid duration attempted: \(newDuration)")
            return
        }

        session.totalDuration = Int(newDuration)
        session.isDurationManuallyEdited = true

        Logger.info("Session duration updated to \(newDuration) seconds")
    }

    /**
     * Updates session distance with validation.
     *
     * - Parameters:
     *   - session: CardioSession to update
     *   - distance: New distance in meters
     */
    static func updateSessionDistance(_ session: CardioSession, distance: Double) {
        // Validate distance (maximum 200km)
        guard distance >= 0 && distance <= 200000 else {
            Logger.warning("Invalid distance attempted: \(distance)")
            return
        }

        session.totalDistance = distance
        session.isDistanceManuallyEdited = true

        // Recalculate average speed if duration > 0
        if session.duration > 0 {
            let speedKmh = (distance / 1000.0) / (Double(session.duration) / 3600.0)
            session.averageSpeed = speedKmh
        }

        Logger.info("Session distance updated to \(distance) meters")
    }

    /**
     * Updates session calories with validation.
     *
     * - Parameters:
     *   - session: CardioSession to update
     *   - calories: New calories value
     */
    static func updateSessionCalories(_ session: CardioSession, calories: Int) {
        // Validate calories (maximum 5000)
        guard calories >= 0 && calories <= 5000 else {
            Logger.warning("Invalid calories attempted: \(calories)")
            return
        }

        session.totalCaloriesBurned = calories
        session.isCaloriesManuallyEdited = true

        Logger.info("Session calories updated to \(calories)")
    }

    /**
     * Updates session heart rate data with validation.
     *
     * - Parameters:
     *   - session: CardioSession to update
     *   - avgHeartRate: New average heart rate
     *   - maxHeartRate: New maximum heart rate
     */
    static func updateSessionHeartRate(
        _ session: CardioSession,
        avgHeartRate: Int,
        maxHeartRate: Int
    ) {
        // Validate heart rate values (30-220 BPM range)
        guard avgHeartRate >= 30 && avgHeartRate <= 220,
              maxHeartRate >= 30 && maxHeartRate <= 220,
              maxHeartRate >= avgHeartRate else {
            Logger.warning("Invalid heart rate values attempted: avg=\(avgHeartRate), max=\(maxHeartRate)")
            return
        }

        session.averageHeartRate = avgHeartRate
        session.maxHeartRate = maxHeartRate
        // Heart rate doesn't have specific manual edit flag

        Logger.info("Session heart rate updated: avg=\(avgHeartRate), max=\(maxHeartRate)")
    }

    // MARK: - Share Content Generation

    /**
     * Generates shareable text content for session.
     *
     * - Parameters:
     *   - session: CardioSession to share
     *   - unitSystem: Unit system for formatting
     * - Returns: Formatted share text
     */
    static func generateShareText(for session: CardioSession, unitSystem: UnitSystem) -> String {
        var components: [String] = []

        // Header
        components.append("🏃‍♂️ \(session.workoutName)")
        components.append("")

        // Duration
        let duration = formatDuration(TimeInterval(session.totalDuration))
        components.append("⏱️ Duration: \(duration)")

        // Distance (if available)
        if session.totalDistance > 0 {
            let distance = UnitsFormatter.formatDistance(meters: session.totalDistance, system: unitSystem)
            components.append("📍 Distance: \(distance)")

            // Average pace (if calculable)
            if let pace = calculateAveragePace(for: session, unitSystem: unitSystem) {
                components.append("⚡ Pace: \(pace)")
            }
        }

        // Calories
        if let calories = session.totalCaloriesBurned, calories > 0 {
            components.append("🔥 Calories: \(calories)")
        }

        // Heart rate (if available)
        if let avgHR = session.averageHeartRate, avgHR > 0 {
            components.append("❤️ Avg Heart Rate: \(avgHR) BPM")
        }

        // Feeling (if set)
        if let feeling = session.feeling {
            let emoji = SessionFeeling.fromString(feeling)?.emoji ?? "😊"
            components.append("\(emoji) Feeling: \(feeling.capitalized)")
        }

        components.append("")
        components.append("Tracked with Thrustr 💪")

        return components.joined(separator: "\n")
    }

    /**
     * Creates shareable image for session.
     *
     * - Parameters:
     *   - session: CardioSession to visualize
     *   - unitSystem: Unit system for formatting
     * - Returns: UIImage for sharing
     */
    static func createShareImage(for session: CardioSession, unitSystem: UnitSystem) -> UIImage? {
        let size = CGSize(width: 400, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // Background
            UIColor.systemBackground.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Header
            drawShareHeader(context: context, session: session, size: size)

            // Stats
            drawShareStats(context: context, session: session, unitSystem: unitSystem, size: size)

            // Footer
            drawShareFooter(context: context, size: size)
        }
    }

    // MARK: - Performance Calculations

    /**
     * Calculates average pace for session.
     *
     * - Parameters:
     *   - session: CardioSession to analyze
     *   - unitSystem: Unit system for formatting
     * - Returns: Formatted average pace string
     */
    static func calculateAveragePace(for session: CardioSession, unitSystem: UnitSystem) -> String? {
        guard session.totalDistance > 0 && session.duration > 0 else { return nil }

        let distanceKm = session.totalDistance / 1000.0
        let timeMinutes = Double(session.duration) / 60.0
        let paceMinPerKm = timeMinutes / distanceKm

        return UnitsFormatter.formatDetailedPace(minPerKm: paceMinPerKm, system: unitSystem)
    }

    /**
     * Formats duration in readable format.
     *
     * - Parameter duration: Duration in seconds
     * - Returns: Formatted duration string
     */
    static func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    // MARK: - Private Helpers

    private static func syncWithHealthKit(session: CardioSession, healthKitService: HealthKitService) async {
        // Implementation would sync workout data with HealthKit
        // This is a placeholder for HealthKit integration
        Logger.info("HealthKit sync initiated for session")
    }

    private static func drawShareHeader(context: UIGraphicsImageRendererContext, session: CardioSession, size: CGSize) {
        let title = session.workoutName
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.label
        ]

        let titleSize = title.size(withAttributes: attributes)
        let titleRect = CGRect(
            x: (size.width - titleSize.width) / 2,
            y: 40,
            width: titleSize.width,
            height: titleSize.height
        )

        title.draw(in: titleRect, withAttributes: attributes)
    }

    private static func drawShareStats(context: UIGraphicsImageRendererContext, session: CardioSession, unitSystem: UnitSystem, size: CGSize) {
        // Implementation for drawing stats on share image
        // This would draw formatted metrics in an attractive layout
    }

    private static func drawShareFooter(context: UIGraphicsImageRendererContext, size: CGSize) {
        let footer = "Tracked with Thrustr 💪"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.secondaryLabel
        ]

        let footerSize = footer.size(withAttributes: attributes)
        let footerRect = CGRect(
            x: (size.width - footerSize.width) / 2,
            y: size.height - 60,
            width: footerSize.width,
            height: footerSize.height
        )

        footer.draw(in: footerRect, withAttributes: attributes)
    }
}

// MARK: - Supporting Types

// SessionFeeling enum is defined in CardioSession.swift
