import Foundation
import Testing
@testable import FuelNow

struct CarPlayStationDetailFormattingTests {
    @Test("Öffnungszeiten-Zeile enthält Status und Schließ-Untertitel wenn geöffnet")
    func openingHoursIncludesSubtitleWhenOpen() throws {
        let station = try decodeStation(
            """
            {"id":"33333333-3333-3333-3333-333333333333","name":"Shell","brand":"Shell",
            "street":"Musterstr.","place":"Berlin","lat":52.51,"lng":13.39,"dist":0.5,
            "diesel":1.799,"e5":1.899,"e10":1.849,"isOpen":true,"houseNumber":"10","postCode":10115,
            "wholeDay":false,
            "openingTimes":[{"text":"Mo-Fr","start":"06:00","end":"22:00"}]}
            """
        )
        let lines = CarPlayStationDetailFormatting.openingHoursDetailLines(station: station)
        #expect(lines.contains(String(localized: "station.status.open")))
        #expect(lines.contains("\n"))
    }

    @Test("Öffnungszeiten-Zeile zeigt nur Geschlossen ohne Untertitel")
    func openingHoursClosedWithoutSubtitle() throws {
        let station = try decodeStation(
            """
            {"id":"44444444-4444-4444-4444-444444444444","name":"Closed","brand":"X",
            "street":"S","place":"P","lat":52.5,"lng":13.4,"dist":1,"diesel":1.5,
            "e5":1.6,"e10":1.55,"isOpen":false,"houseNumber":"1","postCode":10115}
            """
        )
        let lines = CarPlayStationDetailFormatting.openingHoursDetailLines(station: station)
        #expect(lines == String(localized: "station.status.closed"))
    }

    @Test("Standort liefert fullAddress oder nil wenn leer")
    func locationDetailUsesFullAddress() throws {
        let station = try decodeStation(
            """
            {"id":"55555555-5555-5555-5555-555555555555","name":"T","brand":"B",
            "street":"Hauptstr.","place":"Berlin","lat":52.5,"lng":13.4,"dist":1,
            "diesel":1.5,"e5":1.6,"e10":1.55,"isOpen":true,"houseNumber":"12","postCode":10115}
            """
        )
        let location = CarPlayStationDetailFormatting.locationDetail(station: station)
        #expect(location?.contains("Hauptstr.") == true)
        #expect(location?.contains("Berlin") == true)
    }

    private func decodeStation(_ jsonLine: String) throws -> Station {
        try JSONDecoder().decode(Station.self, from: Data(jsonLine.utf8))
    }
}
