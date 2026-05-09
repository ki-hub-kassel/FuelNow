import ActivityKit
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
        .supportedFamilies([.systemSmall, .accessoryInline, .accessoryRectangular])
    }
}

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
    let entry: FuelNowCheapestNearbyEntry

    private var stations: [WidgetStationSnapshot] {
        entry.snapshot?.cheapestNearby ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Günstig im 5-km-Umkreis")
                .font(.caption2)
                .foregroundStyle(.secondary)
            if stations.isEmpty {
                Text("App öffnen — keine aktuellen Preise.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(Array(stations.prefix(2).enumerated()), id: \.offset) { _, station in
                    cheapestRow(station: station)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(URL(string: "fuelnow://map"))
    }

    private func cheapestRow(station: WidgetStationSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(station.brandTitle)
                .font(.subheadline.bold())
                .lineLimit(1)
            HStack(spacing: 6) {
                Text(station.pumpPriceText)
                    .font(.caption)
                    .bold()
                Text("·").font(.caption2).foregroundStyle(.secondary)
                Text(station.distanceText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct FuelNowCheapestNearbyWidget: Widget {
    private let kind = "com.vibecoding.fuelnow.widget.cheapest5km"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FuelNowCheapestNearbyProvider()) { entry in
            FuelNowCheapestNearbyEntryView(entry: entry)
        }
        .configurationDisplayName("Günstig 5 km")
        .description("Die zwei guenstigsten Tankstellen im 5-km-Umkreis um deinen Standort.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - DrivingToStationLiveActivity (Roadmap Phase 5)

struct DrivingToStationLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DrivingToStationActivityAttributes.self) { context in
            DrivingToStationLockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "fuelpump.fill")
                        .foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.distanceText)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.brandTitle)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text("\(context.attributes.fuelDisplayName) · \(context.attributes.pumpPriceText)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if let eta = context.state.etaText {
                        Text(eta)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
            } compactLeading: {
                Image(systemName: "fuelpump.fill")
                    .foregroundStyle(.white)
            } compactTrailing: {
                Text(context.state.distanceText)
                    .foregroundStyle(.white)
            } minimal: {
                Image(systemName: "fuelpump.fill")
                    .foregroundStyle(.white)
            }
            .keylineTint(.green)
        }
    }
}

private struct DrivingToStationLockScreenView: View {
    let context: ActivityViewContext<DrivingToStationActivityAttributes>

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "fuelpump.fill")
                .font(.title2)
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.brandTitle)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("\(context.attributes.fuelDisplayName) · \(context.attributes.pumpPriceText)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(context.state.distanceText)
                    .font(.headline)
                    .foregroundStyle(.white)
                if let eta = context.state.etaText {
                    Text(eta)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Fahrt zu \(context.attributes.stationName), \(context.state.distanceText)")
    }
}

@main
struct FuelNowWidgetsBundle: WidgetBundle {
    var body: some Widget {
        FuelNowWidget()
        FuelNowCheapestNearbyWidget()
        DrivingToStationLiveActivity()
    }
}
