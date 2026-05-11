import Foundation

/// Einmalige Migration beim ersten Start nach Freemium-Update: Nicht-Plus-Nutzer verlieren
/// Preisalarme und die Merkliste, damit Free dem Produktmodell entspricht.
enum PlusFreemiumMigration {
    @MainActor
    static func applyIfNeeded(
        isPlusSubscriber: Bool,
        favoritesStore: FavoritesStore,
        defaults: UserDefaults = .standard
    ) {
        guard FuelNowFeatureFlags.isPlusMonetizationActive else { return }
        let key = AppSettings.UserDefaultsKey.plusFreemiumMigrationV1Completed
        guard !defaults.bool(forKey: key) else { return }
        defaults.set(true, forKey: key)
        guard !isPlusSubscriber else { return }
        defaults.set(false, forKey: AppSettings.UserDefaultsKey.priceAlertsEnabled)
        favoritesStore.removeAllFavorites()
    }
}
