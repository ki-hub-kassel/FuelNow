import Foundation
import Testing
@testable import FuelNow

/// Tests fuer den Preis-Push-Pfad (Roadmap Phase 3).
///
/// Zwei Ebenen:
/// 1. ``FavoritesStore.recordPriceObservation`` — die deterministische Schwellen-Logik:
///    `firstObservation` / `stable` / `priceDrop` / `noFavorite`.
/// 2. ``PriceAlertCoordinator.runRefreshNow`` — End-to-End vom HTTP-`prices.php`-Mock ueber
///    Decoding, Outcome und Persistenz im Favoriten-Store.
///
/// Der `UNUserNotificationCenter`-Pfad wird **nicht** mitgetestet: in Unit-Tests liefert
/// `notificationSettings()` deterministisch `.notDetermined`, also wird kein Push verschickt
/// — das Verhalten ueberpruefen wir indirekt am `lastSeenPriceXY`-Update am Favoriten.
@MainActor
@Suite(.serialized)
struct PriceAlertCoordinatorTests {
    // MARK: - FavoritesStore.recordPriceObservation (Schwellen-Logik)

    @Test func firstObservationStoresBaselineWithoutDrop() throws {
        let store = makeStore()
        let station = try decodeStation(id: stationIDA, e10: nil)
        store.add(station)

        let outcome = store.recordPriceObservation(
            stationID: stationIDA,
            fuel: .e10,
            newPrice: 1.659,
            thresholdEuros: 0.05
        )

        guard case let .firstObservation(price) = outcome else {
            Issue.record("Expected .firstObservation, got \(outcome)")
            return
        }
        #expect(price == 1.659)
        #expect(store.favorites.first?.lastSeenPriceE10 == 1.659)
    }

    @Test func priceDropAtOrAboveThresholdReportsDrop() throws {
        let store = makeStore()
        let station = try decodeStation(id: stationIDA, e10: 1.659)
        store.add(station)

        // Erstbeobachtung etabliert die Baseline.
        _ = store.recordPriceObservation(
            stationID: stationIDA,
            fuel: .e10,
            newPrice: 1.659,
            thresholdEuros: 0.05
        )

        let outcome = store.recordPriceObservation(
            stationID: stationIDA,
            fuel: .e10,
            newPrice: 1.609,
            thresholdEuros: 0.05
        )

        guard case let .priceDrop(oldPrice, newPrice, dropEuros) = outcome else {
            Issue.record("Expected .priceDrop, got \(outcome)")
            return
        }
        #expect(oldPrice == 1.659)
        #expect(newPrice == 1.609)
        #expect(abs(dropEuros - 0.05) < 0.0001)
        #expect(store.favorites.first?.lastSeenPriceE10 == 1.609)
    }

    @Test func priceDropBelowThresholdReportsStableButUpdatesBaseline() throws {
        let store = makeStore()
        let station = try decodeStation(id: stationIDA, e10: 1.659)
        store.add(station)
        _ = store.recordPriceObservation(stationID: stationIDA, fuel: .e10, newPrice: 1.659, thresholdEuros: 0.05)

        let outcome = store.recordPriceObservation(
            stationID: stationIDA,
            fuel: .e10,
            newPrice: 1.649, // nur 1 Cent
            thresholdEuros: 0.05
        )

        guard case let .stable(price) = outcome else {
            Issue.record("Expected .stable, got \(outcome)")
            return
        }
        #expect(price == 1.649)
        // Wichtig: die Baseline rutscht mit — das ist die dokumentierte Konsequenz und der
        // Grund, warum graduelle Preisrutsche keinen Push ausloesen.
        #expect(store.favorites.first?.lastSeenPriceE10 == 1.649)
    }

    @Test func observationForUnknownStationReturnsNoFavorite() {
        let store = makeStore()
        let outcome = store.recordPriceObservation(
            stationID: stationIDA,
            fuel: .e10,
            newPrice: 1.609,
            thresholdEuros: 0.05
        )
        #expect(outcome == .noFavorite)
    }

    // MARK: - PriceAlertCoordinator.runRefreshNow (End-to-End mit Mock-URLSession)

    @Test func refreshSetsBaselineFromTankerkoenigPricesResponse() async throws {
        let setup = try makeCoordinatorSetup(priceAlertsEnabled: true, threshold: 0.05)
        let station = try decodeStation(id: stationIDA, e10: nil)
        setup.favoritesStore.add(station)

        PriceAlertMockURLProtocol.handler = { _ in
            (Self.okResponse(), Self.pricesPayload(id: self.stationIDA, e10: 1.659))
        }
        defer { PriceAlertMockURLProtocol.handler = nil }

        await setup.coordinator.runRefreshNow()

        let favorite = try #require(setup.favoritesStore.favorites.first)
        #expect(favorite.lastSeenPriceE10 == 1.659)
        #expect(PriceAlertMockURLProtocol.callCount == 1)
    }

    @Test func refreshUpdatesBaselineWhenDropAboveThreshold() async throws {
        let setup = try makeCoordinatorSetup(priceAlertsEnabled: true, threshold: 0.05)
        let station = try decodeStation(id: stationIDA, e10: 1.659)
        setup.favoritesStore.add(station)
        // Baseline auf 1.659 setzen, damit der naechste Lauf einen Drop sieht.
        _ = setup.favoritesStore.recordPriceObservation(
            stationID: stationIDA,
            fuel: .e10,
            newPrice: 1.659,
            thresholdEuros: 0.05
        )

        PriceAlertMockURLProtocol.handler = { _ in
            (Self.okResponse(), Self.pricesPayload(id: self.stationIDA, e10: 1.609))
        }
        defer { PriceAlertMockURLProtocol.handler = nil }

        await setup.coordinator.runRefreshNow()

        let favorite = try #require(setup.favoritesStore.favorites.first)
        #expect(favorite.lastSeenPriceE10 == 1.609)
    }

    @Test func refreshIsNoOpWhenPriceAlertsDisabled() async throws {
        let setup = try makeCoordinatorSetup(priceAlertsEnabled: false, threshold: 0.05)
        let station = try decodeStation(id: stationIDA, e10: 1.659)
        setup.favoritesStore.add(station)

        PriceAlertMockURLProtocol.handler = { _ in
            Issue.record("HTTP-Aufruf darf nicht stattfinden, wenn Preis-Pushes deaktiviert sind.")
            return (Self.okResponse(), Self.pricesPayload(id: self.stationIDA, e10: 1.609))
        }
        defer { PriceAlertMockURLProtocol.handler = nil }

        await setup.coordinator.runRefreshNow()

        let favorite = try #require(setup.favoritesStore.favorites.first)
        // lastSeen wurde bei `add(_:)` initial vom Station-Snapshot uebernommen — bleibt 1.659.
        #expect(favorite.lastSeenPriceE10 == 1.659)
        #expect(PriceAlertMockURLProtocol.callCount == 0)
    }

    @Test func refreshSwallowsHttp429AndKeepsBaseline() async throws {
        let setup = try makeCoordinatorSetup(priceAlertsEnabled: true, threshold: 0.05)
        let station = try decodeStation(id: stationIDA, e10: 1.659)
        setup.favoritesStore.add(station)

        PriceAlertMockURLProtocol.handler = { request in
            let url = try #require(request.url)
            let response = HTTPURLResponse(url: url, statusCode: 429, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }
        defer { PriceAlertMockURLProtocol.handler = nil }

        await setup.coordinator.runRefreshNow()

        let favorite = try #require(setup.favoritesStore.favorites.first)
        #expect(favorite.lastSeenPriceE10 == 1.659)
    }

    // MARK: - Test helpers

    private let stationIDA = UUID(uuidString: "474E5046-DEAF-4F9B-9A32-9797B778F047")!

    private struct CoordinatorSetup {
        let coordinator: PriceAlertCoordinator
        let favoritesStore: FavoritesStore
        let defaults: UserDefaults
        let suiteName: String
    }

    private func makeStore() -> FavoritesStore {
        let suiteName = "PriceAlertCoordinatorTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return FavoritesStore(defaults: defaults, storageKey: "favorites")
    }

    private func makeCoordinatorSetup(
        priceAlertsEnabled: Bool,
        threshold: Double
    ) throws -> CoordinatorSetup {
        let suiteName = "PriceAlertCoordinatorTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(priceAlertsEnabled, forKey: AppSettings.UserDefaultsKey.priceAlertsEnabled)
        defaults.set(threshold, forKey: AppSettings.UserDefaultsKey.priceAlertsThresholdEuros)
        defaults.set(FuelType.e10.rawValue, forKey: AppSettings.UserDefaultsKey.preferredFuelType)

        let store = FavoritesStore(defaults: defaults, storageKey: "favorites")

        let session = makeMockSession()
        let client = TankerkoenigClient(apiKey: "test-uuid-key", session: session)
        let coordinator = PriceAlertCoordinator(
            client: client,
            favoritesStore: store,
            notificationCenter: .current(),
            defaults: defaults,
            preferredFuelDefaults: defaults
        )

        PriceAlertMockURLProtocol.callCount = 0
        return CoordinatorSetup(
            coordinator: coordinator,
            favoritesStore: store,
            defaults: defaults,
            suiteName: suiteName
        )
    }

    /// Baut eine `Station` ueber den realen Decoder; den synthetischen Init gibt es nicht.
    private func decodeStation(id: UUID, e10: Double?) throws -> Station {
        let e10Json = e10.map { "\($0)" } ?? "null"
        let json = """
        {
          "id": "\(id.uuidString.lowercased())",
          "name": "TOTAL TEST",
          "brand": "TOTAL",
          "street": "TESTSTR.",
          "place": "BERLIN",
          "houseNumber": "1",
          "postCode": 10407,
          "lat": 52.52,
          "lng": 13.405,
          "isOpen": true,
          "e5": null,
          "e10": \(e10Json),
          "diesel": null
        }
        """
        return try JSONDecoder().decode(Station.self, from: Data(json.utf8))
    }

    nonisolated private static func okResponse() -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://creativecommons.tankerkoenig.de/json/prices.php")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
    }

    nonisolated private static func pricesPayload(id: UUID, e10: Double) -> Data {
        let body = """
        {
          "ok": true,
          "license": "CC BY 4.0 — MTS-K",
          "data": "MTS-K",
          "prices": {
            "\(id.uuidString.lowercased())": {
              "status": "open",
              "e5": false,
              "e10": \(e10),
              "diesel": false
            }
          }
        }
        """
        return Data(body.utf8)
    }

    private func makeMockSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [PriceAlertMockURLProtocol.self]
        return URLSession(configuration: config)
    }
}

/// Lokaler `URLProtocol`-Stub fuer diese Suite. Bewusst eigenstaendig, damit die Datei nicht
/// vom `MockURLProtocol` aus ``TankerkoenigClientTests`` abhaengt (der dort `private` ist).
private final class PriceAlertMockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var handler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?
    nonisolated(unsafe) static var callCount: Int = 0

    override static func canInit(with request: URLRequest) -> Bool { true }
    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.callCount += 1
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
