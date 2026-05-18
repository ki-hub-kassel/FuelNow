#if canImport(CarPlay)
import UIKit

/// Startet die Apple-Maps-**Autoroute** zur Tankstelle auf dem CarPlay-Display (`from: CPTemplateApplicationScene`).
enum CarPlayDrivingNavigation {
    @MainActor
    static func openDrivingDirections(
        to station: Station,
        from scene: UIScene,
        completionHandler: ((Bool) -> Void)? = nil
    ) {
        AppleMapsDrivingNavigation.openDrivingDirections(
            toLatitude: station.latitude,
            longitude: station.longitude,
            placeName: station.name,
            from: scene,
            completionHandler: completionHandler
        )
    }
}
#endif
