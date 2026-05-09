import CoreLocation
import SwiftUI

// MARK: - Preview Helpers

private struct StationListEnvelope: Decodable {
    let stations: [Station]
}

private struct PreviewThrowingFetcher: StationFetching {
    func fetchStations(latitude _: Double, longitude _: Double, radiusKm _: Double) async throws -> [Station] {
        throw URLError(.notConnectedToInternet)
    }
}

private actor PreviewStationFetcher: StationFetching {
    private let stations: [Station]

    init(stations: [Station]) {
        self.stations = stations
    }

    func fetchStations(latitude _: Double, longitude _: Double, radiusKm _: Double) async throws -> [Station] {
        stations
    }
}

private struct PreviewLocationStreamProvider: LocationStreamProviding {
    func makeStream() -> AsyncThrowingStream<LocationStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(LocationStreamEvent(latitude: 52.53, longitude: 13.44, horizontalAccuracy: 10))
            continuation.finish()
        }
    }
}

private enum MapScreenPreviewHarness {
    static var deepLinkStore: MapDeepLinkStore {
        MapDeepLinkStore(defaults: UserDefaults(suiteName: "tr.preview.MapScreen.deeplink")!)
    }

    @MainActor
    static func networkMonitor(snapshot: NetworkPathSnapshot = .satisfied) -> NetworkMonitor {
        NetworkMonitor(provider: PreviewNetworkPathProvider(), initialSnapshot: snapshot)
    }
}

private final class PreviewNetworkPathProvider: NetworkPathProviding, @unchecked Sendable {
    func makeStream() -> AsyncStream<NetworkPathSnapshot> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    func cancel() {}
}

private enum MapScreenPreviewData {
    static let stations: [Station] = {
        let json = Data(
            """
            {"stations":[{"id":"474e5046-deaf-4f9b-9a32-9797b778f047","name":"TOTAL BERLIN",
            "brand":"TOTAL","street":"MARGARETE-SOMMER-STR.","place":"BERLIN","lat":52.53083,
            "lng":13.440946,"dist":1.1,"diesel":1.109,"e5":1.339,"e10":1.319,"isOpen":true,
            "houseNumber":"2","postCode":10407}]}
            """.utf8
        )
        return (try? JSONDecoder().decode(StationListEnvelope.self, from: json).stations) ?? []
    }()
}

// MARK: - Previews

#Preview("Light") {
    NavigationStack {
        MapScreen()
    }
    .environment(LocationService(streamProvider: PreviewLocationStreamProvider(), authorizationProvider: { .authorizedWhenInUse }))
    .environment(StationStore(fetcher: PreviewStationFetcher(stations: MapScreenPreviewData.stations)))
    .environment(MapScreenPreviewHarness.deepLinkStore)
    .environment(MapScreenPreviewHarness.networkMonitor())
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        MapScreen()
    }
    .environment(LocationService(streamProvider: PreviewLocationStreamProvider(), authorizationProvider: { .authorizedWhenInUse }))
    .environment(StationStore(fetcher: PreviewStationFetcher(stations: MapScreenPreviewData.stations)))
    .environment(MapScreenPreviewHarness.deepLinkStore)
    .environment(MapScreenPreviewHarness.networkMonitor())
    .preferredColorScheme(.dark)
}

#Preview("Accessibility 3") {
    NavigationStack {
        MapScreen()
    }
    .environment(LocationService(streamProvider: PreviewLocationStreamProvider(), authorizationProvider: { .authorizedWhenInUse }))
    .environment(StationStore(fetcher: PreviewStationFetcher(stations: MapScreenPreviewData.stations)))
    .environment(MapScreenPreviewHarness.deepLinkStore)
    .environment(MapScreenPreviewHarness.networkMonitor())
    .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Leer — keine Stationen") {
    NavigationStack {
        MapScreen()
    }
    .environment(LocationService(streamProvider: PreviewLocationStreamProvider(), authorizationProvider: { .authorizedWhenInUse }))
    .environment(StationStore(fetcher: PreviewStationFetcher(stations: [])))
    .environment(MapScreenPreviewHarness.deepLinkStore)
    .environment(MapScreenPreviewHarness.networkMonitor())
    .preferredColorScheme(.light)
}

#Preview("Leer — Dark") {
    NavigationStack {
        MapScreen()
    }
    .environment(LocationService(streamProvider: PreviewLocationStreamProvider(), authorizationProvider: { .authorizedWhenInUse }))
    .environment(StationStore(fetcher: PreviewStationFetcher(stations: [])))
    .environment(MapScreenPreviewHarness.deepLinkStore)
    .environment(MapScreenPreviewHarness.networkMonitor())
    .preferredColorScheme(.dark)
}

#Preview("Fetch-Fehler") {
    NavigationStack {
        MapScreen()
    }
    .environment(LocationService(streamProvider: PreviewLocationStreamProvider(), authorizationProvider: { .authorizedWhenInUse }))
    .environment(StationStore(fetcher: PreviewThrowingFetcher()))
    .environment(MapScreenPreviewHarness.deepLinkStore)
    .environment(MapScreenPreviewHarness.networkMonitor())
}

#Preview("Offline-Splash") {
    NavigationStack {
        MapScreen()
    }
    .environment(LocationService(streamProvider: PreviewLocationStreamProvider(), authorizationProvider: { .authorizedWhenInUse }))
    .environment(StationStore(fetcher: PreviewStationFetcher(stations: MapScreenPreviewData.stations)))
    .environment(MapScreenPreviewHarness.deepLinkStore)
    .environment(MapScreenPreviewHarness.networkMonitor(snapshot: .unsatisfied))
}
