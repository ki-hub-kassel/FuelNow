import AppIntents
import Foundation

/// Öffnet die App zur Karte (Deep-Link-Flow ohne zusätzliche Parameter).
struct OpenFuelNowIntent: AppIntent {
    static var title: LocalizedStringResource {
        LocalizedStringResource("intent.openFuelNow.title")
    }

    static var description: IntentDescription {
        IntentDescription(
            LocalizedStringResource("intent.openFuelNow.description")
        )
    }

    static var openAppWhenRun: Bool { true }

    static var isDiscoverable: Bool { true }

    static var supportedModes: IntentModes {
        [.foreground(.dynamic), .background]
    }

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            MapDeepLinkStore.shared.clearPendingStationFocus()
        }
        return .result()
    }
}

/// Öffnet die App und fokussiert die gewählte Tankstelle auf der Karte (Spotlight-tauglich via `OpenIntent`).
struct OpenStationIntent: OpenIntent {
    static var title: LocalizedStringResource {
        LocalizedStringResource("intent.openStation.title")
    }

    static var description: IntentDescription {
        IntentDescription(
            LocalizedStringResource("intent.openStation.description")
        )
    }

    static var openAppWhenRun: Bool { true }

    static var isDiscoverable: Bool { true }

    static var supportedModes: IntentModes {
        [.foreground(.dynamic), .background]
    }

    @Parameter(title: LocalizedStringResource("intent.openStation.parameter.station"))
    var target: StationEntity

    init() {}

    init(target: StationEntity) {
        self.target = target
    }

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            MapDeepLinkStore.shared.enqueueStationFocus(id: target.id)
        }
        return .result()
    }
}
