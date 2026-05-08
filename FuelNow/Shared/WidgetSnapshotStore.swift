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
}

struct WidgetSnapshotStore {
    static let fileName = "widget-snapshot-v1.json"
    static let appGroupIdentifier = "group.com.vibecoding.fuelnow"

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
