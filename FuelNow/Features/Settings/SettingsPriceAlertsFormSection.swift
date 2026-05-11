import SwiftUI
import UIKit
import UserNotifications

/// Preisalarme-Toggle und Schwelle (FuelNow Plus).
struct SettingsPriceAlertsFormSection: View {
    @Environment(\.openURL) private var openURL
    @Environment(EntitlementManager.self) private var entitlementManager
    @Binding var showPlusUpgradeSheet: Bool
    @Binding var priceAlertsEnabled: Bool
    @Binding var priceAlertsThresholdEuros: Double
    @Binding var notificationAuthStatus: UNAuthorizationStatus

    var body: some View {
        Section {
            if entitlementManager.hasPlusBenefits {
                Toggle(isOn: $priceAlertsEnabled) {
                    Label("Preis-Pushes (Beta)", systemImage: "bell.badge")
                }
                .tint(TRColors.accent)
                .accessibilityHint("Schickt eine Benachrichtigung, wenn ein Favorit deutlich günstiger wird.")
                .onChange(of: priceAlertsEnabled) { _, newValue in
                    guard newValue else { return }
                    Task { await handlePriceAlertsToggleEnabled() }
                }

                if priceAlertsEnabled {
                    Picker(selection: $priceAlertsThresholdEuros) {
                        Text("3 Cent").tag(0.03)
                        Text("5 Cent").tag(0.05)
                        Text("10 Cent").tag(0.10)
                    } label: {
                        Label("Schwelle", systemImage: "arrow.down.right")
                    }
                    .accessibilityHint("Mindestpreissturz, ab dem ein Push verschickt wird.")
                }

                if priceAlertsEnabled, notificationAuthStatus == .denied {
                    Button(role: .none) {
                        openNotificationSystemSettings()
                    } label: {
                        Label("Mitteilungen in Systemeinstellungen erlauben", systemImage: "gear")
                            .foregroundStyle(TRColors.accent)
                    }
                    .accessibilityHint("Öffnet die FuelNow-Seite in den iOS-Einstellungen.")
                }
            } else {
                Text("plus.gated.priceAlerts.footer")
                    .font(TRTypography.caption())
                    .foregroundStyle(TRColors.labelSecondary)
                Button {
                    Haptics.tap(.light)
                    showPlusUpgradeSheet = true
                } label: {
                    Label("plus.gated.favorites.openPlus", systemImage: "sparkles")
                        .foregroundStyle(TRColors.accentText)
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("plus.gated.priceAlerts.title")
        } footer: {
            priceAlertsFooter
        }
    }

    private var priceAlertsFooter: some View {
        Text(priceAlertsFooterText)
            .font(TRTypography.caption())
            .foregroundStyle(TRColors.labelSecondary)
    }

    private var priceAlertsFooterText: String {
        let baseHint = "Beta — läuft lokal im Hintergrund. iOS bestimmt, wie oft die App nachsehen darf."
        guard entitlementManager.hasPlusBenefits else {
            return String(localized: "plus.gated.priceAlerts.footer")
        }
        guard priceAlertsEnabled else { return baseHint }
        switch notificationAuthStatus {
        case .denied:
            let denied = "Mitteilungen sind für FuelNow in den Systemeinstellungen deaktiviert — "
                + "Pushes kommen erst an, wenn du sie dort wieder erlaubst."
            return baseHint + "\n\n" + denied
        default:
            return baseHint
        }
    }

    private func handlePriceAlertsToggleEnabled() async {
        let granted = await PriceAlertCoordinator.requestNotificationAuthorizationIfNeeded()
        notificationAuthStatus = await PriceAlertCoordinator.currentAuthorizationStatus()
        if !granted {
            await MainActor.run { priceAlertsEnabled = false }
        }
    }

    private func openNotificationSystemSettings() {
        Haptics.tap(.light)
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}
