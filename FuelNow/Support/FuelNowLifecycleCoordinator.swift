import Foundation
import WidgetKit

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
    let favoritesStore: FavoritesStore
    let priceAlertCoordinator: PriceAlertCoordinator

    init() {
        let location = LocationService(snapshotStore: UserDefaultsLocationSnapshotStore())
        let store = StationStoreFactory.makeDefault()
        let favorites = FavoritesStore()
        let client = TankerkoenigClient()
        let entitlement = EntitlementManager()
        locationService = location
        stationStore = store
        stationDetailFetcher = TankerkoenigStationDetailFetcher(client: client)
        entitlementManager = entitlement
        networkMonitor = NetworkMonitor()
        widgetSnapshotStore = WidgetSnapshotStore()
        favoritesStore = favorites
        priceAlertCoordinator = PriceAlertCoordinator(
            client: client,
            favoritesStore: favorites,
            isPlusUnlocked: { entitlement.hasPlusBenefits }
        )

        FuelNowRuntimeRegistry.stationStore = store
        FuelNowRuntimeRegistry.locationService = location
        FuelNowRuntimeRegistry.lifecycleCoordinator = self
    }

    /// Watch hat Aktualisierung angefordert: optional API-Refresh, Snapshot neu bauen, Widgets + WC pushen.
    /// Rückgabe: JSON für `sendMessage`-Reply (kurz kann noch Vor-Fetch-Stand sein; danach liefert `updateApplicationContext` nach).
    func refreshStationsForWatchCompanion() -> Data? {
        let sharedDefaults = WidgetSnapshotStore.sharedDefaults
        if let preferredFuelRaw = UserDefaults.standard.string(forKey: AppSettings.UserDefaultsKey.preferredFuelType),
           sharedDefaults.string(forKey: AppSettings.UserDefaultsKey.preferredFuelType) != preferredFuelRaw {
            sharedDefaults.set(preferredFuelRaw, forKey: AppSettings.UserDefaultsKey.preferredFuelType)
        }
        if let location = locationService.currentLocation {
            stationStore.forceRefresh(
                using: location,
                radiusKm: AppSettings.SearchRadius.apiMaxKm,
                trigger: .forcedUserLocation
            )
        }
        let preferredFuel = AppSettings.preferredFuelFromStorage(defaults: sharedDefaults)
        let snapshot = WidgetSnapshotBuilder.makeSnapshot(
            stations: stationStore.stations,
            preferredFuel: preferredFuel,
            loadState: stationStore.loadState
        )
        widgetSnapshotStore.write(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
        WatchConnectivityCoordinator.shared.publish(snapshot)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(snapshot)
    }
}
