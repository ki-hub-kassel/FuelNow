import Foundation

/// Entscheidet zwischen Live-Tankerkönig und Bund-Mock — siehe `makeDefault()`.
@MainActor
enum StationStoreFactory {
    /// **Mock erzwingen:** Scheme → Run → Environment → `TANKRADAR_USE_MOCK_STATIONS` = `1`
    ///
    /// **Live erzwingen (DEBUG):** `TANKRADAR_USE_LIVE_STATIONS` = `1` (z. B. API-Fehlerpfad testen).
    ///
    /// **Ohne Flag:** Release immer Live. Debug fällt auf Mock zurück, wenn kein gültiger API-Key gesetzt ist (leer oder Platzhalter).
    static func makeDefault() -> StationStore {
        let env = ProcessInfo.processInfo.environment

        if env["TANKRADAR_USE_MOCK_STATIONS"] == "1" {
            logMock(reason: "TANKRADAR_USE_MOCK_STATIONS=1")
            return StationStore(fetcher: BundledMockStationFetcher())
        }

        if env["TANKRADAR_USE_LIVE_STATIONS"] == "1" {
            #if DEBUG
            logLive(reason: "TANKRADAR_USE_LIVE_STATIONS=1")
            #endif
            return StationStore()
        }

        #if DEBUG
        if !isConfiguredTankerkoenigKey {
            logMock(reason: "DEBUG ohne gültigen Tankerkönig-Key (siehe APIKeys.example.swift)")
            return StationStore(fetcher: BundledMockStationFetcher())
        }
        #endif

        return StationStore()
    }

    private static var isConfiguredTankerkoenigKey: Bool {
        let trimmed = APIKeys.tankerkoenig.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed != "PASTE_YOUR_KEY_HERE"
    }

    #if DEBUG
    private static func logMock(reason: String) {
        print("TankRadar: Mock-Tankstellen aktiv — \(reason). Daten: MockData/mock-stations.json")
    }

    private static func logLive(reason: String) {
        print("TankRadar: Live Tankerkönig — \(reason)")
    }
    #endif
}
