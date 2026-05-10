import CoreSpotlight
import Foundation
import os.log

/// Indexiert eine begrenzte Teilmenge von Tankstellen für Spotlight (`IndexedEntity` + benannter Index).
///
/// **Datenschutz / Nutzertransparenz:** Es werden nur öffentliche Tankstellen-Metadaten aus Tankerkönig
/// (Name, Adresse, Pumpenpreis für die eingestellte Sorte) indexiert — keine Rohkoordinaten im
/// sichtbaren Beschreibungstext. Ortung der Nutzerperson erfolgt hierüber nicht.
enum StationSpotlightIndexer {
    private static let indexName = "FuelNow_StationAppEntities"
    private static let maxEntities = 48
    private static let log = Logger(subsystem: "com.vibecoding.fuelnow", category: "SpotlightIndex")
    /// Debounce-Handle — nur Start/Cancel; keine App-State-Daten.
    nonisolated(unsafe) private static var pendingTask: Task<Void, Never>?

    /// Debounced Reindex nach Stationsliste oder Sortenwechsel (mindert API-/CPU-Last).
    @MainActor
    static func scheduleReindex(stations: [Station], preferredFuel: FuelType) {
        pendingTask?.cancel()
        let snapshot = stations
        let fuel = preferredFuel
        pendingTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(800))
            guard !Task.isCancelled else { return }
            await performIndex(stations: snapshot, preferredFuel: fuel)
        }
    }

    @MainActor
    private static func performIndex(stations: [Station], preferredFuel: FuelType) async {
        let subset = Array(stations.prefix(maxEntities))
        let entities = subset.map { station in
            StationEntity(station: station, indexingDetailLine: indexingLine(for: station, fuel: preferredFuel))
        }
        do {
            try await CSSearchableIndex(name: indexName).indexAppEntities(entities)
        } catch {
            log.error("Spotlight indexAppEntities failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private static func indexingLine(for station: Station, fuel: FuelType) -> String {
        let address = station.fullAddress
        if let price = station.price(for: fuel) {
            let pump = FuelPriceFormatting.pumpStyleString(euros: price)
            return "\(fuel.displayName) \(pump) · \(address)"
        }
        return address
    }
}
