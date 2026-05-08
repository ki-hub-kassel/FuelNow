import AppIntents
import SwiftUI
import WidgetKit

enum FuelNowWidgetMode: String, AppEnum, CaseDisplayRepresentable {
    case nearest
    case cheapest

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Widget-Modus")
    }

    static var caseDisplayRepresentations: [FuelNowWidgetMode: DisplayRepresentation] {
        [
            .nearest: DisplayRepresentation(title: "Nächste"),
            .cheapest: DisplayRepresentation(title: "Günstigste"),
        ]
    }
}

struct FuelNowWidgetConfigurationIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "FuelNow Widget"
    static let description = IntentDescription("Zeigt die nächste oder günstigste Tankstelle aus den letzten App-Daten.")

    @Parameter(title: "Modus", default: .nearest)
    var mode: FuelNowWidgetMode
}

struct FuelNowWidgetRefreshIntent: AppIntent {
    static let title: LocalizedStringResource = "Widget aktualisieren"
    static var openAppWhenRun: Bool { false }

    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct FuelNowWidgetEntry: TimelineEntry {
    let date: Date
    let mode: FuelNowWidgetMode
    let snapshot: WidgetDataSnapshot?
}

struct FuelNowWidgetProvider: AppIntentTimelineProvider {
    typealias Intent = FuelNowWidgetConfigurationIntent
    typealias Entry = FuelNowWidgetEntry

    private let store = WidgetSnapshotStore()

    func placeholder(in context: Context) -> FuelNowWidgetEntry {
        FuelNowWidgetEntry(
            date: .now,
            mode: .nearest,
            snapshot: WidgetDataSnapshot(
                generatedAt: .now,
                loadState: .ready,
                preferredFuelRawValue: "e10",
                stationCount: 2,
                nearest: placeholderStation(name: "FuelNow Mitte", price: "1,58⁹", distance: "0,6 km", open: true),
                cheapest: placeholderStation(name: "FuelNow Süd", price: "1,54⁹", distance: "1,8 km", open: true)
            )
        )
    }

    func snapshot(for configuration: FuelNowWidgetConfigurationIntent, in context: Context) async -> FuelNowWidgetEntry {
        FuelNowWidgetEntry(date: .now, mode: configuration.mode, snapshot: store.read())
    }

    func timeline(for configuration: FuelNowWidgetConfigurationIntent, in context: Context) async -> Timeline<FuelNowWidgetEntry> {
        let entry = FuelNowWidgetEntry(date: .now, mode: configuration.mode, snapshot: store.read())
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now.addingTimeInterval(1_800)
        return Timeline(entries: [entry], policy: .after(refreshDate))
    }

    private func placeholderStation(name: String, price: String, distance: String, open: Bool) -> WidgetStationSnapshot {
        WidgetStationSnapshot(
            stationID: UUID(),
            brandTitle: name,
            stationName: name,
            address: "Musterstraße 1, 12345 Stadt",
            statusText: open ? "Geöffnet" : "Geschlossen",
            isOpen: open,
            distanceText: distance,
            distanceKilometers: 0.6,
            fuelTypeDisplayName: "Super E10",
            pumpPriceText: price,
            voicePriceText: "1 Euro 58,9 Cent",
            openInAppURL: "fuelnow://map",
            mapsDirectionsURL: "https://maps.apple.com/"
        )
    }
}

struct FuelNowWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family

    let entry: FuelNowWidgetEntry

    private var station: WidgetStationSnapshot? {
        guard let snapshot = entry.snapshot else { return nil }
        switch entry.mode {
        case .nearest:
            return snapshot.nearest ?? snapshot.cheapest
        case .cheapest:
            return snapshot.cheapest ?? snapshot.nearest
        }
    }

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        case .accessoryInline:
            inlineView
        case .accessoryRectangular:
            rectangularView
        default:
            smallView
        }
    }

    private var modeTitle: String {
        switch entry.mode {
        case .nearest:
            return "Nächste Tankstelle"
        case .cheapest:
            return "Günstigste Tankstelle"
        }
    }

    private var smallView: some View {
        Group {
            if let station {
                VStack(alignment: .leading, spacing: 6) {
                    Text(modeTitle).font(.caption2).foregroundStyle(.secondary)
                    Text(station.brandTitle).font(.headline).lineLimit(1)
                    Text(station.pumpPriceText).font(.title2.bold()).lineLimit(1)
                    HStack(spacing: 6) {
                        Circle()
                            .fill(station.isOpen ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(station.distanceText).font(.caption)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .widgetURL(URL(string: station.openInAppURL))
            } else {
                fallbackView
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var mediumView: some View {
        Group {
            if let station {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(modeTitle).font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Text(station.statusText).font(.caption)
                    }
                    Text(station.brandTitle).font(.headline).lineLimit(1)
                    Text(station.address).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                    HStack(alignment: .lastTextBaseline) {
                        Text(station.pumpPriceText).font(.title.bold()).lineLimit(1)
                        Text(station.fuelTypeDisplayName).font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Text(station.distanceText).font(.subheadline)
                    }
                    HStack(spacing: 8) {
                        if let openURL = URL(string: station.openInAppURL) {
                            Link(destination: openURL) {
                                Label("In FuelNow", systemImage: "fuelpump.fill")
                            }
                            .buttonStyle(.bordered)
                        }
                        if let mapsURL = URL(string: station.mapsDirectionsURL) {
                            Link(destination: mapsURL) {
                                Label("Navigation", systemImage: "location.north.line.fill")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        Button(intent: FuelNowWidgetRefreshIntent()) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                fallbackView
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var inlineView: some View {
        Group {
            if let station {
                Text("\(station.brandTitle) \(station.pumpPriceText) · \(station.distanceText)")
            } else {
                Text("FuelNow · App öffnen")
            }
        }
    }

    private var rectangularView: some View {
        Group {
            if let station {
                VStack(alignment: .leading, spacing: 4) {
                    Text(modeTitle).font(.caption2).foregroundStyle(.secondary)
                    Text(station.brandTitle).font(.headline).lineLimit(1)
                    HStack {
                        Text(station.pumpPriceText).font(.headline)
                        Spacer()
                        Text(station.distanceText).font(.caption)
                    }
                }
                .widgetURL(URL(string: station.openInAppURL))
            } else {
                Text("FuelNow öffnen, um Daten zu laden.")
            }
        }
    }

    private var fallbackView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FuelNow").font(.headline)
            Text("App öffnen, damit das Widget aktuelle Tankstellen laden kann.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(URL(string: "fuelnow://map"))
    }
}

struct FuelNowWidget: Widget {
    private let kind = "com.vibecoding.fuelnow.widget.stations"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: FuelNowWidgetConfigurationIntent.self, provider: FuelNowWidgetProvider()) { entry in
            FuelNowWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("FuelNow")
        .description("Zeigt die nächste oder günstigste Tankstelle aus den zuletzt geladenen App-Daten.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryRectangular])
    }
}

@main
struct FuelNowWidgetsBundle: WidgetBundle {
    var body: some Widget {
        FuelNowWidget()
    }
}
