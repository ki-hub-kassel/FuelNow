import Foundation

/// Gemeinsame Preis- und Entfernungsformatierung für Tankstellen-UI (Karte, Detail, CarPlay).
///
/// Locale `de_DE`, FuelNow-Zielregion. Preise nutzen den **Tankstellen-Schilder-Stil**
/// `1,58⁹` (TAN-93) — drei Nachkommastellen, dritte Stelle als hochgestelltes
/// Unicode-Superscript. Für rich SwiftUI-Rendering (Pin/Detail/Liste) lieber direkt
/// ``FuelPriceLabel`` verwenden — diese String-API existiert weiter für Slots ohne
/// SwiftUI-`Text` (z. B. CarPlay-`detailText`).
enum StationDisplayFormatting {
    private static let germanLocale = Locale(identifier: "de_DE")

    private static let kilometersFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = germanLocale
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.numberStyle = .decimal
        return formatter
    }()

    private static let metersFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = germanLocale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    /// Tankstellen-Schilder-Stil als Plain-String — `"1,58⁹"`. Nimmt `Double?` und
    /// liefert `"—"` bei `nil`/0 (TAN-93). Vorher: `"1,58 €"` mit 2 Stellen.
    static func priceString(euros: Double?) -> String {
        FuelPriceFormatting.pumpStyleString(euros: euros)
    }

    /// Entfernungs-String für UI-Slots ohne SF-Symbol-Vorsatz.
    ///
    /// **Format (TAN-94):**
    /// - `< 1 km` → Meter auf 50 m gerundet, z. B. `"850 m"` (Apple-Maps-Verhalten).
    /// - `>= 1 km` → Kilometer mit einer Nachkommastelle, z. B. `"3,8 km"`.
    /// - `nil` → `"—"`.
    /// - Negative oder nicht-finite Werte werden wie `0` behandelt → `"0 m"`.
    ///
    /// Das frühere `"ca."`-Präfix (TAN-94) entfällt: die Distanz ist offensichtlich
    /// eine Schätzung — im Detail-Sheet signalisiert das vorangestellte
    /// `location.fill`-Symbol das visuell, in CarPlay-`detailText` ist Platz knapp.
    static func distanceString(kilometers: Double?) -> String {
        guard let kilometers, kilometers.isFinite else {
            return "—"
        }
        let safeKilometers = max(kilometers, 0)
        if safeKilometers < 1 {
            let meters = Int((safeKilometers * 1000 / 50).rounded()) * 50
            let formatted = metersFormatter.string(from: NSNumber(value: meters)) ?? "\(meters)"
            return "\(formatted) m"
        }
        let formatted = kilometersFormatter.string(from: NSNumber(value: safeKilometers))
            ?? String(format: "%.1f", safeKilometers)
        return "\(formatted) km"
    }
}
