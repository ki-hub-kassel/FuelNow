import Foundation

/// Gemeinsame WatchConnectivity-Schlüssel für iPhone ↔ Watch (Payload ist property-list-kompatibel).
enum WatchConnectivitySnapshotBridge {
    /// Gleicher Schlüssel wie `WatchConnectivityCoordinator.snapshotContextKey` / Watch-Provider.
    static let snapshotDataKey = "snapshotV1"
    /// Watch fragt Snapshot-Aktualisierung an; Wert `true` in Message/UserInfo.
    static let refreshRequestKey = "watchRefreshSnapshot"
}
