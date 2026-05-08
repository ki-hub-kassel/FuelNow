import SwiftUI

/// Fehler-/Hinweis-Snippet für Siri/Shortcuts (TAN-96).
///
/// Folgt demselben zweistufigen Layout wie ``StationSearchResultSnippetView`` —
/// Tier-1 Brand-Header (dunkler Teal, AAA gegen weißen Foreground) + Tier-2
/// helle Sub-Card mit Icon und Erklärungstext. So fühlen sich Erfolgs- und
/// Fehlerzustände wie Geschwister an.
struct StationSnippetView: View {
    let systemImage: String
    let title: String
    let subtitle: String

    /// Identische Surface wie ``StationSearchResultSnippetView`` — fix Dark-Brand-Teal in Light + Dark.
    private static let brandHeaderSurface = Color(red: 0.06, green: 0.34, blue: 0.31)

    /// Fehlerzustände kennzeichnen wir durch das Icon im Sub-Card; wenn das Icon „danger" signalisiert
    /// (z. B. `location.slash`, `exclamationmark.triangle`, `fuelpump.slash`), tinten wir es rot.
    private var iconTint: Color {
        switch systemImage {
        case "location.slash", "exclamationmark.triangle":
            TRColors.danger
        default:
            TRColors.accent
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TRSpacing.m) {
            brandHeader
            messageCard
        }
        .padding(TRSpacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerShape(ContainerRelativeShape())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle)")
    }

    private var brandHeader: some View {
        HStack(alignment: .center, spacing: TRSpacing.s) {
            Image(systemName: "fuelpump.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
                .accessibilityHidden(true)
            Text("FuelNow")
                .font(TRTypography.headline())
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(TRSpacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: TRRadius.lg, style: .continuous)
                .fill(Self.brandHeaderSurface)
        )
    }

    private var messageCard: some View {
        HStack(alignment: .top, spacing: TRSpacing.s) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(iconTint)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: TRSpacing.xxs) {
                Text(title)
                    .font(TRTypography.bodyBold())
                    .foregroundStyle(TRColors.labelPrimary)

                Text(subtitle)
                    .font(TRTypography.subheadline())
                    .foregroundStyle(TRColors.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(TRSpacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: TRRadius.lg, style: .continuous)
                .fill(TRColors.backgroundTertiary)
        )
    }
}

/// Abwärtskompatibler Name aus Phase 6 (TAN-51).
typealias StationIntentSnippetView = StationSnippetView
