import Foundation

/// Gemeinsame `@AppStorage`-Schlüssel und Regeln für Karte + Einstellungen (**TAN-19**).
enum AppSettings {
    /// App Group für gemeinsam genutzte Daten zwischen App und Widget.
    static let widgetAppGroupIdentifier = "group.com.vibecoding.fuelnow"

    enum UserDefaultsKey {
        static let preferredFuelType = "tr.preferredFuelType"
        /// Veraltet seit TAN-79: Suchradius wurde aus den Settings entfernt und ist
        /// fest auf das Tankerkönig-API-Maximum (25 km) gesetzt. Der Key bleibt definiert,
        /// damit alte Werte in `UserDefaults` nicht aktiv aufgeräumt werden müssen — die
        /// App liest ihn nicht mehr.
        static let searchRadiusKm = "tr.searchRadiusKm"
        /// Hell / Dunkel / System (`AppearancePreference.rawValue`).
        static let appearancePreference = "tr.appearancePreference"
        /// Letzter bekannter Standort für App Intents / Siri (`LocationProvider`, ~2 min TTL).
        static let locationCacheLatitude = "tr.locationCache.latitude"
        static let locationCacheLongitude = "tr.locationCache.longitude"
        static let locationCacheHorizontalAccuracy = "tr.locationCache.horizontalAccuracy"
        static let locationCacheRecordedAt = "tr.locationCache.recordedAt"
        /// Kurzbefehle / Custom-URL: Tankstelle auf der Karte fokussieren (`MapDeepLinkStore`).
        static let pendingMapStationFocusID = "tr.pendingMapStationFocusID"
        /// First-run Onboarding wurde abgeschlossen/übersprungen.
        static let hasCompletedOnboarding = "tr.hasCompletedOnboarding"
        /// JSON-codierte Liste der Favoriten-Tankstellen (Roadmap Phase 2).
        /// Wird in der App-Group gespeichert, damit Widget/Watch denselben Stand sehen.
        static let favoritesJSON = "tr.favoritesJSON"
        /// Boolesches User-Setting "Preis-Pushes (Beta)" (Roadmap Phase 3).
        static let priceAlertsEnabled = "tr.priceAlerts.enabled"
        /// Schwellenwert in Euro fuer Preis-Pushes; Default 0.05 (5 Cent).
        static let priceAlertsThresholdEuros = "tr.priceAlerts.thresholdEuros"
        /// Einmalige Freemium-Migration (Favoriten/Preisalarme → Plus): nach erstem Lauf `true`.
        static let plusFreemiumMigrationV1Completed = "tr.plusFreemiumMigration.v1.completed"
        /// Nur **Debug-Builds**: Schalter „Plus simulieren“ in den Einstellungen (vor App-Store-Live).
        /// In Release wird der Key von `EntitlementManager` nicht ausgewertet.
        static let temporaryDebugPlusOverrideEnabled = "tr.debug.temporaryPlusOverrideEnabled"
    }

    /// Suchradius für Tankerkönig-`list.php` (TAN-79).
    ///
    /// Seit TAN-79 ist der Suchradius aus den User-Settings entfernt und fest auf das
    /// **API-Maximum von 25 km** gesetzt. Tankerkönig erlaubt im freien Tier
    /// (`creativecommons.tankerkoenig.de`) keinen größeren Radius und untersagt das
    /// Bulk-Mirroring; „alle Tankstellen anzeigen" bedeutet daher konsequent
    /// „alle im 25-km-Umkreis um den Standort".
    enum SearchRadius {
        /// Tankerkönig-API-Maximum für `rad` in `list.php`.
        static let apiMaxKm: Double = 25
    }

    enum TankerkoenigAttribution {
        static let infoURL = URL(string: "https://creativecommons.tankerkoenig.de")!
    }

    /// Gespeicherte UI-Erscheinung; `system` folgt iOS Hell/Dunkel.
    enum AppearancePreference: String, CaseIterable, Identifiable {
        case system
        case light
        case dark

        var id: String { rawValue }

        static func resolved(storedRaw: String) -> AppearancePreference {
            Self(rawValue: storedRaw) ?? .system
        }
    }
}
