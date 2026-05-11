import StoreKit
import SwiftUI

/// Optionales Upgrade-Sheet für FuelNow Plus.
///
/// Reine Opt-in-Surface: wird ausschließlich aus den Einstellungen heraus geöffnet
/// („Was ist FuelNow Plus?"). Es gibt **keine** automatische Einblendung und keinen
/// Nag-Banner — Trial-Copy erscheint nur, wenn der Apple-Kunde nachweislich eligibel
/// ist (`Product.SubscriptionInfo.isEligibleForIntroOffer`, TAN-81).
struct PlusUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(EntitlementManager.self) private var entitlementManager

    @State private var purchase = PlusPurchaseController()

    @State private var loadingTimedOut = false
    @State private var selectedUpgradeProductID = SubscriptionConstants.plusYearlyProductID

    private var plusYearlyProduct: Product? {
        entitlementManager.products.first { $0.id == SubscriptionConstants.plusYearlyProductID }
    }

    private var plusMonthlyProduct: Product? {
        entitlementManager.products.first { $0.id == SubscriptionConstants.plusMonthlyProductID }
    }

    private var selectedUpgradeProduct: Product? {
        entitlementManager.products.first { $0.id == selectedUpgradeProductID }
    }

    private var selectedBilling: PlusPaywallCopy.PlusBillingPeriod {
        selectedUpgradeProductID == SubscriptionConstants.plusMonthlyProductID ? .monthly : .yearly
    }

    private var audience: PlusPaywallCopy.Audience {
        PlusPaywallCopy.audience(
            isSubscriber: entitlementManager.isPlusSubscriber,
            trialOffer: purchase.trialOffer
        )
    }

    private var trialDurationText: String? {
        guard let trial = purchase.trialOffer else { return nil }
        return PlusPaywallCopy.formattedTrialDuration(offer: trial)
    }

    private var displayPriceText: String? {
        if let product = selectedUpgradeProduct {
            return product.displayPrice
        }
        #if DEBUG
        return purchase.debugMockDisplayPrice
        #else
        return nil
        #endif
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: TRSpacing.l) {
                    heroSection
                    trialBlock
                    if !entitlementManager.isPlusSubscriber,
                       plusYearlyProduct != nil || plusMonthlyProduct != nil {
                        PlusUpgradePlanPicker(
                            yearly: plusYearlyProduct,
                            monthly: plusMonthlyProduct,
                            selectedProductID: $selectedUpgradeProductID
                        )
                    }
                    PlusUpgradeBenefitsSection()
                    PlusUpgradePurchaseSection(
                        purchase: purchase,
                        selectedUpgradeProductID: $selectedUpgradeProductID,
                        loadingTimedOut: $loadingTimedOut
                    )
                    PlusUpgradeSecondaryActionsSection(purchase: purchase)
                    PlusUpgradeFineprintSection(footerText: footerText)
                }
                .padding(TRSpacing.m)
                .padding(.bottom, TRSpacing.l)
            }
            .navigationTitle(Text("plus.sheet.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(TRColors.labelSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("plus.sheet.close")
                    .accessibilityHint("Schließt das FuelNow-Plus-Fenster.")
                }
            }
            .task {
                #if DEBUG
                purchase.applyDebugMockIfRequested()
                #endif
                await entitlementManager.loadProducts()
                syncSelectedProductIDWithCatalog()
                if let product = plusYearlyProduct ?? plusMonthlyProduct {
                    await purchase.refreshTrialOffer(for: product)
                }
            }
            .alert(
                Text("settings.plus.alert.title"),
                isPresented: Binding(
                    get: { purchase.alertMessage != nil },
                    set: { if !$0 { purchase.alertMessage = nil } }
                ),
                actions: {
                    Button("settings.plus.alert.ok", role: .cancel) {
                        purchase.alertMessage = nil
                    }
                },
                message: {
                    if let message = purchase.alertMessage {
                        Text(message)
                    }
                }
            )
        }
    }

    private func syncSelectedProductIDWithCatalog() {
        let ids = Set(entitlementManager.products.map(\.id))
        if ids.contains(selectedUpgradeProductID) { return }
        if ids.contains(SubscriptionConstants.plusYearlyProductID) {
            selectedUpgradeProductID = SubscriptionConstants.plusYearlyProductID
        } else if let first = entitlementManager.products.first {
            selectedUpgradeProductID = first.id
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: TRSpacing.s) {
            Text("plus.hero.eyebrow")
                .font(TRTypography.caption())
                .textCase(.uppercase)
                .foregroundStyle(TRColors.accentText)
                .accessibilityAddTraits(.isHeader)

            Text("plus.hero.headline")
                .font(TRTypography.title())
                .foregroundStyle(TRColors.labelPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("plus.hero.subhead")
                .font(TRTypography.body())
                .foregroundStyle(TRColors.labelSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var trialBlock: some View {
        if let price = displayPriceText,
           let duration = trialDurationText,
           let headline = PlusPaywallCopy.trialHeadline(
               audience: audience,
               trialDuration: duration,
               displayPrice: price,
               billing: selectedBilling
           )
        {
            HStack(alignment: .top, spacing: TRSpacing.s) {
                Image(systemName: "gift.fill")
                    .font(TRTypography.title2())
                    .foregroundStyle(TRColors.accentText)
                    .accessibilityHidden(true)

                Text(headline)
                    .font(TRTypography.bodyBold())
                    .foregroundStyle(TRColors.labelPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(TRSpacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                TRColors.accent.opacity(0.10),
                in: RoundedRectangle(cornerRadius: TRRadius.lg, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: TRRadius.lg, style: .continuous)
                    .strokeBorder(TRColors.accent.opacity(0.35), lineWidth: 1)
            )
            .accessibilityElement(children: .combine)
        }
    }

    private var footerText: String {
        let price = displayPriceText ?? ""
        return PlusPaywallCopy.footer(audience: audience, displayPrice: price, billing: selectedBilling)
    }
}

#Preview("Light") {
    PlusUpgradeView()
        .environment(EntitlementManager())
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    PlusUpgradeView()
        .environment(EntitlementManager())
        .preferredColorScheme(.dark)
}

#Preview("Accessibility 3") {
    PlusUpgradeView()
        .environment(EntitlementManager())
        .environment(\.dynamicTypeSize, .accessibility3)
}
