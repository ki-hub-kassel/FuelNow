import SwiftUI

/// Detail-Sheet für eine Tankstelle: Marke in der Navigationsleiste, Status/Entfernung, Spritpreise und Apple-Maps-Navigation (Autoroute).
struct StationDetailView: View {
    let station: Station
    let preferredFuel: FuelType

    @Environment(\.dismiss) private var dismiss
    @Environment(\.stationDetailFetcher) private var stationDetailFetcher
    @Environment(LocationService.self) private var locationService
    @Environment(FavoritesStore.self) private var favoritesStore
    @Environment(EntitlementManager.self) private var entitlementManager

    @State private var detailStation: Station?
    @State private var detailFetchPhase: StationDetailFetchPhase = .idle
    @State private var showOpeningHoursPopover = false
    @State private var showPlusUpgradeSheet = false

    private var resolvedStation: Station {
        detailStation ?? station
    }

    private var navigationBarBrandTitle: String {
        let trimmed = resolvedStation.brand.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? resolvedStation.name : trimmed
    }

    private var openHoursSubtitle: String? {
        StationOpeningHoursPresenter.openStatusSubtitle(station: resolvedStation)
    }

    private var showsOpeningHoursInfo: Bool {
        stationDetailFetcher != nil && resolvedStation.isOpen
    }

    private var openingHoursPopoverPhase: StationDetailFetchPhase {
        guard stationDetailFetcher != nil else { return .idle }
        if detailFetchPhase == .idle { return .loading }
        return detailFetchPhase
    }

    private var statusAccessibilityLabel: String {
        let status = resolvedStation.isOpen
            ? String(localized: "station.status.open")
            : String(localized: "station.status.closed")
        if let sub = openHoursSubtitle {
            return "\(status), \(sub)"
        }
        return status
    }

    private var isFavorited: Bool {
        favoritesStore.contains(stationID: resolvedStation.id)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                StationDetailStatusDistanceRow(
                    resolvedStation: resolvedStation,
                    openHoursSubtitle: openHoursSubtitle,
                    showsOpeningHoursInfo: showsOpeningHoursInfo,
                    statusAccessibilityLabel: statusAccessibilityLabel,
                    showOpeningHoursPopover: $showOpeningHoursPopover
                )
                .padding(.horizontal, TRSpacing.m)
                .padding(.top, TRSpacing.s)
                .padding(.bottom, TRSpacing.m)

                ScrollView {
                    VStack(alignment: .leading, spacing: TRSpacing.m) {
                        StationDetailPricesCard(
                            resolvedStation: resolvedStation,
                            preferredFuel: preferredFuel
                        )
                    }
                    .padding(.horizontal, TRSpacing.m)
                    .padding(.bottom, TRSpacing.m)
                }

                appleMapsNavigationButton
                    .padding(.horizontal, TRSpacing.m)
                    .padding(.top, TRSpacing.s)
                    .padding(.bottom, TRSpacing.m)
            }
            .navigationBarTitleDisplayMode(.inline)
            .task(id: station.id) {
                await refreshStationDetail()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    StationDetailFavoriteToolbar(
                        resolvedStation: resolvedStation,
                        isFavorited: isFavorited,
                        isPlusSubscriber: entitlementManager.isPlusSubscriber,
                        showPlusUpgradeSheet: $showPlusUpgradeSheet
                    )
                }
                ToolbarItem(placement: .principal) {
                    Text(navigationBarBrandTitle)
                        .font(.headline)
                        .foregroundStyle(TRColors.labelPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .accessibilityLabel(resolvedStation.name)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(TRColors.labelSecondary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Schließen")
                    .accessibilityHint("Schließt die Tankstellendetails.")
                }
            }
        }
        .sheet(isPresented: $showPlusUpgradeSheet) {
            PlusUpgradeView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .popover(isPresented: $showOpeningHoursPopover) {
            StationOpeningHoursPopoverView(
                phase: openingHoursPopoverPhase,
                enrichedStation: detailStation,
                listStation: station
            )
            .presentationCompactAdaptation(.popover)
        }
    }

    private var appleMapsNavigationButton: some View {
        Button(action: startAppleMapsDrivingNavigation) {
            Label("Navigation in Apple Maps", systemImage: "location.north.line.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.trPrimaryGlass)
        .accessibilityLabel("Navigation in Apple Maps")
        .accessibilityHint("Startet die Autoroute von deinem Standort zur Tankstelle in Apple Maps.")
    }

    private func refreshStationDetail() async {
        guard let fetcher = stationDetailFetcher else {
            detailFetchPhase = .idle
            detailStation = nil
            return
        }
        detailFetchPhase = .loading
        detailStation = nil
        do {
            detailStation = try await fetcher.fetchStationDetail(id: station.id)
            detailFetchPhase = .loaded
        } catch {
            detailFetchPhase = .failed
            detailStation = nil
        }
    }

    private func startAppleMapsDrivingNavigation() {
        Haptics.tap(.medium)
        Task {
            await DrivingToStationActivityController.startActivity(
                station: resolvedStation,
                preferredFuel: preferredFuel,
                userLocation: locationService.currentLocation
            )
        }
        AppleMapsDrivingNavigation.openDrivingDirections(
            toLatitude: resolvedStation.latitude,
            longitude: resolvedStation.longitude,
            placeName: resolvedStation.name
        )
    }
}
