import AppIntents
import Foundation
import SwiftUI

private enum StationIntentErrorPresentation {
    case noStationsInRadius
    case noStationWithPrice
    case noPriceForFuel(fuelDisplayName: String)
    case locationDenied
    case failure(String)

    var title: String {
        switch self {
        case .noStationsInRadius:
            return String(localized: "intent.error.title.noStations")
        case .noStationWithPrice:
            return String(localized: "intent.error.title.noPrice")
        case .noPriceForFuel:
            return String(localized: "intent.error.title.noPrice")
        case .locationDenied:
            return String(localized: "intent.error.title.location")
        case .failure:
            return String(localized: "intent.error.title.general")
        }
    }

    var subtitle: String {
        switch self {
        case .noStationsInRadius:
            return String(localized: "intent.error.noStationsInRadius")
        case .noStationWithPrice:
            return String(localized: "intent.error.noStationWithPrice")
        case let .noPriceForFuel(fuelDisplayName):
            let format = String(localized: "intent.error.noPriceForFuel")
            return String(format: format, locale: .current, fuelDisplayName)
        case .locationDenied:
            return String(localized: "intent.error.locationDenied")
        case let .failure(message):
            return message
        }
    }

    var systemImage: String {
        switch self {
        case .locationDenied:
            return "location.slash"
        case .noStationsInRadius, .noStationWithPrice, .noPriceForFuel:
            return "fuelpump.slash"
        case .failure:
            return "exclamationmark.triangle"
        }
    }

    /// Spoken dialog für VoiceOver/Siri (entspricht dem Subtitle).
    var dialog: IntentDialog {
        IntentDialog(LocalizedStringResource(stringLiteral: subtitle))
    }

    /// SwiftUI-View, die im Snippet als Fehler-/Hinweis-Karte erscheint.
    var snippetView: some View {
        StationSnippetView(systemImage: systemImage, title: title, subtitle: subtitle)
    }
}

/// Mappt einen geworfenen Fehler aus den Lookup-Pfaden auf eine Snippet-Präsentation.
private func presentation(for error: Error) -> StationIntentErrorPresentation {
    if case LocationProviderError.notAuthorized = error {
        return .locationDenied
    }
    if let failure = error as? TankerkoenigClient.Failure {
        return .failure(failure.localizedDescription)
    }
    let message = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
    return .failure(message)
}

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

    static var isDiscoverable: Bool { true }

    /// Siri/Kurzbefehle ohne geöffnete App: Hintergrundausführung + ggf. Übergang ins UI (iOS 26).
    static var supportedModes: IntentModes {
        [.background, .foreground(.dynamic)]
    }

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        do {
            guard let pair = try await StationIntentLookup.shared.findNearestStation() else {
                let error = StationIntentErrorPresentation.noStationsInRadius
                return .result(dialog: error.dialog, view: AnyView(error.snippetView))
            }
            let station = pair.station
            let origin = pair.origin
            let km = QueryService.distanceKilometers(
                fromOriginLatitude: origin.latitude,
                originLng: origin.longitude,
                to: station
            )
            let preferredFuel = StationIntentLookup.resolvedFuel(defaults: .standard, explicit: nil)
            let preferredFuelWithPrice = station.price(for: preferredFuel) == nil ? nil : preferredFuel
            let fmt = String(localized: "intent.findNearest.dialog.success")
            let dialogText = String(format: fmt, locale: .current, station.name, km)
            return .result(
                dialog: IntentDialog(LocalizedStringResource(stringLiteral: dialogText)),
                view: AnyView(
                    StationSearchResultSnippetView(
                        station: station,
                        mode: .nearest(preferredFuel: preferredFuelWithPrice),
                        distanceKm: km
                    )
                )
            )
        } catch {
            let error = presentation(for: error)
            return .result(dialog: error.dialog, view: AnyView(error.snippetView))
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

    static var isDiscoverable: Bool { true }

    static var supportedModes: IntentModes {
        [.background, .foreground(.dynamic)]
    }

    @Parameter(title: LocalizedStringResource("intent.findCheapest.parameter.fuel"))
    var fuel: FuelType?

    init() {}

    init(fuel: FuelType?) {
        self.fuel = fuel
    }

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        do {
            guard let triple = try await StationIntentLookup.shared.findCheapestStation(explicitFuel: fuel) else {
                let error = StationIntentErrorPresentation.noStationWithPrice
                return .result(dialog: error.dialog, view: AnyView(error.snippetView))
            }
            let station = triple.station
            let fuel = triple.fuel
            let origin = triple.origin
            guard let price = station.price(for: fuel) else {
                let error = StationIntentErrorPresentation.noPriceForFuel(fuelDisplayName: fuel.displayName)
                return .result(dialog: error.dialog, view: AnyView(error.snippetView))
            }
            let km = QueryService.distanceKilometers(
                fromOriginLatitude: origin.latitude,
                originLng: origin.longitude,
                to: station
            )
            let voicePrice = FuelPriceFormatting.voiceOverString(euros: price)
            let fmt = String(localized: "intent.findCheapest.dialog.success")
            let dialogText = String(format: fmt, locale: .current, fuel.displayName, station.name, voicePrice)
            return .result(
                dialog: IntentDialog(LocalizedStringResource(stringLiteral: dialogText)),
                view: AnyView(
                    StationSearchResultSnippetView(
                        station: station,
                        mode: .cheapest(fuel: fuel),
                        distanceKm: km
                    )
                )
            )
        } catch {
            let error = presentation(for: error)
            return .result(dialog: error.dialog, view: AnyView(error.snippetView))
        }
    }
}
