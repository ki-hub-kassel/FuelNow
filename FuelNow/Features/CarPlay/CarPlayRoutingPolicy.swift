import Foundation

/// Welcher CarPlay-Pfad ist aktuell aktiv? Wird vom `FuelNowCarPlaySceneDelegate`
/// (TAN-56) konsumiert und in das jeweilige `CPTemplate` übersetzt.
///
/// Folge-Tickets:
/// * **TAN-55** — `.plus`: `CPTabBarTemplate` mit `CPPointOfInterestTemplate` + Liste,
///   Daten aus ``StationStore`` / ``StationCarPlayPOIMapper``.
/// * **TAN-57** — `.limited`: `CPInformationTemplate` mit `carplay.locked.*` + ergänzendem Hinweis.
/// * **TAN-58** baut auf der Flip-Beobachtung auf, die der Delegate bereits
///   einrichtet (Aboablauf während aktiver Session).
enum CarPlayRoute: Equatable, Sendable {
    /// FuelNow-Plus aktiv → volle CarPlay-Erfahrung (POI-Liste & Detail).
    case plus

    /// Kein Plus → ehrliches `CPInformationTemplate` (HIG-konform, keine Pseudo-Daten).
    case limited
}

/// Pure Routing-Entscheidung — die einzige stelle, an der die Plus-Wahrheit zur
/// CarPlay-Pfad-Wahl wird. Bewusst frei von `CarPlay`/`UIKit`-Imports, damit sie
/// sich ohne Scene-Setup unit-testen lässt (TAN-62-Style).
enum CarPlayRoutingPolicy {
    /// Während Plus nur als Backend aktiv ist (`isPlusUIEnabled == false`), soll CarPlay in TestFlight
    /// trotzdem die POI-Erfahrung zeigen — ohne echtes StoreKit-Abo (siehe `FuelNowFeatureFlags`).
    ///
    /// `isPlusUIEnabled` / `isCarPlayCapabilityEnabled` sind nur für Unit-Tests parametrisiert.
    static func route(
        forCarPlayUnlocked isCarPlayUnlocked: Bool,
        isPlusUIEnabled: Bool = FuelNowFeatureFlags.isPlusUIEnabled,
        isCarPlayCapabilityEnabled: Bool = FuelNowFeatureFlags.isCarPlayCapabilityEnabled
    ) -> CarPlayRoute {
        if isCarPlayCapabilityEnabled, !isPlusUIEnabled {
            return .plus
        }
        return isCarPlayUnlocked ? .plus : .limited
    }
}
