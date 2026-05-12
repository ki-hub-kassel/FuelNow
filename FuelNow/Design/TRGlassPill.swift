import SwiftUI

extension View {
    /// Kompakte Glas-Pille (z. B. Badges, Chips); bei „Transparenz reduzieren“ Material statt Glas.
    func trGlassPill(interactive: Bool = false) -> some View {
        modifier(TRAdaptiveGlassSurfaceModifier(surface: .pill(interactive: interactive)))
    }

    /// Karten-Pins / Cluster: **kein** Liquid Glass auf Kartendaten (HIG: Glas eher schwebende Steuerung).
    func trMapDataPill() -> some View {
        modifier(TRMapDataPillModifier())
    }
}

private struct TRMapDataPillModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.regularMaterial, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(TRColors.labelPrimary.opacity(0.14), lineWidth: 1)
            }
    }
}
