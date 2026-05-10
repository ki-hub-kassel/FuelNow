import AppIntents
import Foundation
import Testing
@testable import FuelNow

private struct StationListEnvelope: Decodable {
    let stations: [Station]
}

private struct MockStationIntentResolver: StationIntentResolving {
    private let byID: [Station.ID: Station]

    init(stations: [Station]) {
        byID = Dictionary(uniqueKeysWithValues: stations.map { ($0.id, $0) })
    }

    func stations(for ids: [Station.ID]) async throws -> [Station] {
        ids.compactMap { byID[$0] }
    }
}

struct StationIntentTests {
    @Test func fuelTypeCoversAllCasesAsAppEnum() {
        #expect(Set(FuelType.allCases) == [.e5, .e10, .diesel])
    }

    @Test func stationEntityPreservesIdentityAndTitle() throws {
        let data = try loadFixture(named: "station-list-sample")
        let station = try #require(try JSONDecoder().decode(StationListEnvelope.self, from: data).stations.first)
        let entity = StationEntity(station: station)
        #expect(entity.id == station.id)
        #expect(entity.title == station.name)
        #expect(entity.indexingDetailLine == nil)
    }

    @Test func stationQueryResolvesViaInjectedResolver() async throws {
        let data = try loadFixture(named: "station-list-sample")
        let station = try #require(try JSONDecoder().decode(StationListEnvelope.self, from: data).stations.first)

        await StationIntentResolution.shared.setResolver(MockStationIntentResolver(stations: [station]))
        let entities = try await StationQuery().entities(for: [station.id])
        await StationIntentResolution.shared.setResolver(EmptyStationIntentResolver())

        #expect(entities.count == 1)
        #expect(entities.first?.id == station.id)
        #expect(entities.first?.title == station.name)
    }

    @Test func stationQueryReturnsEmptyWhenResolverHasNoMatch() async throws {
        let missingID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        await StationIntentResolution.shared.setResolver(EmptyStationIntentResolver())
        let entities = try await StationQuery().entities(for: [missingID])
        #expect(entities.isEmpty)
    }

    /// Siri-Dialog für „günstigste Tankstelle“ soll den gesprochenen Preis (`voiceOverString`) einbetten, nicht „€/l“.
    @Test func findCheapestDialogTemplateEmbedsVoicePricePhrase() {
        let germanTemplate = String(
            localized: String.LocalizationValue("intent.findCheapest.dialog.success"),
            locale: Locale(identifier: "de_DE")
        )
        let voice = FuelPriceFormatting.voiceOverString(euros: 1.589)
        let lineDe = String(
            format: germanTemplate,
            locale: Locale(identifier: "de_DE"),
            "Super E10",
            "Demo Tankstelle",
            voice
        )
        #expect(lineDe.contains(voice))
        #expect(voice.contains("Euro"))
        #expect(voice.contains("Cent"))

        let englishTemplate = String(
            localized: String.LocalizationValue("intent.findCheapest.dialog.success"),
            locale: Locale(identifier: "en_US")
        )
        let lineEn = String(
            format: englishTemplate,
            locale: Locale(identifier: "en_US"),
            "Super E10",
            "Demo Station",
            voice
        )
        #expect(lineEn.contains(voice))
    }

    @Test func findNearestDialogTemplateSupportsStationAndDistance() {
        let germanTemplate = String(
            localized: String.LocalizationValue("intent.findNearest.dialog.success"),
            locale: Locale(identifier: "de_DE")
        )
        let lineDe = String(
            format: germanTemplate,
            locale: Locale(identifier: "de_DE"),
            "Demo Tankstelle",
            1.2
        )
        #expect(lineDe.contains("Demo Tankstelle"))
        #expect(lineDe.contains("1,2"))

        let englishTemplate = String(
            localized: String.LocalizationValue("intent.findNearest.dialog.success"),
            locale: Locale(identifier: "en_US")
        )
        let lineEn = String(
            format: englishTemplate,
            locale: Locale(identifier: "en_US"),
            "Demo Station",
            1.2
        )
        #expect(lineEn.contains("Demo Station"))
        #expect(lineEn.contains("1.2"))
    }

    /// TAN-96: Die neuen Snippet-Header-Keys existieren und liefern nicht-leere Strings,
    /// und der Cheapest-Headline-Format akzeptiert ein Sortenargument.
    ///
    /// Wir prüfen hier bewusst nicht die Sprache, weil `String(localized:locale:)`
    /// die `locale`-Argument nur für die Zahlen-Substitution nutzt — die Sprachauswahl
    /// stammt aus `Bundle.preferredLocalizations`. Sprachtests laufen über die
    /// xcstrings-Snapshot-Verifikation in der CI, nicht über Unit-Tests.
    @Test func snippetHeaderStringKeysExistAndFormat() {
        let cheapestHeadline = String(
            format: String(localized: "intent.snippet.cheapest.headline"),
            "Super E5"
        )
        #expect(cheapestHeadline.contains("Super E5"))
        #expect(!cheapestHeadline.isEmpty)
        #expect(!cheapestHeadline.contains("intent.snippet.cheapest.headline"))

        let nearestHeadline = String(localized: "intent.snippet.nearest.headline")
        #expect(!nearestHeadline.isEmpty)
        #expect(!nearestHeadline.contains("intent.snippet.nearest.headline"))

        let priceCaption = String(localized: "intent.snippet.heroPriceCaption")
        let distanceCaption = String(localized: "intent.snippet.heroDistanceCaption")
        #expect(!priceCaption.isEmpty)
        #expect(!distanceCaption.isEmpty)
        #expect(priceCaption != distanceCaption)
    }

    /// TAN-96: Result-Snippet-View ist mit beiden Modes instanziierbar — schützt
    /// die `Mode`-API vor versehentlichen Brüchen.
    @Test func resultSnippetViewBuildsForBothModes() throws {
        let data = try loadFixture(named: "station-list-sample")
        let station = try #require(try JSONDecoder().decode(StationListEnvelope.self, from: data).stations.first)

        _ = StationSearchResultSnippetView(
            station: station,
            mode: .cheapest(fuel: .e5),
            distanceKm: 1.2
        )
        _ = StationSearchResultSnippetView(
            station: station,
            mode: .nearest(preferredFuel: .e10),
            distanceKm: 0.85
        )
        _ = StationSearchResultSnippetView(
            station: station,
            mode: .nearest(preferredFuel: nil),
            distanceKm: 3.4
        )
    }

    private func loadFixture(named name: String) throws -> Data {
        let bundle = Bundle(for: BundleToken.self)
        let url = try #require(bundle.url(forResource: name, withExtension: "json"))
        return try Data(contentsOf: url)
    }
}

private final class BundleToken: NSObject {}
