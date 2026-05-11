import CoreLocation
import Foundation

#if canImport(CarPlay)
import CarPlay
#endif

// MARK: - Presentation rows (unit-testable, kein CarPlay)

/// Eine Zeile für die CarPlay-Plus-Tankstellenliste — gebaut aus ``Station`` + bevorzugter Kraftstoffsorte.
struct StationCarPlayPOIRow {
    let stationID: UUID
    /// Zeile im horizontalen Picker — typischerweise Marke.
    let pickerTitle: String
    /// Untertitel — bevorzugte Sorte + Preis (oder „—“).
    let pickerSubtitle: String
    /// Kurz-Zusammenfassung unter dem Picker-Eintrag — Status + Entfernung.
    let pickerSummary: String
    /// Mehrzeilige Detail-Zusammenfassung (Tests / künftige Erweiterungen).
    let detailSummary: String
}

enum StationCarPlayPOIMapper {
    /// Tankerkönig / UX: höchstens 12 Einträge in der CarPlay-Plus-Liste.
    static let maxPointsOfInterest = 12

    /// Letzter Eintrag gewinnt — vermeidet Crash von `Dictionary(uniqueKeysWithValues:)` bei doppelter `Station.id`.
    static func stationsByIDReplacingDuplicates(_ stations: [Station]) -> [UUID: Station] {
        var byID: [UUID: Station] = [:]
        for station in stations {
            byID[station.id] = station
        }
        return byID
    }

    static func isRenderableStationCoordinate(_ station: Station) -> Bool {
        CLLocationCoordinate2DIsValid(station.coordinate)
    }

    static func buildRows(stations: [Station], preferredFuel: FuelType) -> [StationCarPlayPOIRow] {
        Array(stations.prefix(maxPointsOfInterest)).map { makeRow(station: $0, preferredFuel: preferredFuel) }
    }

    static func makeRow(station: Station, preferredFuel: FuelType) -> StationCarPlayPOIRow {
        let brand = station.brand.trimmingCharacters(in: .whitespacesAndNewlines)
        let pickerTitle = brand.isEmpty ? station.name : brand

        // TAN-93: Schilder-Stil `1,58⁹` mit Unicode-Superscript für CarPlay-detailText.
        let priceText = StationDisplayFormatting.priceString(euros: station.price(for: preferredFuel))
        let pickerSubtitle = "\(preferredFuel.displayName) \(priceText)"

        let status = station.isOpen
            ? String(localized: "station.status.open")
            : String(localized: "station.status.closed")
        let distance = StationDisplayFormatting.distanceString(kilometers: station.distanceKilometers)
        let pickerSummary = "\(status) · \(distance)"

        let detailSummary = """
        \(station.fullAddress)

        \(compactFuelLine(station: station))
        """

        return StationCarPlayPOIRow(
            stationID: station.id,
            pickerTitle: pickerTitle,
            pickerSubtitle: pickerSubtitle,
            pickerSummary: pickerSummary,
            detailSummary: detailSummary
        )
    }

    /// Eine kompakte Preiszeile für alle Sorten — konsistent mit der Detailansicht
    /// (Schilder-Stil `1,58⁹` mit Unicode-Superscript, TAN-93).
    static func compactFuelLine(station: Station) -> String {
        FuelType.allCases.map { fuel in
            let value = StationDisplayFormatting.priceString(euros: station.price(for: fuel))
            return "\(fuel.displayName) \(value)"
        }.joined(separator: " · ")
    }

    #if canImport(CarPlay)
    /// Sortierte Liste — Root-Template in CarPlay Plus.
    @MainActor
    static func makeNearbyListTemplate(
        rows: [StationCarPlayPOIRow],
        stationsByID: [UUID: Station]
    ) -> CPListTemplate {
        let items: [CPListItem] = rows.map { row in
            let detailText = "\(row.pickerSubtitle) · \(row.pickerSummary)"
            let item = CPListItem(text: row.pickerTitle, detailText: detailText)
            item.handler = { _, completion in
                if let station = stationsByID[row.stationID] {
                    CarPlayDrivingNavigation.openDrivingDirections(to: station)
                }
                completion()
            }
            return item
        }
        let section = CPListSection(items: items)
        return CPListTemplate(title: String(localized: "carplay.plus.list.title"), sections: [section])
    }
    #endif
}
