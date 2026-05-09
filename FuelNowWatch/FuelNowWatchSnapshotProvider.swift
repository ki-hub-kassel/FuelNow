import Foundation
import Observation
import WatchConnectivity

/// Versorgt die Watch-UI mit dem letzten vom iPhone geschickten `WidgetDataSnapshot`.
///
/// **Quelle:** `WCSession.updateApplicationContext` vom iPhone-`WatchConnectivityCoordinator`.
/// **Cache:** Letzte Payload wird im Application-Support-Verzeichnis als
/// `watch-snapshot-v1.json` persistiert, damit die Watch auch ohne erreichbares iPhone
/// (z. B. ausser Reichweite) sofort den letzten Stand zeigen kann.
///
/// Frueher (vor TAN-Watch) versuchte dieser Provider, eine App-Group-Datei zu lesen — das
/// scheitert architekturell, weil iPhone und Watch separate Sandboxes haben (siehe README).
@MainActor
@Observable
final class FuelNowWatchSnapshotProvider: NSObject {
    private(set) var snapshot: WatchWidgetSnapshot?
    private(set) var lastError: String?
    private(set) var isAwaitingFirstPayload: Bool = true

    private let fileManager: FileManager
    private let cacheURL: URL?
    private let snapshotContextKey = "snapshotV1"

    override init() {
        let manager = FileManager.default
        fileManager = manager
        if let supportDir = try? manager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) {
            cacheURL = supportDir.appendingPathComponent("watch-snapshot-v1.json", isDirectory: false)
        } else {
            cacheURL = nil
        }
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    /// Beim App-Start: erst lokaler Cache (sofortige UI), danach falls vorhanden der bereits
    /// gepufferte `receivedApplicationContext` (z. B. Snapshot wurde gesendet, waehrend die
    /// Watch geschlafen hat). Spaetere Pushes kommen via Delegate-Callback.
    func load() async {
        if let cacheURL, let data = try? Data(contentsOf: cacheURL) {
            ingest(data: data, persist: false)
        }
        if WCSession.isSupported(), WCSession.default.activationState == .activated {
            consumeBufferedContext()
        }
    }

    private func consumeBufferedContext() {
        let buffered = WCSession.default.receivedApplicationContext
        if let bytes = buffered[snapshotContextKey] as? Data {
            ingest(data: bytes, persist: true)
        }
    }

    private func ingest(data: Data, persist: Bool) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            snapshot = try decoder.decode(WatchWidgetSnapshot.self, from: data)
            lastError = nil
            isAwaitingFirstPayload = false
            if persist, let cacheURL {
                try? data.write(to: cacheURL, options: [.atomic])
            }
        } catch {
            lastError = error.localizedDescription
        }
    }
}

extension FuelNowWatchSnapshotProvider: WCSessionDelegate {
    nonisolated func session(
        _: WCSession,
        activationDidCompleteWith _: WCSessionActivationState,
        error _: Error?
    ) {
        Task { @MainActor in self.consumeBufferedContext() }
    }

    nonisolated func session(
        _: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        guard let bytes = applicationContext["snapshotV1"] as? Data else { return }
        Task { @MainActor in self.ingest(data: bytes, persist: true) }
    }
}

/// Lokale Spiegelung der relevanten `WidgetDataSnapshot`-Felder fuer die Watch.
///
/// **Warum dupliziert?** Das Watch-Target hat (noch) keine direkte Compile-Membership des
/// iOS-`WidgetSnapshotStore.swift`; die Felder sind hier auf das reduziert, was die Watch-UI
/// braucht. JSON-kompatibel zum `WidgetDataSnapshot` — der `JSONDecoder` ignoriert
/// zusaetzliche iOS-only-Felder (`loadState`, `preferredFuelRawValue`, `stationCount`).
struct WatchWidgetSnapshot: Codable, Sendable, Equatable {
    let generatedAt: Date
    let nearest: WatchStationSnapshot?
    let cheapest: WatchStationSnapshot?
    let cheapestNearby: [WatchStationSnapshot]?
}

struct WatchStationSnapshot: Codable, Sendable, Equatable, Hashable, Identifiable {
    let stationID: UUID
    let brandTitle: String
    let stationName: String
    let pumpPriceText: String
    let distanceText: String
    let isOpen: Bool

    var id: UUID { stationID }

    enum CodingKeys: String, CodingKey {
        case stationID, brandTitle, stationName, pumpPriceText, distanceText, isOpen
    }
}
