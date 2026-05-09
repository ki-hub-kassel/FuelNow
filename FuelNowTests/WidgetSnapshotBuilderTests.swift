import Foundation
import Testing
@testable import FuelNow

@Suite("WidgetSnapshotBuilder")
struct WidgetSnapshotBuilderTests {
    @Test func snapshotContainsNearestAndCheapestForPreferredFuel() throws {
        let nearest = try makeStation(
            id: "00000000-0000-0000-0000-000000000001",
            name: "Nearest",
            distanceKm: 0.8,
            prices: StationFixturePrices(e5: 1.689, e10: 1.659, diesel: 1.549)
        )
        let cheapest = try makeStation(
            id: "00000000-0000-0000-0000-000000000002",
            name: "Cheapest",
            distanceKm: 2.0,
            prices: StationFixturePrices(e5: 1.629, e10: 1.599, diesel: 1.529)
        )
        let snapshot = WidgetSnapshotBuilder.makeSnapshot(
            stations: [nearest, cheapest],
            preferredFuel: .e10,
            loadState: .loaded,
            generatedAt: Date(timeIntervalSince1970: 123)
        )

        #expect(snapshot.loadState == .ready)
        #expect(snapshot.stationCount == 2)
        #expect(snapshot.nearest?.stationID == nearest.id)
        #expect(snapshot.cheapest?.stationID == cheapest.id)
        #expect(snapshot.nearest?.pumpPriceText == FuelPriceFormatting.pumpStyleString(euros: nearest.price(for: .e10)))
        #expect(snapshot.cheapest?.pumpPriceText == FuelPriceFormatting.pumpStyleString(euros: cheapest.price(for: .e10)))
    }

    @Test func snapshotMarksEmptyWhenNoStationsLoaded() {
        let snapshot = WidgetSnapshotBuilder.makeSnapshot(
            stations: [],
            preferredFuel: .e10,
            loadState: .loaded
        )

        #expect(snapshot.loadState == .empty)
        #expect(snapshot.nearest == nil)
        #expect(snapshot.cheapest == nil)
    }

    @Test func snapshotMarksLoadingState() {
        let snapshot = WidgetSnapshotBuilder.makeSnapshot(
            stations: [],
            preferredFuel: .diesel,
            loadState: .loading
        )

        #expect(snapshot.loadState == .loading)
    }

    @Test func snapshotStoreRoundTrip() {
        let store = WidgetSnapshotStore()
        let payload = WidgetDataSnapshot(
            generatedAt: Date(timeIntervalSince1970: 999),
            loadState: .ready,
            preferredFuelRawValue: FuelType.e10.rawValue,
            stationCount: 1,
            nearest: nil,
            cheapest: nil
        )

        store.write(payload)
        let loaded = store.read()

        #expect(loaded == payload)
    }

    private func makeStation(
        id: String,
        name: String,
        distanceKm: Double,
        prices: StationFixturePrices
    ) throws -> Station {
        let json = """
        {
          "id":"\(id)",
          "name":"\(name)",
          "brand":"\(name)",
          "street":"Musterstraße",
          "houseNumber":"1",
          "place":"Kassel",
          "postCode":"34117",
          "lat":51.3127,
          "lng":9.4797,
          "dist":\(distanceKm),
          "isOpen":true,
          "e5":\(prices.e5),
          "e10":\(prices.e10),
          "diesel":\(prices.diesel)
        }
        """

        return try JSONDecoder().decode(Station.self, from: Data(json.utf8))
    }
}

private struct StationFixturePrices {
    let e5: Double
    let e10: Double
    let diesel: Double
}
