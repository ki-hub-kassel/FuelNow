import Foundation

extension AppSettings {
    /// Kraftstoffsorte aus `UserDefaults` — gleicher Key wie ``SettingsView`` (`@AppStorage`).
    nonisolated static func preferredFuelFromStorage(defaults: UserDefaults = .standard) -> FuelType {
        let raw = defaults.string(forKey: UserDefaultsKey.preferredFuelType) ?? FuelType.e10.rawValue
        return FuelType(rawValue: raw) ?? .e10
    }
}
