import SwiftUI

private struct StationDetailPreviewEnvelope: Decodable {
    let stations: [Station]
}

#Preview("Station detail · Standard") {
    StationDetailPreviewHost(dynamicType: .medium)
}

#Preview("Station detail · Accessibility 3") {
    StationDetailPreviewHost(dynamicType: .accessibility3)
}

#Preview("Station detail · Accessibility XXL") {
    StationDetailPreviewHost(dynamicType: .accessibility5)
}

@MainActor
private struct StationDetailPreviewHost: View {
    var dynamicType: DynamicTypeSize

    var body: some View {
        let json = Data(
            """
            {"stations":[{"id":"474e5046-deaf-4f9b-9a32-9797b778f047","name":"TOTAL BERLIN",
            "brand":"TOTAL","street":"MARGARETE-SOMMER-STR.","place":"BERLIN","lat":52.53083,
            "lng":13.440946,"dist":1.12,"diesel":1.109,"e5":1.339,"e10":1.319,"isOpen":true,
            "houseNumber":"2","postCode":10407}]}
            """.utf8
        )
        let station = (try? JSONDecoder().decode(StationDetailPreviewEnvelope.self, from: json).stations.first)!
        let detailFetcher = StationDetailPreviewDetailFetcher(previewStationID: station.id)
        return NavigationStack {
            StationDetailView(station: station, preferredFuel: .e10)
        }
        .environment(\.dynamicTypeSize, dynamicType)
        .environment(\.stationDetailFetcher, detailFetcher)
        .environment(LocationService())
        .environment(FavoritesStore())
        .environment(EntitlementManager())
    }
}

private struct StationDetailPreviewDetailFetcher: StationDetailFetching {
    let previewStationID: UUID

    func fetchStationDetail(id: UUID) async throws -> Station {
        guard id == previewStationID else {
            struct PreviewMismatch: Error {}
            throw PreviewMismatch()
        }
        let detailJSON = Data(
            """
            {"id":"474e5046-deaf-4f9b-9a32-9797b778f047","name":"TOTAL BERLIN",
            "brand":"TOTAL","street":"MARGARETE-SOMMER-STR.","place":"BERLIN","lat":52.53083,
            "lng":13.440946,"dist":1.12,"diesel":1.109,"e5":1.339,"e10":1.319,"isOpen":true,
            "houseNumber":"2","postCode":10407,"wholeDay":false,
            "openingTimes":[
              {"text":"Mo-Fr","start":"06:00:00","end":"22:30:00"},
              {"text":"Samstag","start":"07:00:00","end":"22:00:00"}
            ]}
            """.utf8
        )
        return try JSONDecoder().decode(Station.self, from: detailJSON)
    }
}
