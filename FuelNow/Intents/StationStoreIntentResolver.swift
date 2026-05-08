import Foundation

/// Löst Tankstellen-IDs aus dem aktuellen ``StationStore`` auf (Kurzbefehle / `StationQuery`).
struct StationStoreIntentResolver: StationIntentResolving {
    func stations(for ids: [Station.ID]) async throws -> [Station] {
        await MainActor.run {
            guard let store = FuelNowRuntimeRegistry.stationStore else { return [] }
            let wanted = Set(ids)
            return store.stations.filter { wanted.contains($0.id) }
        }
    }
}
