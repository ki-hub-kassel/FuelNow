import Foundation

/// Produkt-IDs für FuelNow Plus — müssen mit App Store Connect (Linear TAN-42) und `FuelNowPlus.storekit` übereinstimmen.
enum SubscriptionConstants {
    /// Jahresabo (EUR-Basispreis kommt aus StoreKit / ASC, nicht hardcodieren für UI).
    static let plusYearlyProductID = "com.vibecoding.fuelnow.subscription.year"
    /// Monatsabo — gleiche Subscription Group wie das Jahresprodukt.
    static let plusMonthlyProductID = "com.vibecoding.fuelnow.subscription.month"

    /// Reihenfolge für StoreKit-Ladung und Paywall (Jahr zuerst = „Bester Wert“).
    static let productIDs: [String] = [plusYearlyProductID, plusMonthlyProductID]
}

/// Zentrale Apple-Abonnementübersicht (Review-konform für „Verwalten").
enum AppleSubscriptionPortal {
    static let manageAllSubscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")!
}
