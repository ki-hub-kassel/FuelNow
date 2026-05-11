import StoreKit
import SwiftUI

/// Subscribe / active status / loading fallback for `PlusUpgradeView`.
struct PlusUpgradePurchaseSection: View {
    private enum Timing {
        static let loadingTimeoutSeconds: UInt64 = 8
    }

    @Environment(EntitlementManager.self) private var entitlementManager
    @Bindable var purchase: PlusPurchaseController
    @Binding var selectedUpgradeProductID: String
    @Binding var loadingTimedOut: Bool

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
        Group {
            if entitlementManager.isPlusSubscriber {
                activeSubscriberBlock
            } else if let product = selectedUpgradeProduct {
                purchaseBlock(product: product)
            } else {
                #if DEBUG
                if let mockPrice = purchase.debugMockDisplayPrice {
                    mockPurchaseBlock(mockPrice: mockPrice)
                } else {
                    priceLoadingOrFallback
                }
                #else
                priceLoadingOrFallback
                #endif
            }
        }
    }

    private var activeSubscriberBlock: some View {
        VStack(alignment: .leading, spacing: TRSpacing.s) {
            Label {
                Text("settings.plus.status.active")
                    .font(TRTypography.bodyBold())
            } icon: {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(TRColors.accentText)
            }
            Text("plus.status.active.detail")
                .font(TRTypography.callout())
                .foregroundStyle(TRColors.labelSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func purchaseBlock(product: Product) -> some View {
        VStack(spacing: TRSpacing.s) {
            HStack(alignment: .firstTextBaseline) {
                Text(product.displayPrice)
                    .font(TRTypography.title2())
                Text(product.id == SubscriptionConstants.plusMonthlyProductID
                    ? String(localized: "settings.plus.perMonth")
                    : String(localized: "settings.plus.perYear"))
                    .font(TRTypography.body())
                    .foregroundStyle(TRColors.labelSecondary)
                Spacer()
            }
            .accessibilityElement(children: .combine)

            Button {
                Haptics.tap(.medium)
                Task { await purchase.subscribe(to: product, via: entitlementManager) }
            } label: {
                Group {
                    if purchase.isPurchasing {
                        ProgressView()
                    } else {
                        Text(ctaText)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.trPrimaryGlass)
            .disabled(purchase.isBusy)
            .accessibilityLabel(Text(ctaText))
            .accessibilityHint(ctaAccessibilityHint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func mockPurchaseBlock(mockPrice: String) -> some View {
        VStack(spacing: TRSpacing.s) {
            HStack(alignment: .firstTextBaseline) {
                Text(mockPrice)
                    .font(TRTypography.title2())
                Text(selectedBilling == .monthly
                    ? String(localized: "settings.plus.perMonth")
                    : String(localized: "settings.plus.perYear"))
                    .font(TRTypography.body())
                    .foregroundStyle(TRColors.labelSecondary)
                Spacer()
            }
            .accessibilityElement(children: .combine)

            Button {
                // No-op in mock mode — kein echtes Produkt vorhanden.
            } label: {
                Text(ctaText)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.trPrimaryGlass)
            .disabled(true)
            .accessibilityLabel(Text(ctaText))
            .accessibilityHint(ctaAccessibilityHint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var priceLoadingOrFallback: some View {
        if loadingTimedOut {
            VStack(alignment: .leading, spacing: TRSpacing.xs) {
                Text("settings.plus.priceUnavailable")
                    .font(TRTypography.bodyBold())
                    .foregroundStyle(TRColors.labelPrimary)
                Text("settings.plus.priceUnavailable.hint")
                    .font(TRTypography.caption())
                    .foregroundStyle(TRColors.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        } else {
            HStack(spacing: TRSpacing.s) {
                ProgressView()
                Text("settings.plus.priceLoading")
                    .foregroundStyle(TRColors.labelSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .task {
                try? await Task.sleep(nanoseconds: Timing.loadingTimeoutSeconds * 1_000_000_000)
                if !Task.isCancelled, selectedUpgradeProduct == nil {
                    loadingTimedOut = true
                }
            }
        }
    }

    private var ctaText: String {
        PlusPaywallCopy.ctaLabel(
            audience: audience,
            trialDuration: trialDurationText ?? ""
        )
    }

    private var ctaAccessibilityHint: Text {
        switch audience {
        case .eligibleForTrial:
            Text("plus.sheet.subscribe.trial.a11yHint")
        default:
            Text("plus.sheet.subscribe.a11yHint")
        }
    }
}
