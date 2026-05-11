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
    /// `true`, damit CarPlay- und Favoriten-Gates mit echtem StoreKit-Verkauf zusammenpassen
    /// (Freemium: Karte gratis, Plus für CarPlay, Favoriten und Preisalarme).
    static let isPlusUIEnabled: Bool = true
}
