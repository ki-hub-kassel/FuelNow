import SwiftUI

/// Watch-Root: zeigt naechste Tankstelle, guenstigste Tankstelle und (sofern befuellt) eine
/// kurze "guenstig im 5-km-Umkreis"-Liste. Datenpfad: App-Group-Snapshot vom iPhone, kein
/// eigener Tankerkoenig-Fetch (Watch hat keinen API-Key, wuerde sonst den Free-Tier-Limit
/// ueberlasten).
struct FuelNowWatchRootView: View {
    @Environment(FuelNowWatchSnapshotProvider.self) private var provider

    var body: some View {
        NavigationStack {
            List {
                if let snapshot = provider.snapshot {
                    if let nearest = snapshot.nearest {
                        Section("Naechste") {
                            FuelNowWatchStationRow(station: nearest)
                        }
                    }
                    if let cheapest = snapshot.cheapest, cheapest.stationID != snapshot.nearest?.stationID {
                        Section("Guenstigste") {
                            FuelNowWatchStationRow(station: cheapest)
                        }
                    }
                    if let cheapestNearby = snapshot.cheapestNearby, !cheapestNearby.isEmpty {
                        Section("Guenstig im 5-km-Umkreis") {
                            ForEach(cheapestNearby) { station in
                                FuelNowWatchStationRow(station: station)
                            }
                        }
                    }
                    Section {
                        Text("Aktualisiert vom iPhone: \(snapshot.generatedAt.formatted(date: .omitted, time: .shortened))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } else if let error = provider.lastError {
                    Section {
                        Text("Keine Daten").font(.headline)
                        Text(error).font(.caption2).foregroundStyle(.secondary)
                    }
                } else {
                    ProgressView("Lade …")
                }
            }
            .navigationTitle("FuelNow")
            .refreshable { await provider.load() }
        }
    }
}

struct FuelNowWatchStationRow: View {
    let station: WatchStationSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(station.brandTitle)
                .font(.headline)
                .lineLimit(1)
            HStack(spacing: 6) {
                Circle()
                    .fill(station.isOpen ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(station.pumpPriceText)
                    .font(.subheadline)
                    .bold()
                Text("·").font(.caption2).foregroundStyle(.secondary)
                Text(station.distanceText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(station.stationName), \(station.pumpPriceText), \(station.distanceText)")
    }
}
