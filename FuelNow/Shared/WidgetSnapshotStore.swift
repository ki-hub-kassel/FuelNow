import Foundation

enum WidgetSnapshotLoadState: String, Codable, Sendable {
    case ready
    case empty
    case loading
    case failed
}

struct WidgetStationSnapshot: Codable, Sendable, Equatable {
    let stationID: UUID
    let brandTitle: String
    let stationName: String
    let address: String
    let statusText: String
    let isOpen: Bool
    let distanceText: String
    let distanceKilometers: Double?
    let fuelTypeDisplayName: String
    let pumpPriceText: String
    let voicePriceText: String
    let openInAppURL: String
    let mapsDirectionsURL: String
}

struct WidgetDataSnapshot: Codable, Sendable, Equatable {
    let generatedAt: Date
    let loadState: WidgetSnapshotLoadState
    let preferredFuelRawValue: String
    let stationCount: Int
    let nearest: WidgetStationSnapshot?
    let cheapest: WidgetStationSnapshot?
    /// Top-N (Default: 2) guenstigste Tankstellen im engen Radius (Default: 5 km) fuer das
    /// `FuelNowCheapestNearbyWidget` (Roadmap Phase 4). Als optional kodiert, damit alte
    /// Snapshots (vor diesem Feld) weiter dekodiert werden koennen — JSONDecoder springt
    /// auf `nil`, ohne den `WidgetDataSnapshot`-Decode zu brechen.
    let cheapestNearby: [WidgetStationSnapshot]?

    init(
        generatedAt: Date,
        loadState: WidgetSnapshotLoadState,
        preferredFuelRawValue: String,
        stationCount: Int,
        nearest: WidgetStationSnapshot?,
        cheapest: WidgetStationSnapshot?,
        cheapestNearby: [WidgetStationSnapshot]? = nil
    ) {
        self.generatedAt = generatedAt
        self.loadState = loadState
        self.preferredFuelRawValue = preferredFuelRawValue
        self.stationCount = stationCount
        self.nearest = nearest
        self.cheapest = cheapest
        self.cheapestNearby = cheapestNearby
    }
}

/// Steuerzentrum-Controls schreiben eine Pending-Aktion in die App-Group; die Haupt-App liest sie bei `scenePhase == .active`.
enum FuelNowPendingMapControlAction: String, Sendable {
    case focusCheapest
    case refreshVisibleRegion
}

struct WidgetSnapshotStore {
    static let fileName = "widget-snapshot-v1.json"
    static let appGroupIdentifier = "group.com.vibecoding.fuelnow"
    static let pendingControlMapActionKey = "tr.pendingControlMapAction"

    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        encoder = JSONEncoder()
        decoder = JSONDecoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }

    private var snapshotURL: URL? {
        fileManager.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier)?
            .appendingPathComponent(Self.fileName, isDirectory: false)
    }

    func read() -> WidgetDataSnapshot? {
        guard let snapshotURL else { return nil }
        guard let data = try? Data(contentsOf: snapshotURL) else { return nil }
        return try? decoder.decode(WidgetDataSnapshot.self, from: data)
    }

    func write(_ snapshot: WidgetDataSnapshot) {
        guard let snapshotURL else { return }
        guard let data = try? encoder.encode(snapshot) else { return }
        try? data.write(to: snapshotURL, options: [.atomic])
    }
}
