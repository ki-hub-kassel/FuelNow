import Foundation

/// Gemeinsame Preis- und Entfernungsformatierung für Tankstellen-UI (Karte, Detail, CarPlay).
///
/// Locale `de_DE`, FuelNow-Zielregion. Preise nutzen den **Tankstellen-Schilder-Stil**
/// `1,58⁹` (TAN-93) — drei Nachkommastellen, dritte Stelle als hochgestelltes
/// Unicode-Superscript. Für rich SwiftUI-Rendering (Pin/Detail/Liste) lieber direkt
/// ``FuelPriceLabel`` verwenden — diese String-API existiert weiter für Slots ohne
/// SwiftUI-`Text` (z. B. CarPlay-`detailText`).
enum StationDisplayFormatting {
    private static let distanceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.numberStyle = .decimal
        return formatter
    }()

    /// Tankstellen-Schilder-Stil als Plain-String — `"1,58⁹"`. Nimmt `Double?` und
    /// liefert `"—"` bei `nil`/0 (TAN-93). Vorher: `"1,58 €"` mit 2 Stellen.
    static func priceString(euros: Double?) -> String {
        FuelPriceFormatting.pumpStyleString(euros: euros)
    }

    static func distanceString(kilometers: Double?) -> String {
        guard let kilometers else {
            return "—"
        }
        let formatted = distanceFormatter.string(from: NSNumber(value: kilometers)) ?? String(format: "%.1f", kilometers)
        return "ca. \(formatted) km"
    }
}
