import AppIntents
import Foundation

extension FuelType: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Kraftstoff"
    }

    /// Kurztitel für Siri/Shortcuts (entspricht `displayName` / Deutsch).
    static var caseDisplayRepresentations: [FuelType: DisplayRepresentation] {
        [
            .e5: DisplayRepresentation(title: LocalizedStringResource("fuelType.display.e5")),
            .e10: DisplayRepresentation(title: LocalizedStringResource("fuelType.display.e10")),
            .diesel: DisplayRepresentation(title: LocalizedStringResource("fuelType.display.diesel")),
        ]
    }
}
