import AppIntents
import MapKit
import SwiftUI

/// Siri-/Shortcuts-Ergebnis mit Karte, Preis (optional) und Aktionen (Apple Maps / FuelNow).
struct StationSearchResultSnippetView: View {
    let station: Station
    let fuel: FuelType?
    let distanceKm: Double

    private var region: MKCoordinateRegion {
        MKCoordinateRegion(
            center: station.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TRSpacing.s) {
            Map(initialPosition: .region(region), interactionModes: []) {
                Marker(station.name, coordinate: station.coordinate)
            }
            .mapStyle(.standard)
            .frame(height: 128)
            .clipShape(RoundedRectangle(cornerRadius: TRRadius.md, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(String(localized: "intent.snippet.mapAccessibility"))

            Text(station.name)
                .font(TRTypography.headline())
                .foregroundStyle(TRColors.labelPrimary)

            if let fuel {
                HStack(alignment: .firstTextBaseline, spacing: TRSpacing.xs) {
                    Text(fuel.displayName)
                        .font(TRTypography.subheadline())
                        .foregroundStyle(TRColors.labelSecondary)
                    FuelPriceLabel(euros: station.price(for: fuel), prominence: .standard)
                }
                .accessibilityElement(children: .combine)
            }

            Text(String(format: String(localized: String.LocalizationValue("intent.snippet.distanceKm")), locale: .current, distanceKm))
                .font(TRTypography.subheadline())
                .foregroundStyle(TRColors.labelSecondary)

            Text(station.fullAddress)
                .font(TRTypography.caption())
                .foregroundStyle(TRColors.labelTertiary)

            Button(
                intent: StartDrivingNavigationIntent(
                    latitude: station.latitude,
                    longitude: station.longitude,
                    placeName: station.name
                )
            ) {
                Text(LocalizedStringResource("intent.snippet.mapsNavigationButton"))
            }

            Button(intent: OpenStationIntent(station: StationEntity(station: station))) {
                Text(LocalizedStringResource("intent.snippet.showInFuelNowButton"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, TRSpacing.xxs)
    }
}
