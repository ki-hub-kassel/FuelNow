import AppIntents
import Foundation
import SwiftUI

// MARK: - Find nearest

/// Siri/Kurzbefehle: geografisch nächste Tankstelle im 25-km-Umkreis (Tankerkönig-API-Maximum, TAN-79).
struct FindNearestStationIntent: AppIntent {
    static var title: LocalizedStringResource {
        LocalizedStringResource("intent.findNearest.title")
    }

    static var description: IntentDescription {
        IntentDescription(LocalizedStringResource("intent.findNearest.description"))
    }

    static var openAppWhenRun: Bool { false }

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        do {
            guard let pair = try await StationIntentLookup.shared.findNearestStation() else {
                let title = String(localized: String.LocalizationValue("intent.error.bannerTitle"))
                let subtitle = String(localized: String.LocalizationValue("intent.error.noStationsInRadius"))
                return .result(
                    dialog: IntentDialog(LocalizedStringResource(stringLiteral: subtitle)),
                    view: StationSnippetView(title: title, subtitle: subtitle)
                )
            }
            let station = pair.station
            let origin = pair.origin
            let km = QueryService.distanceKilometers(
                fromOriginLatitude: origin.latitude,
                originLng: origin.longitude,
                to: station
            )
            let fmt = String(localized: String.LocalizationValue("intent.findNearest.dialog.success"))
            let dialogText = String(format: fmt, locale: .current, station.name)
            return .result(
                dialog: IntentDialog(LocalizedStringResource(stringLiteral: dialogText)),
                view: StationSearchResultSnippetView(station: station, fuel: nil, distanceKm: km)
            )
        } catch LocationProviderError.notAuthorized {
            let title = String(localized: String.LocalizationValue("intent.error.bannerTitle"))
            let subtitle = String(localized: String.LocalizationValue("intent.error.locationDenied"))
            return .result(
                dialog: IntentDialog(LocalizedStringResource(stringLiteral: subtitle)),
                view: StationSnippetView(title: title, subtitle: subtitle)
            )
        } catch let failure as TankerkoenigClient.Failure {
            let title = String(localized: String.LocalizationValue("intent.error.bannerTitle"))
            let subtitle = failure.localizedDescription
            return .result(
                dialog: IntentDialog(LocalizedStringResource(stringLiteral: subtitle)),
                view: StationSnippetView(title: title, subtitle: subtitle)
            )
        } catch {
            let title = String(localized: String.LocalizationValue("intent.error.bannerTitle"))
            let subtitle = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
            return .result(
                dialog: IntentDialog(LocalizedStringResource(stringLiteral: subtitle)),
                view: StationSnippetView(title: title, subtitle: subtitle)
            )
        }
    }
}

// MARK: - Find cheapest

/// Siri/Kurzbefehle: günstigste Tankstelle für eine Sorte; ohne Parameter wie in den App-Einstellungen.
struct FindCheapestStationIntent: AppIntent {
    static var title: LocalizedStringResource {
        LocalizedStringResource("intent.findCheapest.title")
    }

    static var description: IntentDescription {
        IntentDescription(LocalizedStringResource("intent.findCheapest.description"))
    }

    static var openAppWhenRun: Bool { false }

    @Parameter(title: LocalizedStringResource("intent.findCheapest.parameter.fuel"))
    var fuel: FuelType?

    init() {}

    init(fuel: FuelType?) {
        self.fuel = fuel
    }

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        do {
            guard let triple = try await StationIntentLookup.shared.findCheapestStation(explicitFuel: fuel) else {
                let title = String(localized: String.LocalizationValue("intent.error.bannerTitle"))
                let subtitle = String(localized: String.LocalizationValue("intent.error.noStationWithPrice"))
                return .result(
                    dialog: IntentDialog(LocalizedStringResource(stringLiteral: subtitle)),
                    view: StationSnippetView(title: title, subtitle: subtitle)
                )
            }
            let station = triple.station
            let fuel = triple.fuel
            let origin = triple.origin
            guard let price = station.price(for: fuel) else {
                let title = String(localized: String.LocalizationValue("intent.error.bannerTitle"))
                let fmt = String(localized: String.LocalizationValue("intent.error.noPriceForFuel"))
                let subtitle = String(format: fmt, locale: .current, fuel.displayName)
                return .result(
                    dialog: IntentDialog(LocalizedStringResource(stringLiteral: subtitle)),
                    view: StationSnippetView(title: title, subtitle: subtitle)
                )
            }
            let km = QueryService.distanceKilometers(
                fromOriginLatitude: origin.latitude,
                originLng: origin.longitude,
                to: station
            )
            let voicePrice = FuelPriceFormatting.voiceOverString(euros: price)
            let fmt = String(localized: String.LocalizationValue("intent.findCheapest.dialog.success"))
            let dialogText = String(format: fmt, locale: .current, fuel.displayName, station.name, voicePrice)
            return .result(
                dialog: IntentDialog(LocalizedStringResource(stringLiteral: dialogText)),
                view: StationSearchResultSnippetView(station: station, fuel: fuel, distanceKm: km)
            )
        } catch LocationProviderError.notAuthorized {
            let title = String(localized: String.LocalizationValue("intent.error.bannerTitle"))
            let subtitle = String(localized: String.LocalizationValue("intent.error.locationDenied"))
            return .result(
                dialog: IntentDialog(LocalizedStringResource(stringLiteral: subtitle)),
                view: StationSnippetView(title: title, subtitle: subtitle)
            )
        } catch let failure as TankerkoenigClient.Failure {
            let title = String(localized: String.LocalizationValue("intent.error.bannerTitle"))
            let subtitle = failure.localizedDescription
            return .result(
                dialog: IntentDialog(LocalizedStringResource(stringLiteral: subtitle)),
                view: StationSnippetView(title: title, subtitle: subtitle)
            )
        } catch {
            let title = String(localized: String.LocalizationValue("intent.error.bannerTitle"))
            let subtitle = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
            return .result(
                dialog: IntentDialog(LocalizedStringResource(stringLiteral: subtitle)),
                view: StationSnippetView(title: title, subtitle: subtitle)
            )
        }
    }
}
