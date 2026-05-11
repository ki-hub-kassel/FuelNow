import CoreLocation
import SwiftUI

/// Status-Punkt, Öffnungszeilen und Entfernung unter der Toolbar.
///
/// Entfernung liest ``LocationService`` nur hier — nicht in ``StationDetailView`` — damit GPS-Updates
/// nicht die gesamte Navigation inkl. Schließen-Toolbar neu binden (verhindert „erst beim 2. Tap“).
struct StationDetailStatusDistanceRow: View {
    @Environment(LocationService.self) private var locationService

    let resolvedStation: Station
    let openHoursSubtitle: String?
    let showsOpeningHoursInfo: Bool
    let statusAccessibilityLabel: String
    @Binding var showOpeningHoursPopover: Bool

    private var distanceLabel: String {
        let dynamicDistanceKm = locationService.currentLocation.map { userLocation in
            let stationLocation = CLLocation(latitude: resolvedStation.latitude, longitude: resolvedStation.longitude)
            return userLocation.distance(from: stationLocation) / 1000
        }
        return StationDisplayFormatting.distanceString(
            kilometers: dynamicDistanceKm ?? resolvedStation.distanceKilometers
        )
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: TRSpacing.m) {
            HStack(alignment: .top, spacing: TRSpacing.s) {
                Circle()
                    .fill(resolvedStation.isOpen ? TRColors.success : TRColors.danger)
                    .frame(width: 12, height: 12)
                    .overlay {
                        Circle()
                            .strokeBorder(TRColors.labelPrimary.opacity(0.12), lineWidth: 1)
                    }
                    .padding(.top, 3)
                    .accessibilityHidden(true)

                HStack(alignment: .firstTextBaseline, spacing: TRSpacing.xs) {
                    VStack(alignment: .leading, spacing: TRSpacing.xxs) {
                        Text(
                            resolvedStation.isOpen
                                ? String(localized: "station.status.open")
                                : String(localized: "station.status.closed")
                        )
                        .font(TRTypography.callout())
                        .fontWeight(.semibold)
                        .foregroundStyle(resolvedStation.isOpen ? TRColors.success : TRColors.danger)

                        if let openHoursSubtitle {
                            Text(openHoursSubtitle)
                                .font(TRTypography.caption())
                                .foregroundStyle(TRColors.labelSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(statusAccessibilityLabel)

                    if showsOpeningHoursInfo {
                        Button {
                            Haptics.tap(.light)
                            showOpeningHoursPopover = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(TRTypography.callout().weight(.medium))
                                .foregroundStyle(TRColors.accentText.opacity(0.92))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(String(localized: "station.openingHours.info.accessibilityLabel"))
                        .accessibilityHint(String(localized: "station.openingHours.info.accessibilityHint"))
                    }
                }
            }

            Spacer(minLength: TRSpacing.s)

            HStack(spacing: TRSpacing.xxs) {
                Image(systemName: "location.fill")
                    .font(TRTypography.callout())
                    .foregroundStyle(TRColors.labelSecondary)
                    .accessibilityHidden(true)
                Text(distanceLabel)
                    .font(TRTypography.callout())
                    .foregroundStyle(TRColors.labelSecondary)
                    .multilineTextAlignment(.trailing)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Entfernung, \(distanceLabel)")
        }
    }
}
