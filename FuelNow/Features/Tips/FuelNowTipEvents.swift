import TipKit

/// Gemeinsame TipKit-Events für FuelNow (stabile IDs für Persistenz).
enum FuelNowTipEvents {
    static let didUseSearchThisArea = Tips.Event(id: "fuelnow.event.searchThisArea")
    static let didUseFavoriteHeart = Tips.Event(id: "fuelnow.event.favoriteHeart")
}
