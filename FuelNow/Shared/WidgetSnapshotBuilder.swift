import Foundation

enum WidgetSnapshotBuilder {
    /// Engerer Radius fuer `cheapestNearby` (u. a. Apple-Watch-Ansicht) — nur diese
    /// werden aufgenommen, damit bei einer 25-km-Suche keine Tankstelle weit draussen
    /// als „nah“ gilt.
    static let nearbyCheapestRadiusKm: Double = 5
    /// Wir liefern bis zu 4 Eintraege fuer die Watch-Liste guenstiger Stationen in 5 km.
    static let nearbyCheapestMaxCount: Int = 4

    static func makeSnapshot(
        stations: [Station],
        preferredFuel: FuelType,
        loadState: StationLoadState,
        generatedAt: Date = Date()
    ) -> WidgetDataSnapshot {
        let nearestStation = stations.min { lhs, rhs in
            stationDistance(lhs) < stationDistance(rhs)
        }

        let pricedStations = stations.compactMap { station -> (Station, Double)? in
            guard let price = station.price(for: preferredFuel) else { return nil }
            return (station, price)
        }

        let cheapestStation = pricedStations.min { lhs, rhs in
            if lhs.1 != rhs.1 {
                return lhs.1 < rhs.1
            }
            return stationDistance(lhs.0) < stationDistance(rhs.0)
        }?.0

        let cheapestNearby = pricedStations
            .filter { stationDistance($0.0) <= nearbyCheapestRadiusKm }
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 {
                    return lhs.1 < rhs.1
                }
                return stationDistance(lhs.0) < stationDistance(rhs.0)
            }
            .prefix(nearbyCheapestMaxCount)
            .map { makeStationSnapshot(station: $0.0, preferredFuel: preferredFuel) }

        return WidgetDataSnapshot(
            generatedAt: generatedAt,
            loadState: snapshotLoadState(from: loadState, stationCount: stations.count),
            preferredFuelRawValue: preferredFuel.rawValue,
            stationCount: stations.count,
            nearest: nearestStation.map { makeStationSnapshot(station: $0, preferredFuel: preferredFuel) },
            cheapest: cheapestStation.map { makeStationSnapshot(station: $0, preferredFuel: preferredFuel) },
            cheapestNearby: cheapestNearby.isEmpty ? nil : Array(cheapestNearby)
        )
    }

    private static func snapshotLoadState(from loadState: StationLoadState, stationCount: Int) -> WidgetSnapshotLoadState {
        switch loadState {
        case .idle, .loaded:
            return stationCount > 0 ? .ready : .empty
        case .loading:
            return .loading
        case .failed:
            return .failed
        }
    }

    private static func stationDistance(_ station: Station) -> Double {
        station.distanceKilometers ?? .greatestFiniteMagnitude
    }

    private static func makeStationSnapshot(station: Station, preferredFuel: FuelType) -> WidgetStationSnapshot {
        let preferredPrice = station.price(for: preferredFuel)
        return WidgetStationSnapshot(
            stationID: station.id,
            brandTitle: brandTitle(for: station),
            stationName: station.name,
            address: station.fullAddress,
            statusText: station.isOpen ? String(localized: "station.status.open") : String(localized: "station.status.closed"),
            isOpen: station.isOpen,
            distanceText: StationDisplayFormatting.distanceString(kilometers: station.distanceKilometers),
            distanceKilometers: station.distanceKilometers,
            fuelTypeDisplayName: preferredFuel.displayName,
            pumpPriceText: StationDisplayFormatting.priceString(euros: preferredPrice),
            voicePriceText: FuelPriceFormatting.voiceOverString(euros: preferredPrice),
            openInAppURL: "fuelnow://station/\(station.id.uuidString)",
            mapsDirectionsURL: mapsDirectionsURL(for: station)
        )
    }

    private static func brandTitle(for station: Station) -> String {
        let trimmed = station.brand.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? station.name : trimmed
    }

    private static func mapsDirectionsURL(for station: Station) -> String {
        var components = URLComponents(string: "https://maps.apple.com/")!
        components.queryItems = [
            URLQueryItem(name: "daddr", value: "\(station.latitude),\(station.longitude)"),
            URLQueryItem(name: "dirflg", value: "d"),
            URLQueryItem(name: "q", value: station.name),
        ]
        return components.url?.absoluteString ?? "https://maps.apple.com/"
    }
}
