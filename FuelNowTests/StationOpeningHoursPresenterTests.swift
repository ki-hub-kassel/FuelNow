import Foundation
import Testing
@testable import FuelNow

struct StationOpeningHoursPresenterTests {
    @Test func moFrMask_includesWednesday() throws {
        let mask = StationOpeningHoursPresenter.weekdayMask(from: "Mo-Fr")
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = StationOpeningHoursPresenter.defaultTimeZone
        let noon = try #require(
            cal.date(from: DateComponents(calendar: cal, year: 2025, month: 5, day: 7, hour: 12))
        )
        let today = StationOpeningHoursPresenter.todayMask(date: noon, calendar: cal)
        #expect(!mask.intersection(today).isEmpty)
    }

    @Test func closingTime_moFrSlot_wednesdayNoon() throws {
        let tz = TimeZone(identifier: "Europe/Berlin")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let noon = try #require(
            cal.date(from: DateComponents(calendar: cal, year: 2025, month: 5, day: 7, hour: 12, minute: 0))
        )
        let json = Data(
            #"""
            {"id":"00000000-0000-0000-0000-0000000000aa","name":"T","brand":"B","street":"S",
            "houseNumber":"1","place":"P","postCode":12345,"lat":52,"lng":13,"isOpen":true,
            "e5":1.2,"e10":1.1,"diesel":1.0,
            "openingTimes":[{"text":"Mo-Fr","start":"06:00:00","end":"22:30:00"}]}
            """#.utf8
        )
        let station = try JSONDecoder().decode(Station.self, from: json)
        let end = StationOpeningHoursPresenter.bestClosingDateIfInOpenInterval(
            station: station,
            now: noon,
            timeZone: tz
        )
        let endUnwrapped = try #require(end)
        #expect(cal.component(.hour, from: endUnwrapped) == 22)
        #expect(cal.component(.minute, from: endUnwrapped) == 30)
    }

    @Test func wholeDay_subtitleNotNil() throws {
        let json = Data(
            #"""
            {"id":"00000000-0000-0000-0000-0000000000bb","name":"T","brand":"B","street":"S",
            "houseNumber":"1","place":"P","postCode":12345,"lat":52,"lng":13,"isOpen":true,
            "wholeDay":true,"e5":1.2,"e10":1.1,"diesel":1.0}
            """#.utf8
        )
        let station = try JSONDecoder().decode(Station.self, from: json)
        let sub = StationOpeningHoursPresenter.openStatusSubtitle(
            station: station,
            locale: Locale(identifier: "de_DE")
        )
        #expect(sub != nil)
    }
}
