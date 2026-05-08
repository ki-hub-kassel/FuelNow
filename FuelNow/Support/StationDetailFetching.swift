import Foundation
import SwiftUI

/// On-Demand-`detail.php` für eine Station (Öffnungszeiten) — kein Polling, nur bei geöffnetem Detail.
protocol StationDetailFetching: Sendable {
    func fetchStationDetail(id: UUID) async throws -> Station
}

struct TankerkoenigStationDetailFetcher: StationDetailFetching {
    let client: TankerkoenigClient

    func fetchStationDetail(id: UUID) async throws -> Station {
        try await client.fetchStationDetail(id: id)
    }
}

extension EnvironmentValues {
    @Entry var stationDetailFetcher: (any StationDetailFetching)?
}
