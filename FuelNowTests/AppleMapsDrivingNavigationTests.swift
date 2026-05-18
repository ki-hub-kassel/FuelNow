import MapKit
import Testing
@testable import FuelNow

struct AppleMapsDrivingNavigationTests {
    @Test("Autoroute-LaunchOptions nutzen Fahrmodus")
    func drivingLaunchOptionsUseDrivingMode() {
        let options = AppleMapsDrivingNavigation.drivingDirectionsLaunchOptions
        #expect(options[MKLaunchOptionsDirectionsModeKey] as? String == MKLaunchOptionsDirectionsModeDriving)
    }

    @Test("MapItems enthalten aktuellen Standort und benannte Destination")
    func mapItemsIncludeCurrentLocationAndNamedDestination() {
        let items = AppleMapsDrivingNavigation.makeDrivingDirectionsMapItems(
            toLatitude: 51.3127,
            longitude: 9.4797,
            placeName: "Test Tankstelle"
        )

        #expect(items.count == 2)
        #expect(items[0].isCurrentLocation)
        #expect(items[1].name == "Test Tankstelle")
        #expect(items[1].location.coordinate.latitude == 51.3127)
        #expect(items[1].location.coordinate.longitude == 9.4797)
    }
}
