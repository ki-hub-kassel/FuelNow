import Foundation

/// Produkt-IDs für TankRadar Plus — müssen mit App Store Connect (Linear TAN-42) und `TankRadarPlus.storekit` übereinstimmen.
enum SubscriptionConstants {
    /// Jahresabo (EUR-Basispreis kommt aus StoreKit / ASC, nicht hardcodieren für UI).
    static let plusYearlyProductID = "com.vibecoding.TankRadar.subscription.year"

    static let productIDs: [String] = [plusYearlyProductID]
}
