import AppIntents
import SwiftUI

/// Result-Snippet für Siri/Shortcuts (TAN-96): zweistufiges Layout im Stil des Apple
/// WWDC25-Samples ([Design interactive snippets](https://developer.apple.com/videos/play/wwdc2025/281/))
/// — dunkler Brand-Header mit Headline + Hero-Metrik, helle Detail-Sub-Card mit
/// Stationsname/Adresse/Total-Row, Action-Footer mit zwei System-Buttons.
///
/// **Bewusst keine `Map`/`MKMapSnapshotter` und kein `glassEffect`**: SwiftUI
/// `Map` rendert in der App-Intents-Sandbox nicht zuverlässig (Apple-Forum-Thread
/// 711057, „Failed to serialize PlatformViewRepresentableAdaptor"); auch
/// Liquid-Glass-Surfaces können in Snippets brüchig sein. Wir bleiben bewusst
/// auf System-Surfaces (`RoundedRectangle` + `Color`) und System-Buttons
/// (`.bordered` / `.borderedProminent`). Die Haupt-App nutzt weiter Liquid Glass.
struct StationSearchResultSnippetView: View {
    /// Welcher Intent das Snippet erzeugt — bestimmt Headline und Hero-Metrik.
    enum Mode {
        /// `FindNearestStationIntent`: Distanz wird Hero, Preis (falls vorhanden) wandert in die Sub-Card.
        case nearest(preferredFuel: FuelType?)
        /// `FindCheapestStationIntent`: Pumpstyle-Preis wird Hero, Distanz wandert in die Sub-Card.
        case cheapest(fuel: FuelType)
    }

    let station: Station
    let mode: Mode
    let distanceKm: Double

    /// Brand-Header-Surface. `TRColors.accentText` flippt im Dark Mode auf hellen Teal
    /// und scheidet als Surface aus — wir hardcoden den Light-Mode-Wert (`TRPaletteHex.accentText`)
    /// als RGB, damit der Header in Light + Dark dunkel bleibt und der weiße Foreground AAA-Kontrast erfüllt.
    private static let brandHeaderSurface = Color(red: 0.06, green: 0.34, blue: 0.31)

    /// Marke wenn vorhanden, sonst voller Stationsname — analog `navigationBarBrandTitle` im
    /// Detail-Sheet, damit Snippet und App dieselbe Heuristik nutzen.
    private var brandTitle: String {
        let trimmed = station.brand.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? station.name : trimmed
    }

    private var statusLabel: String {
        station.isOpen
            ? String(localized: "station.status.open")
            : String(localized: "station.status.closed")
    }

    private var statusColor: Color {
        station.isOpen ? TRColors.success : TRColors.danger
    }

    private var distanceLabel: String {
        StationDisplayFormatting.distanceString(kilometers: distanceKm)
    }

    private var sideCardPrice: Double? {
        switch mode {
        case .cheapest:
            return nil
        case let .nearest(preferredFuel):
            guard let preferredFuel else { return nil }
            return station.price(for: preferredFuel)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TRSpacing.m) {
            brandHeader
            detailCard
            actionFooter
        }
        .padding(TRSpacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerShape(ContainerRelativeShape())
        .accessibilityElement(children: .contain)
        .accessibilityLabel(combinedAccessibilityLabel)
    }

    // MARK: - Tier 1: Brand-Header

    private var brandHeader: some View {
        HStack(alignment: .top, spacing: TRSpacing.m) {
            VStack(alignment: .leading, spacing: TRSpacing.xxs) {
                Text(headerHeadline)
                    .font(TRTypography.headline())
                    .foregroundStyle(.white)
                    .accessibilityAddTraits(.isHeader)

                Text(headerSubtitle)
                    .font(TRTypography.caption())
                    .foregroundStyle(.white.opacity(0.75))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: TRSpacing.xxs) {
                heroValue
                Text(heroCaption)
                    .font(TRTypography.captionSmall())
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
        .padding(TRSpacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: TRRadius.lg, style: .continuous)
                .fill(Self.brandHeaderSurface)
        )
    }

    private var headerHeadline: String {
        switch mode {
        case let .cheapest(fuel):
            let format = String(localized: "intent.snippet.cheapest.headline")
            return String(format: format, locale: .current, fuel.displayName)
        case .nearest:
            return String(localized: "intent.snippet.nearest.headline")
        }
    }

    private var headerSubtitle: String {
        switch mode {
        case .cheapest:
            return String(localized: "intent.snippet.cheapest.headerSub")
        case .nearest:
            return statusLabel
        }
    }

    @ViewBuilder
    private var heroValue: some View {
        switch mode {
        case let .cheapest(fuel):
            FuelPriceLabel(
                euros: station.price(for: fuel),
                prominence: .display,
                foreground: .white
            )
        case .nearest:
            Text(distanceLabel)
                .font(TRTypography.title2())
                .foregroundStyle(.white)
        }
    }

    private var heroCaption: String {
        switch mode {
        case .cheapest:
            String(localized: "intent.snippet.heroPriceCaption")
        case .nearest:
            String(localized: "intent.snippet.heroDistanceCaption")
        }
    }

    // MARK: - Tier 2: Detail-Sub-Card

    private var detailCard: some View {
        HStack(alignment: .top, spacing: TRSpacing.s) {
            Image(systemName: "fuelpump.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(TRColors.accent)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: TRSpacing.xs) {
                Text(brandTitle)
                    .font(TRTypography.bodyBold())
                    .foregroundStyle(TRColors.labelPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                if !station.fullAddress.isEmpty {
                    Text(station.fullAddress)
                        .font(TRTypography.caption())
                        .foregroundStyle(TRColors.labelTertiary)
                        .lineLimit(2)
                }

                Divider()
                    .padding(.vertical, TRSpacing.xxs)

                detailTotalRow
            }
        }
        .padding(TRSpacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: TRRadius.lg, style: .continuous)
                .fill(TRColors.backgroundTertiary)
        )
    }

    private var detailTotalRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: TRSpacing.s) {
            switch mode {
            case .cheapest:
                statusBadge
                Spacer(minLength: TRSpacing.xs)
                HStack(spacing: TRSpacing.xxs) {
                    Image(systemName: "location.fill")
                        .font(TRTypography.subheadline())
                        .foregroundStyle(TRColors.labelSecondary)
                        .accessibilityHidden(true)
                    Text(distanceLabel)
                        .font(TRTypography.subheadline())
                        .foregroundStyle(TRColors.labelSecondary)
                }
            case let .nearest(preferredFuel):
                if let preferredFuel {
                    Text(preferredFuel.displayName)
                        .font(TRTypography.subheadline())
                        .foregroundStyle(TRColors.labelSecondary)
                    Spacer(minLength: TRSpacing.xs)
                    FuelPriceLabel(
                        euros: sideCardPrice,
                        prominence: .standard,
                        foreground: TRColors.labelPrimary
                    )
                } else {
                    statusBadge
                    Spacer(minLength: TRSpacing.xs)
                }
            }
        }
    }

    private var statusBadge: some View {
        HStack(spacing: TRSpacing.xs) {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .strokeBorder(TRColors.labelPrimary.opacity(0.12), lineWidth: 1)
                )
                .accessibilityHidden(true)
            Text(statusLabel)
                .font(TRTypography.subheadline())
                .foregroundStyle(TRColors.labelSecondary)
        }
    }

    // MARK: - Action-Footer

    private var actionFooter: some View {
        HStack(spacing: TRSpacing.s) {
            Button(intent: OpenStationIntent(station: StationEntity(station: station))) {
                Label(
                    String(localized: "intent.snippet.showInFuelNowButton"),
                    systemImage: "fuelpump.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button(
                intent: StartDrivingNavigationIntent(
                    latitude: station.latitude,
                    longitude: station.longitude,
                    placeName: station.name
                )
            ) {
                Label(
                    String(localized: "intent.snippet.mapsNavigationButton"),
                    systemImage: "location.north.line.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(TRColors.accent)
        }
    }

    // MARK: - Accessibility

    private var combinedAccessibilityLabel: String {
        var parts: [String] = []
        switch mode {
        case let .cheapest(fuel):
            parts.append(String(
                format: String(localized: "intent.snippet.cheapest.headline"),
                locale: .current,
                fuel.displayName
            ))
            let voicePrice = FuelPriceFormatting.voiceOverString(euros: station.price(for: fuel))
            parts.append(voicePrice)
        case let .nearest(preferredFuel):
            parts.append(String(localized: "intent.snippet.nearest.headline"))
            if let preferredFuel {
                let voicePrice = FuelPriceFormatting.voiceOverString(
                    euros: station.price(for: preferredFuel)
                )
                parts.append("\(preferredFuel.displayName), \(voicePrice)")
            }
        }
        parts.append(station.name)
        parts.append(statusLabel)
        let format = String(localized: "intent.snippet.distanceVoice")
        parts.append(String(format: format, locale: .current, distanceKm))
        return parts.joined(separator: ", ")
    }
}
