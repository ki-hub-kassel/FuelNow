import SwiftUI

/// Scrollbarer Preisblock im Tankstellen-Detail.
struct StationDetailPricesCard: View {
    let resolvedStation: Station
    let preferredFuel: FuelType

    var body: some View {
        TRSectionCard(title: "Preise") {
            VStack(alignment: .leading, spacing: TRSpacing.s) {
                ForEach(FuelType.allCases) { fuel in
                    priceRow(fuel: fuel, isPreferred: fuel == preferredFuel)
                }
            }
        }
    }

    private func priceRow(fuel: FuelType, isPreferred: Bool) -> some View {
        let euros = resolvedStation.price(for: fuel)
        let priceProminence: FuelPriceLabel.Prominence = isPreferred ? .display : .standard
        let priceForeground: Color =
            (euros == nil)
            ? TRColors.labelSecondary
            : (isPreferred ? TRColors.accentText : TRColors.labelSecondary)
        let nameFont: Font = isPreferred ? TRTypography.headline() : TRTypography.body()
        let nameColor: Color = isPreferred ? TRColors.labelPrimary : TRColors.labelSecondary

        return HStack(alignment: .firstTextBaseline) {
            Text(fuel.displayName)
                .font(nameFont)
                .foregroundStyle(nameColor)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            Spacer(minLength: TRSpacing.s)
            FuelPriceLabel(
                euros: euros,
                prominence: priceProminence,
                foreground: priceForeground
            )
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(priceRowAccessibilityLabel(fuel: fuel, isPreferred: isPreferred))
    }

    private func priceRowAccessibilityLabel(fuel: FuelType, isPreferred: Bool) -> String {
        let pricePart = FuelPriceFormatting.voiceOverString(euros: resolvedStation.price(for: fuel))
        return StationVoiceOverCopy.detailPriceRow(
            fuelDisplayName: fuel.displayName,
            formattedPriceOrUnavailable: pricePart,
            isPreferred: isPreferred
        )
    }
}
