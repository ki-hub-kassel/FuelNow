import SwiftUI

/// Schritt 1: Branding, Kurztext und Kraftstoffwahl (gleiche Karten wie in den Einstellungen).
struct OnboardingWelcomeFuelStep: View {
    @Binding var fuelSelection: FuelType

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TRSpacing.l) {
                Image(.appLogo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 96, height: 96)
                    .clipShape(.rect(cornerRadius: 22, style: .continuous))
                    .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 6)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, TRSpacing.s)
                    .accessibilityHidden(true)

                Text("onboarding.step1.title")
                    .font(TRTypography.title())
                    .foregroundStyle(TRColors.labelPrimary)

                Text("onboarding.step1.subtitle")
                    .font(TRTypography.body())
                    .foregroundStyle(TRColors.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                FuelTypeCardPicker(
                    selection: $fuelSelection,
                    groupAccessibilityLabel: "onboarding.fuelpicker.accessibility"
                )
                .padding(.top, TRSpacing.xs)
            }
            .padding(.horizontal, TRSpacing.m)
            .padding(.bottom, TRSpacing.l)
        }
    }
}

/// Schritt 2: Datenschutzrahmen für Standortfreigabe.
struct OnboardingLocationStep: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TRSpacing.l) {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(TRColors.accentText)
                    .frame(maxWidth: .infinity)
                    .padding(.top, TRSpacing.xl)
                    .accessibilityHidden(true)

                Text("onboarding.location.title")
                    .font(TRTypography.title())
                    .foregroundStyle(TRColors.labelPrimary)

                Text("onboarding.location.detail")
                    .font(TRTypography.body())
                    .foregroundStyle(TRColors.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: TRSpacing.xl)
            }
            .padding(.horizontal, TRSpacing.m)
            .padding(.bottom, TRSpacing.l)
        }
    }
}
