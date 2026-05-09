import SwiftUI
import WidgetKit

/// Watch-Komplikationen (`accessoryCircular` und `accessoryCorner`) — Roadmap Phase 6.
///
/// **Status:** Skelett. Wird wirksam, sobald in Xcode ein **Widget Extension Target** unter
/// dem Watch-Companion (z. B. `FuelNowWatchComplications`) angelegt ist und dieser Code
/// dort kompiliert wird. Vorher kann die Datei kompiliert werden, sobald sie im
/// `FuelNowWatch`-Target Mitglied ist; das Modul rendert dann nur in der Watch-App, nicht
/// auf dem Ziffernblatt.

struct FuelNowComplicationEntry: TimelineEntry {
    let date: Date
    let snapshot: WatchWidgetSnapshot?
}

struct FuelNowComplicationProvider: TimelineProvider {
    typealias Entry = FuelNowComplicationEntry

    private let provider: FuelNowWatchSnapshotProvider

    init() {
        // Provider haelt sich seine UserDefaults selber; in der Komplikation nutzen wir
        // ihn synchron ueber die App-Group.
        self.provider = FuelNowWatchSnapshotProvider()
    }

    func placeholder(in context: Context) -> FuelNowComplicationEntry {
        FuelNowComplicationEntry(
            date: .now,
            snapshot: WatchWidgetSnapshot(
                generatedAt: .now,
                nearest: WatchStationSnapshot(
                    stationID: UUID(),
                    brandTitle: "FuelNow Mitte",
                    stationName: "FuelNow Mitte",
                    pumpPriceText: "1,58⁹",
                    distanceText: "0,6 km",
                    isOpen: true
                ),
                cheapest: nil,
                cheapestNearby: nil
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (FuelNowComplicationEntry) -> Void) {
        Task { @MainActor in
            await provider.load()
            completion(FuelNowComplicationEntry(date: .now, snapshot: provider.snapshot))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FuelNowComplicationEntry>) -> Void) {
        Task { @MainActor in
            await provider.load()
            let entry = FuelNowComplicationEntry(date: .now, snapshot: provider.snapshot)
            let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now.addingTimeInterval(1_800)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }
}

struct FuelNowComplicationEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: FuelNowComplicationEntry

    private var station: WatchStationSnapshot? {
        entry.snapshot?.nearest ?? entry.snapshot?.cheapest
    }

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                Circle().stroke(.thinMaterial, lineWidth: 1)
                if let station {
                    VStack(spacing: 0) {
                        Text(station.pumpPriceText)
                            .font(.system(size: 11, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Text("E10")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Image(systemName: "fuelpump.fill")
                }
            }
        case .accessoryCorner:
            if let station {
                Text(station.pumpPriceText)
                    .widgetCurvesContent()
                    .widgetLabel {
                        Text(station.distanceText)
                    }
            } else {
                Image(systemName: "fuelpump.fill")
            }
        case .accessoryInline:
            if let station {
                Text("FuelNow \(station.pumpPriceText) · \(station.distanceText)")
            } else {
                Text("FuelNow")
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                if let station {
                    Text(station.brandTitle).font(.headline).lineLimit(1)
                    Text("\(station.pumpPriceText) · \(station.distanceText)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("FuelNow")
                        .font(.headline)
                }
            }
        default:
            EmptyView()
        }
    }
}

struct FuelNowComplicationWidget: Widget {
    private let kind = "com.vibecoding.fuelnow.watch.complication.nearest"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FuelNowComplicationProvider()) { entry in
            FuelNowComplicationEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("FuelNow")
        .description("Nächste Tankstelle inklusive Pump-Style-Preis.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryInline, .accessoryRectangular])
    }
}

@main
struct FuelNowWatchComplicationsBundle: WidgetBundle {
    var body: some Widget {
        FuelNowComplicationWidget()
    }
}
