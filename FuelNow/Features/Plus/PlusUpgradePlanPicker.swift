import StoreKit
import SwiftUI

/// Zwei Abo-Stufen (Jahr bevorzugt) mit klarer visueller Auswahl vor dem Kauf-CTA.
struct PlusUpgradePlanPicker: View {
    let yearly: Product?
    let monthly: Product?
    @Binding var selectedProductID: String

    var body: some View {
        VStack(alignment: .leading, spacing: TRSpacing.s) {
            Text("plus.planPicker.title")
                .font(TRTypography.bodyBold())
                .foregroundStyle(TRColors.labelPrimary)

            if let yearly {
                planRow(
                    product: yearly,
                    badge: String(localized: "plus.planPicker.badge.yearBest"),
                    periodFooter: String(localized: "settings.plus.perYear")
                )
            }
            if let monthly {
                planRow(
                    product: monthly,
                    badge: nil,
                    periodFooter: String(localized: "settings.plus.perMonth")
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func planRow(product: Product, badge: String?, periodFooter: String) -> some View {
        let selected = selectedProductID == product.id
        Button {
            Haptics.tap(.light)
            selectedProductID = product.id
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: TRSpacing.m) {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .font(.title3)
                    .foregroundStyle(selected ? TRColors.accentText : TRColors.labelSecondary)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: TRSpacing.xxs) {
                    HStack(spacing: TRSpacing.xs) {
                        Text(product.displayPrice)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(TRColors.labelPrimary)
                            .monospacedDigit()
                        Text(periodFooter)
                            .font(TRTypography.callout())
                            .foregroundStyle(TRColors.labelSecondary)
                        if let badge {
                            Text(badge)
                                .font(TRTypography.captionSmall())
                                .textCase(.uppercase)
                                .padding(.horizontal, TRSpacing.xs)
                                .padding(.vertical, TRSpacing.xxs)
                                .background(TRColors.accent.opacity(0.15), in: Capsule(style: .continuous))
                                .foregroundStyle(TRColors.accentText)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(TRSpacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                selected ? TRColors.accent.opacity(0.08) : TRColors.backgroundTertiary,
                in: RoundedRectangle(cornerRadius: TRRadius.lg, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: TRRadius.lg, style: .continuous)
                    .strokeBorder(selected ? TRColors.accent.opacity(0.45) : TRColors.labelSecondary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityLabel(accessibilityLabel(for: product, period: periodFooter, selected: selected))
    }

    private func accessibilityLabel(for product: Product, period: String, selected: Bool) -> String {
        let state = selected ? String(localized: "plus.planPicker.a11y.selected") : String(localized: "plus.planPicker.a11y.unselected")
        return "\(product.displayPrice) \(period). \(state)"
    }
}
