/// Zentraler Schalter für Produktfunktionen, die zusätzliche Apple-Freigaben brauchen.
enum FuelNowFeatureFlags {
    enum CarPlayCapabilityMode {
        /// CarPlay deaktiviert (kein Entitlement + keine CarPlay-Scene im Manifest).
        case none
        /// Offizielle Fueling-Capability nach Apple-Freigabe.
        case fueling
        /// Temporärer Testpfad, solange Fueling noch nicht freigeschaltet ist.
        case evCharging
    }

    /// Aktive CarPlay-Capability für diesen Build.
    ///
    /// Default für den temporären Testzweig: EV-Charging, damit CarPlay in TestFlight/Fahrzeug
    /// verifiziert werden kann, bis Fueling freigegeben ist.
    static let carPlayCapabilityMode: CarPlayCapabilityMode = .evCharging

    /// `true`, wenn irgendeine CarPlay-Capability im Bundle aktiv ist.
    static var isCarPlayCapabilityEnabled: Bool {
        carPlayCapabilityMode != .none
    }

    /// Schaltet die FuelNow-Plus-UI (Settings-Section, Paywall-Sheet, Mini-Hero) sichtbar.
    ///
    /// Für das 1.0-Release bewusst auf `false` — die Plus-Bezahllogik (`StoreKit 2`,
    /// `EntitlementManager`, `PlusPurchaseController`, `PlusUpgradeView`, `PlusMiniHero`) bleibt
    /// vollständig im Build erhalten und ist über DEBUG-Demo-Toggle weiter testbar; im Release-UI
    /// wird die Plus-Section in `SettingsView` aber nicht gerendert. Reaktivierung später nur
    /// durch Flippen dieses Flags auf `true` — keine UI-Strukturänderung nötig.
    static let isPlusUIEnabled: Bool = false
}
