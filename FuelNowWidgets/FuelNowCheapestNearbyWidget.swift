import SwiftUI
import WidgetKit

// MARK: - FuelNowCheapestNearbyWidget (Roadmap Phase 4)

struct FuelNowCheapestNearbyEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetDataSnapshot?
}

struct FuelNowCheapestNearbyProvider: TimelineProvider {
    typealias Entry = FuelNowCheapestNearbyEntry

    private let store = WidgetSnapshotStore()

    func placeholder(in context: Context) -> FuelNowCheapestNearbyEntry {
        FuelNowCheapestNearbyEntry(
            date: .now,
            snapshot: WidgetDataSnapshot(
                generatedAt: .now,
                loadState: .ready,
                preferredFuelRawValue: "e10",
                stationCount: 5,
                nearest: nil,
                cheapest: nil,
                cheapestNearby: [
                    placeholderStation(name: "FuelNow Süd", price: "1,54⁹", distance: "1,8 km"),
                    placeholderStation(name: "FuelNow Ost", price: "1,55⁹", distance: "2,3 km"),
                    placeholderStation(name: "FuelNow West", price: "1,56⁹", distance: "3,1 km"),
                    placeholderStation(name: "FuelNow Nord", price: "1,57⁹", distance: "4,2 km"),
                ]
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (FuelNowCheapestNearbyEntry) -> Void) {
        completion(FuelNowCheapestNearbyEntry(date: .now, snapshot: store.read()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FuelNowCheapestNearbyEntry>) -> Void) {
        let entry = FuelNowCheapestNearbyEntry(date: .now, snapshot: store.read())
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now.addingTimeInterval(1_800)
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }

    private func placeholderStation(name: String, price: String, distance: String) -> WidgetStationSnapshot {
        WidgetStationSnapshot(
            stationID: UUID(),
            brandTitle: name,
            stationName: name,
            address: "Musterstraße 1, 12345 Stadt",
            statusText: "Geöffnet",
            isOpen: true,
            distanceText: distance,
            distanceKilometers: 1.8,
            fuelTypeDisplayName: "Super E10",
            pumpPriceText: price,
            voicePriceText: "1 Euro 54,9 Cent",
            openInAppURL: "fuelnow://map",
            mapsDirectionsURL: "https://maps.apple.com/"
        )
    }
}

struct FuelNowCheapestNearbyEntryView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.showsWidgetContainerBackground) private var showsWidgetBackground

    let entry: FuelNowCheapestNearbyEntry

    private var stations: [WidgetStationSnapshot] {
        entry.snapshot?.cheapestNearby ?? []
    }

    private var maxStations: Int {
        family == .systemMedium ? 4 : 2
    }

    private var glanceSmall: Bool {
        FuelNowWidgetGlanceHelpers.isGlanceSmall(family: family, showsWidgetContainerBackground: showsWidgetBackground)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemMedium ? 8 : (glanceSmall ? 7 : 6)) {
            Text("Günstigste im 5-km-Umkreis")
                .font(glanceSmall ? .subheadline.weight(.medium) : .caption2)
                .foregroundStyle(glanceSmall ? Color.primary.opacity(0.9) : Color.secondary)
                .minimumScaleFactor(0.85)
                .lineLimit(2)
            if stations.isEmpty {
                Text("App öffnen — keine aktuellen Preise.")
                    .font(glanceSmall ? .subheadline : .caption)
                    .foregroundStyle(Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(Array(stations.prefix(maxStations).enumerated()), id: \.offset) { _, station in
                    if family == .systemMedium {
                        mediumRow(station: station)
                    } else {
                        compactRow(station: station)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) {
            Rectangle().fill(.fill.tertiary)
        }
        .widgetURL(URL(string: "fuelnow://map"))
    }

    private func compactRow(station: WidgetStationSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(station.brandTitle)
                .font(glanceSmall ? .title3.weight(.semibold) : .subheadline.bold())
                .foregroundStyle(Color.primary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            HStack(spacing: 6) {
                Text(station.pumpPriceText)
                    .font(glanceSmall ? .headline.bold() : .caption.bold())
                    .foregroundStyle(Color.primary)
                Text("·").font(.caption2).foregroundStyle(.secondary)
                Text(station.distanceText)
                    .font(glanceSmall ? .subheadline : .caption2)
                    .foregroundStyle(Color.primary.opacity(0.85))
            }
            .minimumScaleFactor(0.85)
        }
    }

    private func mediumRow(station: WidgetStationSnapshot) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(station.isOpen ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            Text(station.brandTitle)
                .font(.subheadline)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(station.pumpPriceText)
                .font(.subheadline.bold())
                .monospacedDigit()
                .lineLimit(1)
            Text(station.distanceText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .lineLimit(1)
                .frame(minWidth: 48, alignment: .trailing)
        }
    }
}

struct FuelNowCheapestNearbyWidget: Widget {
    private let kind = "com.vibecoding.fuelnow.widget.cheapest5km"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FuelNowCheapestNearbyProvider()) { entry in
            FuelNowCheapestNearbyEntryView(entry: entry)
        }
        .configurationDisplayName("Günstigste im 5-km-Umkreis")
        .description("Die günstigsten Tankstellen im 5-km-Umkreis um deinen Standort.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
