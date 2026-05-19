#if canImport(CarPlay)
import CarPlay
import Foundation

/// CarPlay-Session-Kontext für Listenaufbau (Scene, Controller, Callbacks).
struct CarPlayStationListEnvironment {
    let carPlayScene: CPTemplateApplicationScene?
    let interfaceController: CPInterfaceController?
    let onToggleSort: @MainActor () -> Void
    let makeSimpleInfoTemplate: @MainActor (String, String) -> CPInformationTemplate
}

/// Baut die CarPlay-Plus-Tankstellenliste inkl. Sortierung und Detail-Push.
enum CarPlayStationListBuilder {
    @MainActor
    static func makeStationsListRoot(
        store: StationStore,
        sortMode: CarPlayStationSortMode,
        environment: CarPlayStationListEnvironment
    ) -> CPTemplate {
        let fuel = AppSettings.preferredFuelFromStorage()
        let filtered = store.stations.filter { StationCarPlayPOIMapper.isRenderableStationCoordinate($0) }
        guard !filtered.isEmpty else {
            return environment.makeSimpleInfoTemplate(
                String(localized: "carplay.plus.empty.title"),
                String(localized: "carplay.plus.empty.body")
            )
        }

        let origin = resolveOrigin(store: store, stations: filtered)
        let sorted: [Station] = switch sortMode {
        case .distance:
            QueryService.sortByDistance(
                stations: filtered,
                originLatitude: origin.latitude,
                originLongitude: origin.longitude
            )
        case .price:
            QueryService.sortByPrice(
                stations: filtered,
                fuel: fuel,
                originLatitude: origin.latitude,
                originLongitude: origin.longitude
            )
        }

        let rows = StationCarPlayPOIMapper.buildRows(stations: sorted, preferredFuel: fuel)
        let byID = StationCarPlayPOIMapper.stationsByIDReplacingDuplicates(sorted)
        guard !rows.isEmpty else {
            return environment.makeSimpleInfoTemplate(
                String(localized: "carplay.plus.error.title"),
                String(localized: "carplay.plus.error.generic")
            )
        }

        return StationCarPlayPOIMapper.makeNearbyListTemplate(
            rows: rows,
            stationsByID: byID,
            sortMode: sortMode,
            onToggleSort: environment.onToggleSort
        ) { station in
            guard let interfaceController = environment.interfaceController else { return }
            let detail = CarPlayStationDetailInformationTemplate.make(
                station: station,
                interfaceController: interfaceController,
                carPlayScene: environment.carPlayScene
            )
            interfaceController.pushTemplate(detail, animated: true, completion: nil)
        }
    }

    @MainActor
    private static func resolveOrigin(store: StationStore, stations: [Station]) -> (latitude: Double, longitude: Double) {
        if let center = store.lastFetchCenter {
            return (center.latitude, center.longitude)
        }
        if let location = FuelNowRuntimeRegistry.locationService?.currentLocation {
            return (location.coordinate.latitude, location.coordinate.longitude)
        }
        if let first = stations.first {
            return (first.latitude, first.longitude)
        }
        return (0, 0)
    }
}
#endif
