import StoreKit
import SwiftUI

/// FuelNow Plus Promo- oder Status-Sektion in den Einstellungen.
enum SettingsPlusFormSections {
    struct Promo: View {
        @Bindable var purchase: PlusPurchaseController
        let plusHeroProduct: Product?
        @Binding var showPlusUpgradeSheet: Bool
        @Binding var showOfferCodeRedemption: Bool
        var onRestore: () async -> Void

        var body: some View {
            Section {
                PlusMiniHero(
                    product: plusHeroProduct,
                    isLoading: plusHeroProduct == nil,
                    trialOffer: purchase.trialOffer,
                    openPlusSheet: { showPlusUpgradeSheet = true }
                )
                .listRowInsets(EdgeInsets(top: TRSpacing.xs, leading: 0, bottom: TRSpacing.xs, trailing: 0))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                Button {
                    showOfferCodeRedemption = true
                } label: {
                    Label("settings.plus.offerCode", systemImage: "giftcard")
                }
                .accessibilityHint(Text("settings.plus.offerCode.hint"))

                Button {
                    Task { await onRestore() }
                } label: {
                    Label("settings.plus.restore", systemImage: "arrow.clockwise")
                }
                .disabled(purchase.isBusy)
                .accessibilityHint("Synchronisiert Käufe mit deinem Apple-ID-Konto.")
            } header: {
                Text("settings.section.plus")
            } footer: {
                Text("settings.plus.footer")
            }
        }
    }

    struct Active: View {
        @Environment(\.openURL) private var openURL
        @Bindable var purchase: PlusPurchaseController
        @Binding var showOfferCodeRedemption: Bool
        var onRestore: () async -> Void

        var body: some View {
            Section {
                Label {
                    Text("settings.plus.status.active")
                        .font(TRTypography.bodyBold())
                } icon: {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(TRColors.accentText)
                }
                .accessibilityElement(children: .combine)

                Button {
                    openURL(AppleSubscriptionPortal.manageAllSubscriptionsURL)
                } label: {
                    Label("settings.plus.manage", systemImage: "creditcard")
                }
                .accessibilityHint("Öffnet die Abonnementverwaltung deines Apple-ID-Kontos.")

                Button {
                    showOfferCodeRedemption = true
                } label: {
                    Label("settings.plus.offerCode", systemImage: "giftcard")
                }
                .accessibilityHint(Text("settings.plus.offerCode.hint"))

                Button {
                    Task { await onRestore() }
                } label: {
                    Label("settings.plus.restore", systemImage: "arrow.clockwise")
                }
                .disabled(purchase.isBusy)
                .accessibilityHint("Synchronisiert Käufe mit deinem Apple-ID-Konto.")
            } header: {
                Text("settings.section.plus")
            } footer: {
                Text("settings.plus.footer")
            }
        }
    }
}
