import SwiftUI

/// Favoriten-Liste in den Einstellungen (FuelNow Plus).
struct SettingsFavoritesFormSection: View {
    @Environment(EntitlementManager.self) private var entitlementManager
    @Environment(FavoritesStore.self) private var favoritesStore
    @Binding var showPlusUpgradeSheet: Bool

    var body: some View {
        Section {
            if entitlementManager.isPlusSubscriber {
                if favoritesStore.favorites.isEmpty {
                    Text("Noch keine Favoriten — tippe in der Tankstellen-Detailansicht auf das Herz.")
                        .font(TRTypography.caption())
                        .foregroundStyle(TRColors.labelSecondary)
                } else {
                    ForEach(favoritesStore.favorites) { favorite in
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: TRSpacing.xxs) {
                                Text(favorite.displayTitle)
                                    .font(TRTypography.bodyBold())
                                if !favorite.street.isEmpty {
                                    Text(favorite.street)
                                        .font(TRTypography.caption())
                                        .foregroundStyle(TRColors.labelSecondary)
                                }
                            }
                            Spacer(minLength: TRSpacing.s)
                            Button(role: .destructive) {
                                Haptics.tap(.medium)
                                favoritesStore.remove(stationID: favorite.id)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(TRColors.danger)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(favorite.displayTitle) als Favorit entfernen")
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            favoritesStore.remove(stationID: favoritesStore.favorites[index].id)
                        }
                    }
                }
            } else {
                Text("plus.gated.favorites.footer")
                    .font(TRTypography.caption())
                    .foregroundStyle(TRColors.labelSecondary)
                Button {
                    Haptics.tap(.light)
                    showPlusUpgradeSheet = true
                } label: {
                    Label("plus.gated.favorites.openPlus", systemImage: "sparkles")
                        .foregroundStyle(TRColors.accentText)
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("plus.gated.favorites.title")
        } footer: {
            if entitlementManager.isPlusSubscriber {
                Text("Lokale Liste — wird mit Widget und Watch geteilt, sobald Sync aktiviert ist.")
                    .font(TRTypography.caption())
                    .foregroundStyle(TRColors.labelSecondary)
            }
        }
    }
}
