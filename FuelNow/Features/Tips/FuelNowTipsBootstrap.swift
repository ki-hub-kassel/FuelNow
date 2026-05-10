import TipKit

enum FuelNowTipsBootstrap {
    /// Einmalige TipKit-Konfiguration beim App-Start (Display-Frequenz zurückhaltend).
    static func configure() {
        do {
            try Tips.configure([
                .displayFrequency(.weekly),
            ])
        } catch {
            assertionFailure("TipKit configure failed: \(error.localizedDescription)")
        }
    }
}
