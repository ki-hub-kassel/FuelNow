import Foundation

/// Anzeige-Logik für Tankerkönig-`openingTimes` (`text` + `start`/`end` als Uhrzeit, vgl. API-Doku).
enum StationOpeningHoursPresenter: Sendable {
    /// Anzeige-Zeitzone (Tankstellen in DE).
    static var defaultTimeZone: TimeZone { TimeZone(identifier: "Europe/Berlin")! }

    // MARK: - Public

    static func calendar(timeZone: TimeZone) -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        cal.locale = Locale(identifier: "de_DE")
        return cal
    }

    /// Einzeiliger Untertitel neben „Geöffnet“: z. B. Schließzeit heute.
    static func openStatusSubtitle(
        station: Station,
        now: Date = Date(),
        timeZone: TimeZone = defaultTimeZone,
        locale: Locale = .current
    ) -> String? {
        guard station.isOpen else { return nil }
        if station.wholeDay == true {
            return String(localized: "station.openingHours.subtitle.wholeDay")
        }
        guard let end = bestClosingDateIfInOpenInterval(
            station: station,
            now: now,
            timeZone: timeZone
        ) else {
            return nil
        }
        let time = timeString(date: end, timeZone: timeZone, locale: locale)
        return String(format: String(localized: "station.openingHours.subtitle.untilFormat"), time)
    }

    static func popoverModel(
        station: Station,
        now: Date = Date(),
        timeZone: TimeZone = defaultTimeZone,
        locale: Locale = .current
    ) -> StationOpeningHoursPopoverModel {
        var lines: [String] = []
        if let opening = station.openingTimes {
            for row in opening {
                let a = shortTimeString(clock: row.start, timeZone: timeZone, locale: locale) ?? row.start
                let b = shortTimeString(clock: row.end, timeZone: timeZone, locale: locale) ?? row.end
                let label = row.text.trimmingCharacters(in: .whitespacesAndNewlines)
                if label.isEmpty {
                    lines.append(
                        String(format: String(localized: "station.openingHours.row.timeRangeFormat"), a, b)
                    )
                } else {
                    lines.append(
                        String(
                            format: String(localized: "station.openingHours.row.labeledTimeRangeFormat"),
                            label, a, b
                        )
                    )
                }
            }
        }
        let overrideLines: [String]? = station.overrides.map { o in
            o.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        }.flatMap { $0.isEmpty ? nil : $0 }

        let primary: String?
        if station.isOpen {
            if station.wholeDay == true {
                primary = String(localized: "station.openingHours.primary.openWholeDay")
            } else if let end = bestClosingDateIfInOpenInterval(station: station, now: now, timeZone: timeZone) {
                let time = timeString(date: end, timeZone: timeZone, locale: locale)
                primary = String(format: String(localized: "station.openingHours.primary.untilFormat"), time)
            } else {
                primary = String(localized: "station.openingHours.primary.openNoInterval")
            }
        } else {
            primary = String(localized: "station.openingHours.primary.closed")
        }

        return StationOpeningHoursPopoverModel(
            primaryLine: primary,
            scheduleLines: lines,
            overrideLines: overrideLines
        )
    }

    // MARK: - Interval / weekday

    struct WeekdayMask: OptionSet, Sendable {
        let rawValue: Int
        static let mon = Self(rawValue: 1 << 0)
        static let tue = Self(rawValue: 1 << 1)
        static let wed = Self(rawValue: 1 << 2)
        static let thu = Self(rawValue: 1 << 3)
        static let fri = Self(rawValue: 1 << 4)
        static let sat = Self(rawValue: 1 << 5)
        static let sun = Self(rawValue: 1 << 6)
        static let everyDay: Self = [.mon, .tue, .wed, .thu, .fri, .sat, .sun]
    }

    /// Mon=0 … So=6 (vereinbart mit ``WeekdayMask``-Bits).
    static func mondayFirstDayIndex(from date: Date, calendar: Calendar) -> Int {
        let weekday = calendar.component(.weekday, from: date)
        return (weekday + 5) % 7
    }

    static func todayMask(date: Date, calendar: Calendar) -> WeekdayMask {
        let idx = mondayFirstDayIndex(from: date, calendar: calendar)
        return WeekdayMask(rawValue: 1 << idx)
    }

    static func weekdayMask(from scheduleText: String) -> WeekdayMask {
        let collapsed = scheduleText
            .lowercased()
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: " ", with: "")

        if collapsed.contains("täglich") || collapsed.contains("tgl") { return .everyDay }
        if collapsed.contains("mo-so") || collapsed.contains("montag-sonntag") { return .everyDay }

        if collapsed.contains("-") {
            let parts = collapsed.split(separator: "-", omittingEmptySubsequences: true).map(String.init)
            if parts.count == 2,
               let a = dayIndex(from: parts[0]),
               let b = dayIndex(from: parts[1]) {
                return mask(range: min(a, b)...max(a, b))
            }
        }

        if let single = dayIndex(from: collapsed) {
            return WeekdayMask(rawValue: 1 << single)
        }

        // Unbekannt — konservativ alle Tage annehmen, damit typische Texte nicht leer bleiben.
        return .everyDay
    }

    static func bestClosingDateIfInOpenInterval(
        station: Station,
        now: Date,
        timeZone: TimeZone
    ) -> Date? {
        guard station.isOpen, station.wholeDay != true else { return nil }
        guard let slots = station.openingTimes, !slots.isEmpty else { return nil }

        let calendar = calendar(timeZone: timeZone)
        let todayBit = todayMask(date: now, calendar: calendar)

        var best: Date?
        for slot in slots {
            let mask = weekdayMask(from: slot.text)
            guard !mask.isDisjoint(with: todayBit) else { continue }

            guard let start = clockTimeOnSameDay(clock: slot.start, reference: now, calendar: calendar),
                  let endClock = clockTimeOnSameDay(clock: slot.end, reference: now, calendar: calendar)
            else { continue }

            var end = endClock
            if end <= start {
                end = calendar.date(byAdding: .day, value: 1, to: end) ?? end
            }
            if now >= start, now <= end {
                if best == nil || end > best! {
                    best = end
                }
            }
        }
        return best
    }

    // MARK: - Private

    private static func mask(range: ClosedRange<Int>) -> WeekdayMask {
        var m = WeekdayMask()
        for i in range {
            m.insert(WeekdayMask(rawValue: 1 << i))
        }
        return m
    }

    private static func dayIndex(from token: String) -> Int? {
        let t = token.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return nil }
        if t.hasPrefix("mo") { return 0 }
        if t.hasPrefix("di") { return 1 }
        if t.hasPrefix("mi") { return 2 }
        if t.hasPrefix("do") { return 3 }
        if t.hasPrefix("fr") { return 4 }
        if t.hasPrefix("sa") { return 5 }
        if t.hasPrefix("so") { return 6 }
        return nil
    }

    private static func clockTimeOnSameDay(clock: String, reference: Date, calendar: Calendar) -> Date? {
        for pattern in ["HH:mm:ss", "HH:mm"] {
            let df = DateFormatter()
            df.calendar = calendar
            df.timeZone = calendar.timeZone
            df.locale = Locale(identifier: "en_GB_POSIX")
            df.dateFormat = pattern
            guard let parsed = df.date(from: clock.trimmingCharacters(in: .whitespaces)) else { continue }
            let hms = calendar.dateComponents([.hour, .minute, .second], from: parsed)
            var base = calendar.dateComponents([.year, .month, .day], from: reference)
            base.hour = hms.hour
            base.minute = hms.minute
            base.second = hms.second
            return calendar.date(from: base)
        }
        return nil
    }

    private static func timeString(date: Date, timeZone: TimeZone, locale: Locale) -> String {
        let df = DateFormatter()
        df.timeZone = timeZone
        df.locale = locale
        df.dateStyle = .none
        df.timeStyle = .short
        return df.string(from: date)
    }

    private static func shortTimeString(clock: String, timeZone: TimeZone, locale: Locale) -> String? {
        let cal = calendar(timeZone: timeZone)
        let ref = Date()
        guard let d = clockTimeOnSameDay(clock: clock, reference: ref, calendar: cal) else { return nil }
        return timeString(date: d, timeZone: timeZone, locale: locale)
    }
}

struct StationOpeningHoursPopoverModel: Sendable, Equatable {
    let primaryLine: String?
    let scheduleLines: [String]
    let overrideLines: [String]?
}
