import Foundation
@preconcurrency import WatchConnectivity

/// Sendet den aktuellen `WidgetDataSnapshot` vom iPhone an die Apple-Watch-Companion-App.
///
/// **Warum WCSession statt App-Group?** iPhone und Watch sind im Simulator und auf realen
/// Geraeten getrennte Sandboxes — die App-Group `group.com.vibecoding.fuelnow` teilt sich
/// nicht ueber das Pair hinweg. Die einzig zuverlaessige Bruecke ist `WatchConnectivity`.
///
/// **Warum `updateApplicationContext`?** Wir brauchen genau **einen aktuellen** Snapshot auf
/// der Watch — `updateApplicationContext` ueberschreibt den vorherigen Stand und wird auch
/// dann ausgeliefert, wenn die Watch gerade nicht erreichbar ist (iOS puffert bis zur naechsten
/// Verbindung). `transferUserInfo` waere queue-basiert und wuerde mehrere alte Snapshots
/// nachliefern — unnoetiger Traffic.
///
/// Der Coordinator ist ein `NSObject`, weil `WCSessionDelegate` davon erbt. Die Delegate-
/// Methoden sind `nonisolated` — `WatchConnectivity` ruft auf einer privaten Queue.
@MainActor
final class WatchConnectivityCoordinator: NSObject {
    static let shared = WatchConnectivityCoordinator()

    private let session: WCSession?

    /// Schluessel im `applicationContext`-Dictionary fuer die JSON-codierte Snapshot-Payload.
    /// Versions-Suffix erlaubt zukuenftige Schema-Wechsel ohne Watch-Crash auf alten Builds.
    static let snapshotContextKey = WatchConnectivitySnapshotBridge.snapshotDataKey

    override init() {
        if WCSession.isSupported() {
            session = WCSession.default
        } else {
            session = nil
        }
        super.init()
        session?.delegate = self
        session?.activate()
    }

    /// Schickt den Snapshot an die Watch — falls die Session aktiv ist.
    /// No-op auf Geraeten ohne WCSession-Support (z. B. iPad).
    ///
    /// **Hinweis zu `isWatchAppInstalled`:** Apple empfiehlt das Flag als Optimierung, im
    /// Simulator ist es aber haeufig fehlerhaft `false`, obwohl die Watch-App im Companion-
    /// Bundle installiert ist. Wir verlassen uns daher nur auf `activationState == .activated`
    /// und `isPaired`. `updateApplicationContext` ist idempotent und low-cost — selbst wenn
    /// niemand mithoert, wird der letzte Stand verworfen, sobald die naechste Payload kommt.
    func publish(_ snapshot: WidgetDataSnapshot) {
        guard let session, session.activationState == .activated else { return }
        guard session.isPaired else { return }
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(snapshot)
            try session.updateApplicationContext([WatchConnectivitySnapshotBridge.snapshotDataKey: data])
            #if DEBUG
            let installed = session.isWatchAppInstalled
            print("[WatchConnectivityCoordinator] published snapshot (\(data.count)B, installed=\(installed))")
            #endif
        } catch {
            #if DEBUG
            print("[WatchConnectivityCoordinator] publish failed: \(error)")
            #endif
        }
    }
}

extension WatchConnectivityCoordinator: WCSessionDelegate {
    nonisolated func session(
        _: WCSession,
        activationDidCompleteWith _: WCSessionActivationState,
        error _: Error?
    ) {}

    /// Auf iOS verlangt das Protokoll diese beiden Methoden — beide reaktivieren die Session,
    /// damit z. B. ein Watch-Wechsel (Pair mit anderer Watch) wieder funktioniert.
    nonisolated func sessionDidBecomeInactive(_: WCSession) {}
    nonisolated func sessionDidDeactivate(_: WCSession) {
        WCSession.default.activate()
    }

    nonisolated func session(
        _: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        guard message[WatchConnectivitySnapshotBridge.refreshRequestKey] as? Bool == true else { return }
        // `replyHandler` ist nicht `Sendable`; Apple ruft auf WC-Queue — wir marshallen auf MainActor.
        nonisolated(unsafe) let reply = replyHandler
        DispatchQueue.main.async {
            let payload = FuelNowRuntimeRegistry.lifecycleCoordinator?.refreshStationsForWatchCompanion()
            var replyPayload: [String: Any] = [:]
            if let payload {
                replyPayload[WatchConnectivitySnapshotBridge.snapshotDataKey] = payload
            }
            reply(replyPayload)
        }
    }

    nonisolated func session(_: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        guard userInfo[WatchConnectivitySnapshotBridge.refreshRequestKey] as? Bool == true else { return }
        DispatchQueue.main.async {
            _ = FuelNowRuntimeRegistry.lifecycleCoordinator?.refreshStationsForWatchCompanion()
        }
    }
}
