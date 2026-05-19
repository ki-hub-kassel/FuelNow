#if canImport(CarPlay)
import CarPlay
import Foundation
import UIKit

/// Ge-pushtes Tankstellen-Detail für CarPlay Plus (`pushTemplate` — `presentTemplate` unterstützt kein CPInformationTemplate).
enum CarPlayStationDetailInformationTemplate {
    @MainActor
    static func make(
        station: Station,
        interfaceController: CPInterfaceController?,
        carPlayScene: CPTemplateApplicationScene?
    ) -> CPInformationTemplate {
        var items: [CPInformationItem] = [
            CPInformationItem(
                title: String(localized: "carplay.stationDetail.section.prices"),
                detail: StationCarPlayPOIMapper.compactFuelLine(station: station)
            ),
        ]

        if let location = CarPlayStationDetailFormatting.locationDetail(station: station) {
            items.append(
                CPInformationItem(
                    title: String(localized: "carplay.stationDetail.section.location"),
                    detail: location
                )
            )
        }

        items.append(
            CPInformationItem(
                title: String(localized: "carplay.stationDetail.section.openingHours"),
                detail: CarPlayStationDetailFormatting.openingHoursDetailLines(station: station)
            )
        )

        items.append(
            CPInformationItem(
                title: String(localized: "carplay.stationDetail.section.distance"),
                detail: CarPlayStationDetailFormatting.distanceDetail(station: station)
            )
        )

        let navigation = CPTextButton(
            title: String(localized: "intent.snippet.mapsNavigationButton"),
            textStyle: .confirm
        ) { [weak interfaceController] _ in
            guard let carPlayScene else { return }
            CarPlayDrivingNavigation.openDrivingDirections(to: station, from: carPlayScene) { success in
                guard success else { return }
                interfaceController?.popTemplate(animated: true, completion: nil)
            }
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
