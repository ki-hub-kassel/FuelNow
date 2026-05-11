import SwiftUI

/// Statischer Hinweis über dem Chip „In diesem Gebiet suchen“ — ersetzt `TipView(MapSearchAreaTip)`,
/// das in TestFlight als defekt gemeldet wurde (Layout/Rendering über der Karte).
struct MapSearchAreaCoachmark: View {
    var body: some View {
        VStack(alignment: .leading, spacing: TRSpacing.xxs) {
            Label {
                Text("tip.mapSearchArea.title")
                    .font(TRTypography.bodyBold())
            } icon: {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(TRColors.accentText)
            }
            Text("tip.mapSearchArea.message")
                .font(TRTypography.caption())
                .foregroundStyle(TRColors.labelSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(TRSpacing.s)
        .background(
            RoundedRectangle(cornerRadius: TRRadius.lg, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: TRRadius.lg, style: .continuous)
                .strokeBorder(TRColors.separator.opacity(0.6), lineWidth: 0.5)
        )
        .accessibilityElement(children: .combine)
    }
}
