import SwiftUI

/// Benefit rows for the Plus paywall (CarPlay row omitted when capability is off).
struct PlusUpgradeBenefit: Identifiable {
    let id: String
    let systemImage: String
    let title: LocalizedStringResource
    let description: LocalizedStringResource

    static let catalog: [PlusUpgradeBenefit] = [
        PlusUpgradeBenefit(
            id: "carplay",
            systemImage: "car.fill",
            title: "plus.benefit.carplay.title",
            description: "plus.benefit.carplay.description"
        ),
        PlusUpgradeBenefit(
            id: "favorites",
            systemImage: "bell.badge.fill",
            title: "plus.benefit.favorites.title",
            description: "plus.benefit.favorites.description"
        ),
        PlusUpgradeBenefit(
            id: "future",
            systemImage: "sparkles",
            title: "plus.benefit.future.title",
            description: "plus.benefit.future.description"
        ),
    ]

    static var paywallBenefits: [PlusUpgradeBenefit] {
        catalog.filter { benefit in
            benefit.id != "carplay" || FuelNowFeatureFlags.isCarPlayCapabilityEnabled
        }
    }
}

struct PlusUpgradeBenefitsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: TRSpacing.m) {
            ForEach(PlusUpgradeBenefit.paywallBenefits) { benefit in
                PlusUpgradeBenefitRow(benefit: benefit)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PlusUpgradeBenefitRow: View {
    let benefit: PlusUpgradeBenefit

    var body: some View {
        HStack(alignment: .top, spacing: TRSpacing.m) {
            Image(systemName: benefit.systemImage)
                .font(.title2)
                .foregroundStyle(TRColors.accentText)
                .frame(width: 32, height: 32, alignment: .center)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: TRSpacing.xxs) {
                Text(benefit.title)
                    .font(TRTypography.bodyBold())
                    .foregroundStyle(TRColors.labelPrimary)
                Text(benefit.description)
                    .font(TRTypography.callout())
                    .foregroundStyle(TRColors.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}
