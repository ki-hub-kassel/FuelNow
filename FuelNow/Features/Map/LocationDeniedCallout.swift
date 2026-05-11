import SwiftUI
import UIKit

/// Vollflächige Erläuterung bei verweigertem oder eingeschränktem Standortzugriff (TAN-21).
struct LocationDeniedCallout: View {
    /// Öffnet das In-App-Einstellungs-Sheet (Spritart, Radius, Datenquelle).
    var openInAppSettings: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var scrimOpacity: Double {
        colorScheme == .dark ? 0.58 : 0.35
    }

    var body: some View {
        ZStack {
            Color.black.opacity(scrimOpacity)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            ContentUnavailableView {
                Label("Standort nicht erlaubt", systemImage: "location.slash.fill")
            } description: {
                Text(
                    "FuelNow braucht deinen Standort, um Tankstellen in der Nähe zu laden. "
                        + "Erlaube unter iOS-Einstellungen → FuelNow → Standort die Option „Beim Verwenden der App“."
                )
                .multilineTextAlignment(.center)
                .accessibilityLabel(
                    "FuelNow braucht deinen Standort, um Tankstellen in der Nähe zu laden. "
                        + "Erlaube unter iOS-Einstellungen, FuelNow, Standort die Option Beim Verwenden der App."
                )
            } actions: {
                Button("iOS-Einstellungen öffnen") {
                    openSystemSettings()
                }
                .buttonStyle(TRPrimaryGlassButtonStyle())

                Button("FuelNow-Einstellungen") {
                    openInAppSettings()
                }
                .buttonStyle(TRSoftButtonStyle())
            }
            .padding(TRSpacing.l)
            .background(
                RoundedRectangle(cornerRadius: TRRadius.xl, style: .continuous)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: TRRadius.xl, style: .continuous)
                    .strokeBorder(TRColors.separator.opacity(0.6), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.55 : 0.18), radius: 28, y: 12)
            .padding(TRSpacing.m)
        }
        .accessibilityElement(children: .contain)
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview("Denied callout") {
    LocationDeniedCallout(openInAppSettings: {})
}
