import BackgroundTasks
import Foundation
import UIKit
import UserNotifications

/// Koordiniert lokale Preis-Pushes fuer Favoriten-Tankstellen (Roadmap Phase 3).
///
/// **Architektur:**
/// - **Trigger:** `BGAppRefreshTaskRequest` (Apple-System-Polling) **plus** Foreground-Refresh
///   beim Detail-Sheet-Open (best-effort).
/// - **Datenquelle:** `TankerkoenigClient.prices(ids:)` — chunked auf max. 10 IDs.
/// - **Schwelle:** Pro Sorte und Favorit wird der zuletzt gesehene Preis gespeichert; faellt der
///   neue Preis um mindestens `thresholdEuros` (Default 5 Cent), feuert eine `UNUserNotification`
///   mit Deep-Link `fuelnow://station/{id}`.
/// - **User-Schalter:** `AppSettings.UserDefaultsKey.priceAlertsEnabled` muss `true` sein, sonst
///   stiller No-Op.
@MainActor
final class PriceAlertCoordinator {
    /// Identifier fuer den `BGTaskScheduler`. Wird **zwingend** auch in `Info.plist` unter
    /// `BGTaskSchedulerPermittedIdentifiers` eingetragen — sonst registriert iOS den Task nicht.
    nonisolated static let backgroundTaskIdentifier = "com.vibecoding.fuelnow.priceAlerts.refresh"

    /// Standard-Schwelle, die in den Settings angepasst werden kann (3, 5, 10 Cent).
    nonisolated static let defaultThresholdEuros: Double = 0.05

    private let client: TankerkoenigClient
    private let favoritesStore: FavoritesStore
    private let notificationCenter: UNUserNotificationCenter
    private let defaults: UserDefaults
    private let preferredFuelDefaults: UserDefaults

    init(
        client: TankerkoenigClient,
        favoritesStore: FavoritesStore,
        notificationCenter: UNUserNotificationCenter = .current(),
        defaults: UserDefaults = .standard,
        preferredFuelDefaults: UserDefaults? = nil
    ) {
        self.client = client
        self.favoritesStore = favoritesStore
        self.notificationCenter = notificationCenter
        self.defaults = defaults
        self.preferredFuelDefaults = preferredFuelDefaults
            ?? UserDefaults(suiteName: AppSettings.widgetAppGroupIdentifier)
            ?? .standard
    }

    /// Liefert den aktuellen System-Status fuer App-Notifications. Wird vom Settings-Sheet
    /// genutzt, um den Preis-Push-Toggle korrekt zu reflektieren (z. B. Hinweis, falls der
    /// User in den Systemeinstellungen Notifications komplett deaktiviert hat).
    static func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        let center = UNUserNotificationCenter.current()
        return await center.notificationSettings().authorizationStatus
    }

    /// Fragt — falls noch nicht entschieden — Notification-Permission ab. Idempotent.
    /// Wird vom Settings-Toggle aufgerufen, bevor der erste Push gesendet werden koennte.
    ///
    /// Rueckgabe: `true`, wenn am Ende `authorized` oder `provisional` vorliegt — also
    /// Pushes tatsaechlich ankommen koennen. `false` bei `denied` (User-Entscheidung) oder
    /// einem Fehler in `requestAuthorization`. Der Settings-Toggle springt in dem Fall
    /// zurueck und zeigt einen Deep-Link in die Systemeinstellungen.
    @discardableResult
    static func requestNotificationAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                #if DEBUG
                print("[PriceAlertCoordinator] requestAuthorization failed: \(error)")
                #endif
                return false
            }
        @unknown default:
            return false
        }
    }

    /// Beim App-Start einmal aufrufen, damit `BGTaskScheduler` den Handler kennt — sonst
    /// schlaegt das Submitten fehl. Der `task` wird absichtlich `@unchecked`-Sendable
    /// in `Task { @MainActor }` reingereicht: `BGTask` ist API-mässig thread-safe genug
    /// für den Hop, das Swift-6-Concurrency-Modell hat aber dafür noch keine Annotation.
    nonisolated static func registerBackgroundHandler(
        coordinator: @escaping @Sendable () -> PriceAlertCoordinator?
    ) {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: backgroundTaskIdentifier,
            using: nil
        ) { task in
            let wrapper = UnsafeBGTaskBox(task: task)
            Task { @MainActor in
                guard let live = coordinator() else {
                    wrapper.task.setTaskCompleted(success: false)
                    return
                }
                await live.handleBackgroundRefresh(task: wrapper.task)
            }
        }
    }

    private final class UnsafeBGTaskBox: @unchecked Sendable {
        let task: BGTask
        init(task: BGTask) { self.task = task }
    }

    /// Plant den naechsten Background-Refresh in 30 Min — iOS entscheidet dann, ob/wann er laeuft.
    func scheduleNextRefresh() {
        guard isEnabled else { return }
        let request = BGAppRefreshTaskRequest(identifier: Self.backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            #if DEBUG
            print("[PriceAlertCoordinator] BGTaskScheduler submit failed: \(error)")
            #endif
        }
    }

    var isEnabled: Bool {
        defaults.bool(forKey: AppSettings.UserDefaultsKey.priceAlertsEnabled)
    }

    var thresholdEuros: Double {
        let raw = defaults.double(forKey: AppSettings.UserDefaultsKey.priceAlertsThresholdEuros)
        return raw > 0 ? raw : Self.defaultThresholdEuros
    }

    /// Im Vordergrund manuell triggerbar (Settings-Debug-Button / nach Add-Favorit).
    func runRefreshNow() async {
        guard isEnabled else { return }
        await performRefresh()
    }

    /// Wird vom `BGTask`-Handler aufgerufen.
    private func handleBackgroundRefresh(task: BGTask) async {
        scheduleNextRefresh()
        guard isEnabled else {
            task.setTaskCompleted(success: true)
            return
        }
        let didFireAny = await performRefresh()
        task.setTaskCompleted(success: didFireAny || true) // success != "fired" hier; nur Crash signalisiert false
    }

    @discardableResult
    private func performRefresh() async -> Bool {
        let ids = favoritesStore.favorites.map(\.id)
        guard !ids.isEmpty else { return false }

        let preferredFuel = AppSettings.preferredFuelFromStorage(defaults: preferredFuelDefaults)
        let threshold = thresholdEuros

        var didFireAny = false
        for chunk in ids.chunked(into: 10) {
            let prices: [UUID: TankerkoenigClient.StationPrice]
            do {
                prices = try await client.prices(ids: chunk)
            } catch {
                #if DEBUG
                print("[PriceAlertCoordinator] prices fetch failed: \(error)")
                #endif
                continue
            }

            for (stationID, price) in prices {
                guard let observed = price.price(for: preferredFuel) else { continue }
                let outcome = favoritesStore.recordPriceObservation(
                    stationID: stationID,
                    fuel: preferredFuel,
                    newPrice: observed,
                    thresholdEuros: threshold
                )
                if case let .priceDrop(_, newPrice, dropEuros) = outcome,
                   let favorite = favoritesStore.favorites.first(where: { $0.id == stationID }) {
                    await postPriceDropNotification(
                        favorite: favorite,
                        fuel: preferredFuel,
                        newPrice: newPrice,
                        dropEuros: dropEuros
                    )
                    didFireAny = true
                }
            }
        }
        return didFireAny
    }

    private func postPriceDropNotification(
        favorite: FavoriteStationRecord,
        fuel: FuelType,
        newPrice: Double,
        dropEuros: Double
    ) async {
        // Permissions-Anfrage ist Aufgabe des Settings-Toggles; hier nur posten, falls erlaubt.
        let settings = await notificationCenter.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Preis gefallen: \(favorite.displayTitle)"
        let centsDrop = Int(round(dropEuros * 100))
        let formatted = FuelPriceFormatting.pumpStyleString(euros: newPrice)
        content.body = "\(fuel.displayName) jetzt \(formatted) — \(centsDrop) Cent günstiger als zuletzt."
        content.sound = .default
        content.userInfo = [
            "deepLink": "fuelnow://station/\(favorite.id.uuidString)",
            "stationID": favorite.id.uuidString,
        ]

        let request = UNNotificationRequest(
            identifier: "fuelnow.priceDrop.\(favorite.id.uuidString)",
            content: content,
            trigger: nil
        )
        do {
            try await notificationCenter.add(request)
        } catch {
            #if DEBUG
            print("[PriceAlertCoordinator] notification add failed: \(error)")
            #endif
        }
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
