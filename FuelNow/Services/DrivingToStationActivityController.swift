import ActivityKit
import CoreLocation
import Foundation

/// Startet die Live Activity „Fahrt zu Tankstelle …" (Roadmap Phase 5).
///
/// **Annahme:** `NSSupportsLiveActivities` ist in `Info.plist` auf `true` (siehe Roadmap).
/// Wenn die System-Permission fehlt (User hat Live Activities global deaktiviert), gibt
/// `Activity.request(...)` einen Fehler zurueck — wir loggen ihn im DEBUG-Build, scheitern
/// aber stillschweigend (Apple-Maps-Navigation soll trotzdem starten).
///
/// **Lifetime:** Default 60 Min. Apple beendet die Activity ohnehin spaetestens nach
/// `staleDate`/`endsAt`; wir koennen mit `Activity.update(...)` Distanz/ETA fortlaufend
/// nachschieben, sobald eine Lokal-Logik dafuer existiert (Phase 5+).
enum DrivingToStationActivityController {
    static let defaultDurationSeconds: TimeInterval = 60 * 60 // 60 Min

    /// Startet eine Activity oder aktualisiert eine bereits laufende fuer dieselbe Station.
    @MainActor
    static func startActivity(
        station: Station,
        preferredFuel: FuelType,
        userLocation: CLLocation?,
        durationSeconds: TimeInterval = defaultDurationSeconds
    ) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            #if DEBUG
            print("[DrivingActivity] Live Activities sind global deaktiviert.")
            #endif
            return
        }

        let attributes = DrivingToStationActivityAttributes(
            stationID: station.id,
            brandTitle: brandTitle(for: station),
            stationName: station.name,
            pumpPriceText: FuelPriceFormatting.pumpStyleString(euros: station.price(for: preferredFuel)),
            fuelDisplayName: preferredFuel.displayName
        )

        let initialState = DrivingToStationActivityAttributes.DrivingState(
            distanceText: distanceText(from: userLocation, to: station),
            etaText: nil,
            endsAt: Date(timeIntervalSinceNow: durationSeconds)
        )

        let stationID = station.id
        let existingActivities = Activity<DrivingToStationActivityAttributes>.activities
        var foundExisting = false
        for activity in existingActivities where activity.attributes.stationID == stationID {
            await activity.update(.init(state: initialState, staleDate: initialState.endsAt))
            foundExisting = true
        }
        if foundExisting { return }

        do {
            _ = try Activity<DrivingToStationActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: initialState.endsAt),
                pushType: nil
            )
        } catch {
            #if DEBUG
            print("[DrivingActivity] start failed: \(error)")
            #endif
        }
    }

    /// Beendet alle laufenden FuelNow-Activities — Aufruf z. B. aus Settings („Live Activity
    /// stoppen") oder bei Foreground-Rueckkehr nach Ankunft (Heuristik in spaeterer Iteration).
    @MainActor
    static func endAllActivities() async {
        let activities = Activity<DrivingToStationActivityAttributes>.activities
        for activity in activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private static func brandTitle(for station: Station) -> String {
        let trimmed = station.brand.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? station.name : trimmed
    }

    private static func distanceText(from userLocation: CLLocation?, to station: Station) -> String {
        if let userLocation {
            let stationLocation = CLLocation(latitude: station.latitude, longitude: station.longitude)
            let km = userLocation.distance(from: stationLocation) / 1000
            return StationDisplayFormatting.distanceString(kilometers: km)
        }
        return StationDisplayFormatting.distanceString(kilometers: station.distanceKilometers)
    }
}
