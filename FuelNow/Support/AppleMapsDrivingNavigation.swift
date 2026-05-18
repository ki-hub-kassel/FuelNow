import CoreLocation
import MapKit
import UIKit

/// Startet die Apple-Maps-Autoroute vom aktuellen Standort zu einer Koordinate (FuelNow-Detail, Siri-Snippet, CarPlay).
enum AppleMapsDrivingNavigation {
    static var drivingDirectionsLaunchOptions: [String: Any] {
        [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
    }

    static func makeDrivingDirectionsMapItems(
        toLatitude latitude: Double,
        longitude: Double,
        placeName: String?
    ) -> [MKMapItem] {
        let destinationLocation = CLLocation(latitude: latitude, longitude: longitude)
        let destination = MKMapItem(location: destinationLocation, address: nil)
        destination.name = placeName

        let current = MKMapItem.forCurrentLocation()
        return [current, destination]
    }

    static func openDrivingDirections(
        toLatitude latitude: Double,
        longitude: Double,
        placeName: String?,
        from scene: UIScene? = nil,
        completionHandler: ((Bool) -> Void)? = nil
    ) {
        let mapItems = makeDrivingDirectionsMapItems(
            toLatitude: latitude,
            longitude: longitude,
            placeName: placeName
        )
        let launchOptions = drivingDirectionsLaunchOptions

        if let scene {
            MKMapItem.openMaps(
                with: mapItems,
                launchOptions: launchOptions,
                from: scene,
                completionHandler: completionHandler
            )
        } else {
            MKMapItem.openMaps(with: mapItems, launchOptions: launchOptions)
            completionHandler?(true)
        }
    }
}
