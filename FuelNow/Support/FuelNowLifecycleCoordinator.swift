import Foundation

/// Hält die App-weiten Runtime-Dienst-Instanzen und setzt ``FuelNowRuntimeRegistry``
/// **bevor** SwiftUI `ContentView.onAppear` läuft — sonst kann die CarPlay-Session ohne Store/
/// Standort verbinden und bleibt dauerhaft auf Loading/Limited.
@MainActor
final class FuelNowLifecycleCoordinator {
    let locationService: LocationService
    let stationDetailFetcher: TankerkoenigStationDetailFetcher
    let stationStore: StationStore
    let entitlementManager: EntitlementManager
    let networkMonitor: NetworkMonitor
    let widgetSnapshotStore: WidgetSnapshotStore

    init() {
        let location = LocationService(snapshotStore: UserDefaultsLocationSnapshotStore())
        let store = StationStoreFactory.makeDefault()
        locationService = location
        stationStore = store
        stationDetailFetcher = TankerkoenigStationDetailFetcher(client: TankerkoenigClient())
        entitlementManager = EntitlementManager()
        networkMonitor = NetworkMonitor()
        widgetSnapshotStore = WidgetSnapshotStore()

        FuelNowRuntimeRegistry.stationStore = store
        FuelNowRuntimeRegistry.locationService = location
    }
}
