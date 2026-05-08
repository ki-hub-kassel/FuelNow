import CoreLocation
import MapKit

/// Startet die Apple-Maps-Autoroute vom aktuellen Standort zu einer Koordinate (FuelNow-Detail, Siri-Snippet).
enum AppleMapsDrivingNavigation {
    static func openDrivingDirections(toLatitude latitude: Double, longitude: Double, placeName: String?) {
        let destinationLocation = CLLocation(latitude: latitude, longitude: longitude)
        let destination = MKMapItem(location: destinationLocation, address: nil)
        destination.name = placeName

        let current = MKMapItem.forCurrentLocation()
        MKMapItem.openMaps(
            with: [current, destination],
            launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        )
    }
}
