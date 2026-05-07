import SwiftUI

/// Formatter + SwiftUI-View für Spritpreise im **Tankstellen-Schilder-Stil** (TAN-93).
///
/// Tankerkönig liefert Preise mit drei Nachkommastellen (z. B. `1.589 €`). FuelNow
/// zeigt sie überall mit **allen drei Stellen**, dritte Stelle als Zehntel-Superscript
/// — `1,58⁹` — wie auf deutschen Tankstellen-Schildern üblich (Konvention seit den
/// späten 1960ern, *Tankstellen-Pfennig*; psychologisches Pricing).
///
/// **Output-Modi:**
/// - ``FuelPriceLabel`` — SwiftUI-View; setzt Hauptpreis und Zehntel-Stelle als zwei
///   konkatenierte `Text`-Knoten mit `baselineOffset`. Gibt automatisch ein
///   natürlichsprachliches `accessibilityLabel` mit (`„1 Euro 58,9 Cent"`).
/// - ``pumpStyleString(euros:)`` — Plain-String mit Unicode-Superscript (`"1,58⁹"`),
///   für CarPlay-Listen oder andere String-Slots ohne SwiftUI-`Text`.
/// - ``voiceOverString(euros:)`` — natürlichsprachlich (`"1 Euro 58,9 Cent"`); wird in
///   `accessibilityLabel` und VoiceOver-Voicestrings verwendet, **nicht** in Display-UI.
///
/// **Konvention (TAN-93):** ersetzt die bisherige 2-Nachkommastellen-Anzeige für alle
/// visuellen Preisstellen. Siri/CarPlay-Voice nutzen weiterhin die volle Zahl
/// (`voiceOverString`), nicht das Schilder-Format. Siehe `AGENTS.md`.
enum FuelPriceFormatting {
    private static let germanLocale = Locale(identifier: "de_DE")

    /// Zerlegt einen Tankerkönig-Preis (3 Nachkommastellen) in den Hauptteil `"1,58"` und
    /// die Zehntel-Stelle `"9"` (Komma als de_DE-Dezimaltrenner).
    ///
    /// Liefert `nil` für `nil`/`0`/nicht-finite Werte — Aufrufer rendert dann den
    /// "—"-Platzhalter.
    static func swiftUIComponents(euros: Double?) -> (main: String, tenths: String)? {
        guard let euros, euros > 0, euros.isFinite else { return nil }
        // Auf Zehntel-Cent runden und ganzzahlig splitten — vermeidet Float-Rauschen
        // (`1.589` ist als Double oft `1.5889999…`).
        let totalTenthCents = Int((euros * 1000).rounded())
        let euroPart = totalTenthCents / 1000
        let twoCent = (totalTenthCents % 1000) / 10
        let tenth = totalTenthCents % 10
        let main = String(format: "%d,%02d", euroPart, twoCent)
        return (main, String(tenth))
    }

    /// Schilder-Stil als Plain-String mit Unicode-Superscript-Ziffer (`"1,58⁹"`).
    /// Geeignet für CarPlay-`detailText` und andere reine String-Slots.
    static func pumpStyleString(euros: Double?) -> String {
        guard let parts = swiftUIComponents(euros: euros) else { return "—" }
        let superscript = parts.tenths.compactMap(superscriptDigit).reduce(into: "") { $0.append($1) }
        return parts.main + superscript
    }

    /// VoiceOver-/Siri-freundliche Aussprache aller drei Stellen, z. B.
    /// `"1 Euro 58,9 Cent"`. Bei `nil`/`0` → `"Kein Preis verfügbar"` (gleicher Wortlaut
    /// wie bisher in `StationDetailView`, damit VoiceOver nicht zwei Varianten lernt).
    static func voiceOverString(euros: Double?) -> String {
        guard let euros, euros > 0, euros.isFinite else {
            return "Kein Preis verfügbar"
        }
        let totalTenthCents = Int((euros * 1000).rounded())
        let euroPart = totalTenthCents / 1000
        let centsTenths = Double(totalTenthCents % 1000) / 10.0
        let centsFormatter = NumberFormatter()
        centsFormatter.locale = germanLocale
        centsFormatter.minimumFractionDigits = 1
        centsFormatter.maximumFractionDigits = 1
        let centsString = centsFormatter.string(from: NSNumber(value: centsTenths)) ?? "0,0"
        return "\(euroPart) Euro \(centsString) Cent"
    }

    private static func superscriptDigit(_ char: Character) -> Character? {
        switch char {
        case "0": return "⁰"
        case "1": return "¹"
        case "2": return "²"
        case "3": return "³"
        case "4": return "⁴"
        case "5": return "⁵"
        case "6": return "⁶"
        case "7": return "⁷"
        case "8": return "⁸"
        case "9": return "⁹"
        default: return nil
        }
    }
}

/// Spritpreis im Tankstellen-Schilder-Stil (`1,58⁹`) als SwiftUI-View.
///
/// Rendert Hauptzahl + hochgestellte Zehntel-Stelle als zwei konkatenierte
/// `Text`-Knoten (mit `baselineOffset`). Bei `nil` zeigt sie einen Em-Dash `"—"`.
/// Setzt automatisch ein natürlichsprachliches `accessibilityLabel`, damit
/// VoiceOver die volle Zahl liest und nicht „eins Komma fünfacht hochgestellt neun".
struct FuelPriceLabel: View {
    let euros: Double?
    let prominence: Prominence
    let foreground: Color

    /// Größenstufen — kalibriert pro Render-Slot, damit die Zehntel-Stelle in jedem
    /// Kontext lesbar bleibt (Pin: kleinster Slot, Plus-Hero: größter).
    enum Prominence {
        /// Karten-Pin / Callout — gleicher Body-Schnitt wie heute.
        case compact
        /// Listen-/Detail-Sheet-Default — die Standardhöhe.
        case standard
        /// Vergleichsanzeigen / Plus-Hero — größer und prominenter.
        case display

        var mainFont: Font {
            switch self {
            case .compact: return TRTypography.bodyBold()
            case .standard: return TRTypography.bodyBold()
            case .display: return TRTypography.title2()
            }
        }

        var tenthsFont: Font {
            switch self {
            case .compact: return TRTypography.captionSmall()
            case .standard: return TRTypography.caption()
            case .display: return TRTypography.callout()
            }
        }

        /// Positiver Offset hebt die Zehntel-Stelle hoch (Schilder-Look).
        var tenthsBaselineOffset: CGFloat {
            switch self {
            case .compact: return 4
            case .standard: return 5
            case .display: return 8
            }
        }
    }

    init(
        euros: Double?,
        prominence: Prominence = .standard,
        foreground: Color = TRColors.labelPrimary
    ) {
        self.euros = euros
        self.prominence = prominence
        self.foreground = foreground
    }

    var body: some View {
        priceText
            .foregroundStyle(foreground)
            .accessibilityLabel(FuelPriceFormatting.voiceOverString(euros: euros))
    }

    private var priceText: Text {
        guard let parts = FuelPriceFormatting.swiftUIComponents(euros: euros) else {
            return Text(verbatim: "—").font(prominence.mainFont)
        }
        // iOS 26 deprecated `Text + Text` — Inline-Interpolation eines `Text` in `Text`
        // erhält die Run-Modifier (font/baselineOffset) der inneren Texte.
        let mainRun = Text(verbatim: parts.main).font(prominence.mainFont)
        let tenthsRun = Text(verbatim: parts.tenths)
            .font(prominence.tenthsFont)
            .baselineOffset(prominence.tenthsBaselineOffset)
        return Text("\(mainRun)\(tenthsRun)")
    }
}

// MARK: - Previews

#Preview("FuelPriceLabel · Slots") {
    VStack(spacing: TRSpacing.l) {
        ForEach(
            [
                ("Pin (compact)", FuelPriceLabel.Prominence.compact),
                ("List/Detail (standard)", .standard),
                ("Plus Hero (display)", .display),
            ],
            id: \.0
        ) { label, prominence in
            VStack(alignment: .leading, spacing: TRSpacing.xs) {
                Text(label).font(TRTypography.caption()).foregroundStyle(TRColors.labelSecondary)
                HStack(spacing: TRSpacing.l) {
                    FuelPriceLabel(euros: 1.589, prominence: prominence)
                    FuelPriceLabel(euros: 2.109, prominence: prominence)
                    FuelPriceLabel(euros: nil, prominence: prominence)
                }
            }
        }
    }
    .padding(TRSpacing.l)
    .background(TRColors.background)
}
