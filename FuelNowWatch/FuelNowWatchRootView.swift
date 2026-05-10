import SwiftUI

/// Watch-Root: zeigt naechste Tankstelle, guenstigste Tankstelle und (sofern befuellt) eine
/// kurze „günstig im 5-km-Umkreis“-Liste. Daten kommen per WatchConnectivity vom iPhone —
/// Aktualisierung startet dort einen Tankerkönig-Fetch; die Watch hat keinen eigenen API-Key.
struct FuelNowWatchRootView: View {
    @Environment(FuelNowWatchSnapshotProvider.self) private var provider

    var body: some View {
        NavigationStack {
            List {
                if provider.isRefreshingFromPhone {
                    Section {
                        ProgressView("Aktualisiere …")
                    }
                }
                if let hint = provider.refreshHint {
                    Section {
                        Text(hint)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                if let snapshot = provider.snapshot {
                    if let nearest = snapshot.nearest {
                        Section("Nächste") {
                            FuelNowWatchStationRow(station: nearest)
                        }
                    }
                    if let cheapest = snapshot.cheapest, cheapest.stationID != snapshot.nearest?.stationID {
                        Section("Günstigste") {
                            FuelNowWatchStationRow(station: cheapest)
                        }
                    }
                    if let cheapestNearby = snapshot.cheapestNearby, !cheapestNearby.isEmpty {
                        Section("Günstigste im 5-km-Umkreis") {
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await provider.requestRefreshFromPhone() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(provider.isRefreshingFromPhone)
                    .accessibilityLabel("Aktualisieren")
                }
            }
            .refreshable {
                await provider.requestRefreshFromPhone()
                await provider.load()
            }
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
