import Foundation
import Testing
@testable import FuelNow

@Suite("FuelPriceFormatting · TAN-93 Schilder-Stil")
struct FuelPriceFormattingTests {
    // MARK: - swiftUIComponents

    @Test func swiftUIComponentsSplitsThreeDecimalPrice() throws {
        let parts = try #require(FuelPriceFormatting.swiftUIComponents(euros: 1.589))
        #expect(parts.main == "1,58")
        #expect(parts.tenths == "9")
    }

    @Test func swiftUIComponentsSplitsZeroTenth() throws {
        let parts = try #require(FuelPriceFormatting.swiftUIComponents(euros: 2.100))
        #expect(parts.main == "2,10")
        #expect(parts.tenths == "0")
    }

    @Test func swiftUIComponentsHandlesFloatNoiseLikeTankerkoenig() throws {
        // Tankerkönig liefert `1.589 €` → als Double oft `1.5889999…`. Beim Splitten
        // müssen die runden 1,58⁹ rauskommen, nicht 1,58⁸ oder 1,57⁹.
        let parts = try #require(FuelPriceFormatting.swiftUIComponents(euros: 1.5889999999))
        #expect(parts.main == "1,58")
        #expect(parts.tenths == "9")
    }

    @Test func swiftUIComponentsLeadingZeroOnCents() throws {
        // 1.009 € → "1,00⁹" — Cent-Stelle muss zweistellig bleiben.
        let parts = try #require(FuelPriceFormatting.swiftUIComponents(euros: 1.009))
        #expect(parts.main == "1,00")
        #expect(parts.tenths == "9")
    }

    @Test func swiftUIComponentsNilForMissingPrice() {
        #expect(FuelPriceFormatting.swiftUIComponents(euros: nil) == nil)
    }

    @Test func swiftUIComponentsNilForZero() {
        #expect(FuelPriceFormatting.swiftUIComponents(euros: 0) == nil)
    }

    @Test func swiftUIComponentsNilForNegative() {
        #expect(FuelPriceFormatting.swiftUIComponents(euros: -1.0) == nil)
    }

    @Test func swiftUIComponentsNilForInfinity() {
        #expect(FuelPriceFormatting.swiftUIComponents(euros: .infinity) == nil)
    }

    // MARK: - pumpStyleString

    @Test func pumpStyleStringRendersUnicodeSuperscript() {
        #expect(FuelPriceFormatting.pumpStyleString(euros: 1.589) == "1,58⁹")
        #expect(FuelPriceFormatting.pumpStyleString(euros: 2.109) == "2,10⁹")
        #expect(FuelPriceFormatting.pumpStyleString(euros: 1.500) == "1,50⁰")
    }

    @Test func pumpStyleStringFallbackForMissingPrice() {
        #expect(FuelPriceFormatting.pumpStyleString(euros: nil) == "—")
        #expect(FuelPriceFormatting.pumpStyleString(euros: 0) == "—")
    }

    // MARK: - voiceOverString

    @Test func voiceOverStringSpeaksFullThreeDecimalPrice() {
        // VoiceOver soll alle drei Stellen aussprechen, natürlichsprachlich (de_DE).
        #expect(FuelPriceFormatting.voiceOverString(euros: 1.589) == "1 Euro 58,9 Cent")
    }

    @Test func voiceOverStringHandlesRoundCents() {
        #expect(FuelPriceFormatting.voiceOverString(euros: 2.100) == "2 Euro 10,0 Cent")
    }

    @Test func voiceOverStringFallbackForMissingPrice() {
        #expect(FuelPriceFormatting.voiceOverString(euros: nil) == "Kein Preis verfügbar")
        #expect(FuelPriceFormatting.voiceOverString(euros: 0) == "Kein Preis verfügbar")
    }

    @Test func voiceOverStringNeverContainsSuperscript() {
        // VoiceOver darf niemals die Schilder-Schreibweise lesen — sonst sagt es
        // „eins Komma fünfacht hochgestellt neun".
        let voice = FuelPriceFormatting.voiceOverString(euros: 1.589)
        #expect(!voice.contains("⁹"))
        #expect(!voice.contains("⁰"))
    }
}
