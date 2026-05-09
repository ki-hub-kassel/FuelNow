import AppIntents
import Foundation

/// Spendet Kern-Intents nach erstem erfolgreichen Datenstand, damit Siri/Kurzbefehle sie ohne vorherige manuelle Ausführung eher vorschlagen können.
@MainActor
enum ShortcutSuggestionDonation {
    private static var donatedThisSession = false

    static func donateAfterStationsLoadedIfNeeded(loadState: StationLoadState, stationCount: Int) {
        guard case .loaded = loadState, stationCount > 0 else { return }
        guard !donatedThisSession else { return }
        donatedThisSession = true
        _ = IntentDonationManager.shared.donate(intent: FindNearestStationIntent())
        _ = IntentDonationManager.shared.donate(intent: FindCheapestStationIntent())
        _ = IntentDonationManager.shared.donate(intent: OpenFuelNowIntent())
    }
}
