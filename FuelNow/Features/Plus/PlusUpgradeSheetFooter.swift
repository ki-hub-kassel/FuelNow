import StoreKit
import SwiftUI

/// Restore, manage subscription link, and legal footer for the Plus sheet.
struct PlusUpgradeSecondaryActionsSection: View {
    @Environment(\.openURL) private var openURL
    @Environment(EntitlementManager.self) private var entitlementManager
    @Bindable var purchase: PlusPurchaseController

    var body: some View {
        VStack(alignment: .leading, spacing: TRSpacing.s) {
            Button {
                Haptics.tap(.light)
                Task { await purchase.restore(via: entitlementManager) }
            } label: {
                Label("settings.plus.restore", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .disabled(purchase.isBusy)
            .foregroundStyle(TRColors.accentText)
            .accessibilityHint("Synchronisiert Käufe mit deinem Apple-ID-Konto.")

            Button {
                Haptics.tap(.light)
                openURL(AppleSubscriptionPortal.manageAllSubscriptionsURL)
            } label: {
                Label("settings.plus.manage", systemImage: "creditcard")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .foregroundStyle(TRColors.accentText)
            .accessibilityHint("Öffnet die Abonnementverwaltung deines Apple-ID-Kontos.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PlusUpgradeFineprintSection: View {
    let footerText: String

    var body: some View {
        VStack(alignment: .leading, spacing: TRSpacing.xxs) {
            Text(footerText)
                .font(TRTypography.caption())
                .foregroundStyle(TRColors.labelSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
