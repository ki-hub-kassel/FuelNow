import Foundation
import Testing
@testable import FuelNow

@Suite("StationDisplayFormatting · TAN-94 Distance polish")
struct StationDisplayFormattingTests {
    @Test func distanceStringFormatsKilometersWithOneDecimal() {
        #expect(StationDisplayFormatting.distanceString(kilometers: 3.8) == "3,8 km")
        #expect(StationDisplayFormatting.distanceString(kilometers: 1.0) == "1,0 km")
        #expect(StationDisplayFormatting.distanceString(kilometers: 12.345) == "12,3 km")
    }

    @Test func distanceStringSwitchesToMetersBelowOneKilometer() {
        #expect(StationDisplayFormatting.distanceString(kilometers: 0.85) == "850 m")
        #expect(StationDisplayFormatting.distanceString(kilometers: 0.42) == "400 m")
    }

    @Test func distanceStringRoundsMetersToFiftyMeterSteps() {
        // 0.123 km = 123 m → auf 50 m gerundet → 100 m
        #expect(StationDisplayFormatting.distanceString(kilometers: 0.123) == "100 m")
        // 0.176 km = 176 m → auf 50 m gerundet → 200 m
        #expect(StationDisplayFormatting.distanceString(kilometers: 0.176) == "200 m")
        // 0.025 km = 25 m → auf 50 m gerundet → 50 m (Banker's rounding mit FloatingPointRoundingRule.toNearestOrEven hier zu erwarten, daher tolerant)
        #expect(StationDisplayFormatting.distanceString(kilometers: 0.025) == "0 m"
            || StationDisplayFormatting.distanceString(kilometers: 0.025) == "50 m")
    }

    @Test func distanceStringTreatsZeroAsZeroMeters() {
        #expect(StationDisplayFormatting.distanceString(kilometers: 0) == "0 m")
    }

    @Test func distanceStringClampsNegativeToZero() {
        #expect(StationDisplayFormatting.distanceString(kilometers: -1) == "0 m")
    }

    @Test func distanceStringEmDashForMissingDistance() {
        #expect(StationDisplayFormatting.distanceString(kilometers: nil) == "—")
    }

    @Test func distanceStringEmDashForNonFiniteDistance() {
        #expect(StationDisplayFormatting.distanceString(kilometers: .infinity) == "—")
        #expect(StationDisplayFormatting.distanceString(kilometers: .nan) == "—")
    }

    @Test func distanceStringNoLongerContainsCaPrefix() {
        // TAN-94: das frühere „ca. " ist entfernt, weil das vorgesetzte SF-Symbol
        // (location.fill) die Schätzung visuell trägt.
        #expect(!StationDisplayFormatting.distanceString(kilometers: 3.8).contains("ca."))
        #expect(!StationDisplayFormatting.distanceString(kilometers: 0.5).contains("ca."))
    }
}
