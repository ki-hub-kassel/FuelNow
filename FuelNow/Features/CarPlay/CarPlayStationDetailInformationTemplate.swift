#if canImport(CarPlay)
import CarPlay
import Foundation

/// Ge-pushtes Tankstellen-Detail für CarPlay Plus (`pushTemplate` — `presentTemplate` unterstützt kein CPInformationTemplate).
enum CarPlayStationDetailInformationTemplate {
    @MainActor
    static func make(
        station: Station,
        interfaceController: CPInterfaceController?
    ) -> CPInformationTemplate {
        let openClosed = station.isOpen
            ? String(localized: "station.status.open")
            : String(localized: "station.status.closed")
        let distance = StationDisplayFormatting.distanceString(kilometers: station.distanceKilometers)
        let liveStatusDetail = "\(openClosed)\n\(distance)"

        let items: [CPInformationItem] = [
            CPInformationItem(
                title: String(localized: "carplay.stationDetail.section.prices"),
                detail: StationCarPlayPOIMapper.compactFuelLine(station: station)
            ),
            CPInformationItem(
                title: String(localized: "carplay.stationDetail.section.liveStatus"),
                detail: liveStatusDetail
            ),
        ]

        let navigation = CPTextButton(
            title: String(localized: "intent.snippet.mapsNavigationButton"),
            textStyle: .confirm
        ) { [weak interfaceController] _ in
            CarPlayDrivingNavigation.openDrivingDirections(to: station)
            interfaceController?.popTemplate(animated: true, completion: nil)
        }

        return CPInformationTemplate(
            title: station.name,
            layout: .leading,
            items: items,
            actions: [navigation]
        )
    }
}
#endif
