import SwiftUI

/// Tankerkönig / MTS-K Hinweis am Ende der Einstellungen.
struct SettingsDataSourceAttributionFooter: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: TRSpacing.xxs) {
            let attribution = AttributedString(
                String(
                    format: String(localized: "settings.dataSource.inline"),
                    String(localized: "settings.dataSource.linkLabel")
                )
            )
            Text(attribution)
                .font(TRTypography.caption())
                .foregroundStyle(TRColors.labelSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Tankerkönig und MTS-K, Lizenz CC BY 4.0")
                .accessibilityHint("Doppeltippen, um die Lizenzinformationen zu öffnen.")
                .onTapGesture {
                    openURL(AppSettings.TankerkoenigAttribution.infoURL)
                }
        }
        .padding(.top, TRSpacing.xs)
    }
}
