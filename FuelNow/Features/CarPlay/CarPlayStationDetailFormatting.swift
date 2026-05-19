import Foundation

/// Textformatierung für das CarPlay-Tankstellen-Detail (`CPInformationTemplate`).
enum CarPlayStationDetailFormatting {
    static func openingHoursDetailLines(station: Station) -> String {
        let status = station.isOpen
            ? String(localized: "station.status.open")
            : String(localized: "station.status.closed")
        if let subtitle = StationOpeningHoursPresenter.openStatusSubtitle(station: station) {
            return "\(status)\n\(subtitle)"
        }
        return status
    }

    static func locationDetail(station: Station) -> String? {
        let trimmed = station.fullAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func distanceDetail(station: Station) -> String {
        StationDisplayFormatting.distanceString(kilometers: station.distanceKilometers)
    }
}
