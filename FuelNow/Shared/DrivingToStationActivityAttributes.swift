import ActivityKit
import Foundation

/// `ActivityAttributes` fuer die Live Activity „Fahrt zu Tankstelle …" (Roadmap Phase 5).
///
/// **Architektur:**
/// - **Static attributes** (`stationName`, `brandTitle`, `pumpPriceText`, `fuelDisplayName`):
///   bleiben fuer die Lebensdauer der Activity konstant — sie werden nur beim Start in
///   `ActivityKit` reingegeben und vom Lock-Screen / der Dynamic Island gelesen.
/// - **Dynamic state** (`distanceText`, `etaText`, `endsAt`): kann waehrend der Fahrt mit
///   `Activity.update(...)` veraendert werden, sobald wir spaeter Live-Distanz nachschieben.
///   In der ersten MVP-Auspraegung beendet sich die Activity nach `endsAt` automatisch.
///
/// Die Datei liegt im `FuelNow/Shared/`-Pfad und wird sowohl von der App (Activity-Start)
/// als auch von der Widget-Extension (Live-Activity-Renderer) compiliert.
struct DrivingToStationActivityAttributes: ActivityAttributes {
    typealias ContentState = DrivingState

    /// Tankerkoenig-Stations-UUID — erlaubt Deep-Link / Disambiguierung in der Live Activity.
    let stationID: UUID
    /// Marke (oder Stationsname als Fallback) — Headline der Activity.
    let brandTitle: String
    /// Voller Stationsname fuer Accessibility / VoiceOver.
    let stationName: String
    /// Schilder-Stil-Preis der bevorzugten Sorte (z. B. `"1,58⁹"`).
    let pumpPriceText: String
    /// Anzeigename der bevorzugten Sorte (z. B. `"Super E10"`).
    let fuelDisplayName: String

    struct DrivingState: Codable, Hashable, Sendable {
        /// Anzeige-Distanz (z. B. `"2,3 km"`); Server-/Lokal-Update setzt das frisch.
        var distanceText: String
        /// Sekundaere ETA-Anzeige (z. B. `"ca. 5 Min"`). Optional, weil die App keine
        /// Routenberechnung selbst macht — Apple Maps haendelt die echte ETA.
        var etaText: String?
        /// Zeitpunkt, bis zu dem die Activity laufen darf; danach beendet der App-Start
        /// oder ein Watchdog die Activity per `Activity.end(...)`.
        var endsAt: Date

        init(distanceText: String, etaText: String? = nil, endsAt: Date) {
            self.distanceText = distanceText
            self.etaText = etaText
            self.endsAt = endsAt
        }
    }
}
