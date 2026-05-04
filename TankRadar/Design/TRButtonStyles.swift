import SwiftUI

// MARK: - Primary (accent-tinted glass)

/// Hauptaktion: Liquid Glass mit Akzent-Tint (iOS 26).
struct TRPrimaryGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TRTypography.bodyBold())
            .foregroundStyle(TRColors.labelPrimary)
            .padding(.horizontal, TRSpacing.l)
            .padding(.vertical, TRSpacing.xs)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .glassEffect(
                Glass.regular.tint(TRColors.accent.opacity(0.35)).interactive(),
                in: .capsule
            )
    }
}

// MARK: - Soft (neutral glass)

/// Sekundäre Aktion: dezentes Glas.
struct TRSoftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TRTypography.bodyBold())
            .foregroundStyle(TRColors.labelPrimary)
            .padding(.horizontal, TRSpacing.l)
            .padding(.vertical, TRSpacing.xs)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .glassEffect(Glass.regular.interactive(), in: .capsule)
    }
}

// MARK: - Outline

/// Ghost / Tertiär: nur Kontur, kein Glas.
struct TROutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TRTypography.bodyBold())
            .foregroundStyle(TRColors.accent)
            .padding(.horizontal, TRSpacing.l)
            .padding(.vertical, TRSpacing.xs)
            .background(Capsule().fill(TRColors.backgroundSecondary.opacity(0.001)))
            .overlay {
                Capsule()
                    .strokeBorder(TRColors.accent, lineWidth: 1.5)
            }
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

extension ButtonStyle where Self == TRPrimaryGlassButtonStyle {
    static var trPrimaryGlass: TRPrimaryGlassButtonStyle { TRPrimaryGlassButtonStyle() }
}

extension ButtonStyle where Self == TRSoftButtonStyle {
    static var trSoft: TRSoftButtonStyle { TRSoftButtonStyle() }
}

extension ButtonStyle where Self == TROutlineButtonStyle {
    static var trOutline: TROutlineButtonStyle { TROutlineButtonStyle() }
}
