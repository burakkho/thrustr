import SwiftUI
import MapKit

/**
 * Route map component for displaying workout route in session summary.
 *
 * Shows the GPS route taken during outdoor cardio workouts with proper
 * map region calculation and route polyline overlay. Handles empty states
 * for indoor workouts or missing GPS data.
 *
 * Features:
 * - GPS route visualization with polyline
 * - Automatic map region calculation
 * - Indoor workout empty state
 * - Map snapshot generation capability
 * - Consistent styling with theme
 */
struct RouteMapView: View {
    @Environment(\.theme) private var theme

    // Route data
    let session: CardioSession
    let coordinates: [CLLocationCoordinate2D]
    let mapRegion: MKCoordinateRegion

    // Optional map snapshot for static display
    let mapSnapshot: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            // Section header
            sectionHeader

            // Map content
            mapContent
        }
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        HStack {
            Image(systemName: "map.fill")
                .foregroundColor(theme.colors.accent)
                .font(.title3)

            Text("Route")
                .font(theme.typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.textPrimary)

            Spacer()

            if !coordinates.isEmpty {
                Text(formatDistance())
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
    }

    // MARK: - Map Content

    @ViewBuilder
    private var mapContent: some View {
        if coordinates.isEmpty {
            // Indoor workout or no GPS data
            indoorWorkoutState
        } else if let snapshot = mapSnapshot {
            // Static map snapshot
            staticMapView(snapshot)
        } else {
            // Interactive map with route
            interactiveMapView
        }
    }

    private var indoorWorkoutState: some View {
        VStack(spacing: theme.spacing.m) {
            Image(systemName: "building.2.fill")
                .font(.system(size: 40))
                .foregroundColor(theme.colors.textSecondary)

            Text("Indoor Workout")
                .font(theme.typography.body)
                .fontWeight(.medium)
                .foregroundColor(theme.colors.textPrimary)

            Text("No GPS route available for indoor workouts")
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
    }

    private func staticMapView(_ snapshot: UIImage) -> some View {
        Image(uiImage: snapshot)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(height: 200)
            .cornerRadius(theme.radius.m)
            .clipped()
    }

    private var interactiveMapView: some View {
        Map {
            if !coordinates.isEmpty {
                MapPolyline(coordinates: coordinates)
                    .stroke(.blue, lineWidth: 3)
            }
        }
        .mapStyle(.standard)
        .frame(height: 200)
        .cornerRadius(theme.radius.m)
        .overlay(
            RoundedRectangle(cornerRadius: theme.radius.m)
                .stroke(theme.colors.border, lineWidth: 1)
        )
    }

    // MARK: - Helper Methods

    private func formatDistance() -> String {
        let distanceKm = session.totalDistance / 1000.0
        return String(format: "%.2f km", distanceKm)
    }
}

// MARK: - iOS 17+ MapKit Implementation

@available(iOS 17.0, *)
struct ModernRouteMapView: View {
    @Environment(\.theme) private var theme

    let session: CardioSession
    let coordinates: [CLLocationCoordinate2D]

    @State private var mapCameraPosition = MapCameraPosition.automatic

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            // Section header
            HStack {
                Image(systemName: "map.fill")
                    .foregroundColor(theme.colors.accent)
                    .font(.title3)

                Text("Route")
                    .font(theme.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.textPrimary)

                Spacer()
            }

            // Modern map with route
            if !coordinates.isEmpty {
                Map(position: $mapCameraPosition) {
                    // Route polyline
                    MapPolyline(coordinates: coordinates)
                        .stroke(.blue, lineWidth: 3)

                    // Start marker
                    if let startCoordinate = coordinates.first {
                        Annotation("Start", coordinate: startCoordinate) {
                            RouteMarker(type: .start)
                        }
                    }

                    // End marker
                    if let endCoordinate = coordinates.last, coordinates.count > 1 {
                        Annotation("End", coordinate: endCoordinate) {
                            RouteMarker(type: .end)
                        }
                    }
                }
                .frame(height: 200)
                .cornerRadius(theme.radius.m)
                .onAppear {
                    updateMapCamera()
                }
            } else {
                // Indoor workout state
                indoorWorkoutPlaceholder
            }
        }
    }

    private var indoorWorkoutPlaceholder: some View {
        VStack(spacing: theme.spacing.m) {
            Image(systemName: "building.2.fill")
                .font(.system(size: 40))
                .foregroundColor(theme.colors.textSecondary)

            Text("Indoor Workout")
                .font(theme.typography.body)
                .fontWeight(.medium)
                .foregroundColor(theme.colors.textPrimary)

            Text("No GPS route recorded")
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .background(theme.colors.cardBackground)
        .cornerRadius(theme.radius.m)
    }

    private func updateMapCamera() {
        let region = CardioSessionSummaryService.calculateMapRegion(for: coordinates)
        mapCameraPosition = .region(region)
    }
}

// MARK: - Route Markers

struct RouteMarker: View {
    enum MarkerType {
        case start
        case end

        var color: Color {
            switch self {
            case .start: return .green
            case .end: return .red
            }
        }

        var icon: String {
            switch self {
            case .start: return "play.fill"
            case .end: return "stop.fill"
            }
        }
    }

    let type: MarkerType

    var body: some View {
        ZStack {
            Circle()
                .fill(type.color)
                .frame(width: 20, height: 20)

            Image(systemName: type.icon)
                .font(.system(size: 8))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Preview

#Preview("Outdoor Route") {
    RouteMapView(
        session: {
            let session = CardioSession()
            session.totalDistance = 5000
            session.totalDuration = 1800
            session.isCompleted = true
            return session
        }(),
        coordinates: [
            CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784),
            CLLocationCoordinate2D(latitude: 41.0122, longitude: 28.9824),
            CLLocationCoordinate2D(latitude: 41.0162, longitude: 28.9864)
        ],
        mapRegion: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 41.0122, longitude: 28.9824),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ),
        mapSnapshot: nil
    )
    .padding()
}

#Preview("Indoor Workout") {
    RouteMapView(
        session: {
            let session = CardioSession()
            session.totalDistance = 0
            session.totalDuration = 1800
            session.isCompleted = true
            return session
        }(),
        coordinates: [],
        mapRegion: MKCoordinateRegion(),
        mapSnapshot: nil
    )
    .padding()
}