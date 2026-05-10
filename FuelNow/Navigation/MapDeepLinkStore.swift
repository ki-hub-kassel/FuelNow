import Foundation

/// Merkt sich eine per Deep Link oder Open-Intent angeforderte Tankstelle und synchronisiert nach `UserDefaults` (Cold Start / Intents).
///
/// Mutations aus Intents laufen über `MainActor.run` in der App; `UserDefaults` ist threadsicher.
@Observable
final class MapDeepLinkStore {
    /// Globale Instanz für App Intents und `FuelNowApp` (Zugriffe über `MainActor.run` / UI).
    nonisolated(unsafe) static let shared = MapDeepLinkStore()

    private let defaults: UserDefaults

    private(set) var pendingStationFocusID: UUID?

    /// Aus Steuerzentrum (App-Group) oder `fuelnow://map?action=…`; wird von `MapScreen` verarbeitet.
    private(set) var pendingControlAction: FuelNowPendingMapControlAction?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let str = defaults.string(forKey: AppSettings.UserDefaultsKey.pendingMapStationFocusID),
           let id = UUID(uuidString: str) {
            pendingStationFocusID = id
        }
    }

    func enqueueStationFocus(id: UUID) {
        pendingStationFocusID = id
        defaults.set(id.uuidString, forKey: AppSettings.UserDefaultsKey.pendingMapStationFocusID)
    }

    func clearPendingStationFocus() {
        pendingStationFocusID = nil
        defaults.removeObject(forKey: AppSettings.UserDefaultsKey.pendingMapStationFocusID)
    }

    func enqueuePendingMapControl(_ action: FuelNowPendingMapControlAction) {
        pendingControlAction = action
    }

    func clearPendingMapControl() {
        pendingControlAction = nil
    }

    /// Steuerzentrum-Extension schreibt in die App-Group; beim Aktivwerden der Szene einlesen.
    func syncPendingControlFromAppGroupIfNeeded() {
        guard let defs = UserDefaults(suiteName: WidgetSnapshotStore.appGroupIdentifier),
              let raw = defs.string(forKey: WidgetSnapshotStore.pendingControlMapActionKey),
              let action = FuelNowPendingMapControlAction(rawValue: raw) else { return }
        defs.removeObject(forKey: WidgetSnapshotStore.pendingControlMapActionKey)
        pendingControlAction = action
    }
}
