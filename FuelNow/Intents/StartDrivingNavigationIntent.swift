import AppIntents
import Foundation

/// Interner Intent für Siri-/Shortcuts-Snippets: startet Turn-by-Turn in Apple Maps (`isDiscoverable: false`).
struct StartDrivingNavigationIntent: AppIntent {
    static var title: LocalizedStringResource {
        LocalizedStringResource("intent.startDrivingNavigation.title")
    }

    static var description: IntentDescription {
        IntentDescription(LocalizedStringResource("intent.startDrivingNavigation.description"))
    }

    static var openAppWhenRun: Bool { false }

    static var isDiscoverable: Bool { false }

    @Parameter(title: LocalizedStringResource("intent.startDrivingNavigation.parameter.latitude"))
    var latitude: Double

    @Parameter(title: LocalizedStringResource("intent.startDrivingNavigation.parameter.longitude"))
    var longitude: Double

    @Parameter(title: LocalizedStringResource("intent.startDrivingNavigation.parameter.placeName"))
    var placeName: String

    init() {}

    init(latitude: Double, longitude: Double, placeName: String) {
        self.latitude = latitude
        self.longitude = longitude
        self.placeName = placeName
    }

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            AppleMapsDrivingNavigation.openDrivingDirections(
                toLatitude: latitude,
                longitude: longitude,
                placeName: placeName.isEmpty ? nil : placeName
            )
        }
        return .result()
    }
}
