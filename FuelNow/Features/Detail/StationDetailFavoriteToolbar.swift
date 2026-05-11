import SwiftUI
import TipKit

/// Herz in der Tankstellen-Detail-Toolbar (Plus-gated).
struct StationDetailFavoriteToolbar: View {
    @Environment(FavoritesStore.self) private var favoritesStore

    let resolvedStation: Station
    let isFavorited: Bool
    let isPlusSubscriber: Bool
    @Binding var showPlusUpgradeSheet: Bool

    var body: some View {
        Group {
            if isPlusSubscriber {
                Button {
                    Haptics.tap(.light)
                    favoritesStore.toggle(resolvedStation)
                    Task {
                        await FuelNowTipEvents.didUseFavoriteHeart.donate()
                    }
                } label: {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(isFavorited ? TRColors.danger : TRColors.labelSecondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .popoverTip(FavoriteStationTip(), arrowEdge: .leading)
                .accessibilityLabel(isFavorited ? "Favorit entfernen" : "Als Favorit speichern")
                .accessibilityHint(
                    isFavorited
                        ? "Entfernt diese Tankstelle aus deinen Favoriten."
                        : "Speichert diese Tankstelle in deinen Favoriten und meldet Preissturz-Pushes."
                )
            } else {
                Button {
                    Haptics.tap(.light)
                    showPlusUpgradeSheet = true
                } label: {
                    Image(systemName: "heart")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(TRColors.labelSecondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("station.detail.favorite.plusOnly.a11yLabel"))
                .accessibilityHint(Text("station.detail.favorite.plusOnly.a11yHint"))
            }
        }
    }
}
