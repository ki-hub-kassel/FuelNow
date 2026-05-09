import CoreLocation
import SwiftUI

private enum StationDetailFetchPhase: Equatable {
    case idle
    case loading
    case loaded
    case failed
}

/// Detail-Sheet für eine Tankstelle: Marke in der Navigationsleiste, Status/Entfernung, Spritpreise und Apple-Maps-Navigation (Autoroute).
struct StationDetailView: View {
    let station: Station
    let preferredFuel: FuelType

    @Environment(\.dismiss) private var dismiss
    @Environment(\.stationDetailFetcher) private var stationDetailFetcher
    @Environment(LocationService.self) private var locationService
    @Environment(FavoritesStore.self) private var favoritesStore

    @State private var detailStation: Station?
    @State private var detailFetchPhase: StationDetailFetchPhase = .idle
    @State private var showOpeningHoursPopover = false

    /// Tankerkönig-`list.php` liefert kein `openingTimes`; nach `detail.php` ersetzen wir die Anzeige-Daten.
    private var resolvedStation: Station {
        detailStation ?? station
    }

    /// Marke in der Toolbar; wenn leer, voller Stationsname.
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

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                statusAndDistanceRow
                    .padding(.horizontal, TRSpacing.m)
                    .padding(.top, TRSpacing.s)
                    .padding(.bottom, TRSpacing.m)

                ScrollView {
                    VStack(alignment: .leading, spacing: TRSpacing.m) {
                        TRSectionCard(title: "Preise") {
                            VStack(alignment: .leading, spacing: TRSpacing.s) {
                                ForEach(FuelType.allCases) { fuel in
                                    priceRow(fuel: fuel, isPreferred: fuel == preferredFuel)
                                }
                            }
                        }
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
                    favoriteToggleButton
                }
                ToolbarItem(placement: .principal) {
                    Text(navigationBarBrandTitle)
                        .font(.headline)
                        .foregroundStyle(TRColors.labelPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .accessibilityLabel(resolvedStation.name)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(TRColors.labelSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Schließen")
                    .accessibilityHint("Schließt die Tankstellendetails.")
                }
            }
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

    private var isFavorited: Bool {
        favoritesStore.contains(stationID: resolvedStation.id)
    }

    private var favoriteToggleButton: some View {
        Button {
            Haptics.tap(.light)
            favoritesStore.toggle(resolvedStation)
        } label: {
            Image(systemName: isFavorited ? "heart.fill" : "heart")
                .font(.title3.weight(.medium))
                .foregroundStyle(isFavorited ? TRColors.danger : TRColors.labelSecondary)
                .symbolRenderingMode(.hierarchical)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFavorited ? "Favorit entfernen" : "Als Favorit speichern")
        .accessibilityHint(
            isFavorited
                ? "Entfernt diese Tankstelle aus deinen Favoriten."
                : "Speichert diese Tankstelle in deinen Favoriten und meldet Preissturz-Pushes."
        )
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

    /// Status und Entfernung unter der Toolbar (fix, ohne Scrollen).
    private var statusAndDistanceRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: TRSpacing.m) {
            HStack(alignment: .top, spacing: TRSpacing.s) {
                Circle()
                    .fill(resolvedStation.isOpen ? TRColors.success : TRColors.danger)
                    .frame(width: 12, height: 12)
                    .overlay {
                        Circle()
                            .strokeBorder(TRColors.labelPrimary.opacity(0.12), lineWidth: 1)
                    }
                    .padding(.top, 3)
                    .accessibilityHidden(true)

                HStack(alignment: .firstTextBaseline, spacing: TRSpacing.xs) {
                    VStack(alignment: .leading, spacing: TRSpacing.xxs) {
                        Text(
                            resolvedStation.isOpen
                                ? String(localized: "station.status.open")
                                : String(localized: "station.status.closed")
                        )
                        .font(TRTypography.callout())
                        .fontWeight(.semibold)
                        .foregroundStyle(resolvedStation.isOpen ? TRColors.success : TRColors.danger)

                        if let openHoursSubtitle {
                            Text(openHoursSubtitle)
                                .font(TRTypography.caption())
                                .foregroundStyle(TRColors.labelSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(statusAccessibilityLabel)

                    if showsOpeningHoursInfo {
                        Button {
                            Haptics.tap(.light)
                            showOpeningHoursPopover = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(TRTypography.callout().weight(.medium))
                                .foregroundStyle(TRColors.accentText.opacity(0.92))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(String(localized: "station.openingHours.info.accessibilityLabel"))
                        .accessibilityHint(String(localized: "station.openingHours.info.accessibilityHint"))
                    }
                }
            }

            Spacer(minLength: TRSpacing.s)

            // TAN-94: kleines `location.fill`-Symbol vor dem Wert; das frühere
            // „ca."-Präfix entfällt, weil das Symbol die Schätzung visuell trägt.
            HStack(spacing: TRSpacing.xxs) {
                Image(systemName: "location.fill")
                    .font(TRTypography.callout())
                    .foregroundStyle(TRColors.labelSecondary)
                    .accessibilityHidden(true)
                Text(distanceLabel)
                    .font(TRTypography.callout())
                    .foregroundStyle(TRColors.labelSecondary)
                    .multilineTextAlignment(.trailing)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Entfernung, \(distanceLabel)")
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

    private var distanceLabel: String {
        let dynamicDistanceKm = locationService.currentLocation.map { userLocation in
            let stationLocation = CLLocation(latitude: resolvedStation.latitude, longitude: resolvedStation.longitude)
            return userLocation.distance(from: stationLocation) / 1000
        }
        return StationDisplayFormatting.distanceString(
            kilometers: dynamicDistanceKm ?? resolvedStation.distanceKilometers
        )
    }

    private func priceRow(fuel: FuelType, isPreferred: Bool) -> some View {
        let euros = resolvedStation.price(for: fuel)
        // TAN-93: Hauptsorte deutlich prominent (größer, accentText), Vergleichssorten
        // sekundär (Standardgröße, labelSecondary). Schriftgröße + Farbe sind als
        // visueller Marker ausreichend; das frühere Häkchen-Badge wäre redundant
        // und wurde entfernt. Bei fehlendem Preis (nil) immer secondary, weil ein
        // „—"-Platzhalter nicht „leuchten" soll.
        let priceProminence: FuelPriceLabel.Prominence = isPreferred ? .display : .standard
        let priceForeground: Color =
            (euros == nil)
            ? TRColors.labelSecondary
            : (isPreferred ? TRColors.accentText : TRColors.labelSecondary)
        let nameFont: Font = isPreferred ? TRTypography.headline() : TRTypography.body()
        let nameColor: Color = isPreferred ? TRColors.labelPrimary : TRColors.labelSecondary

        return HStack(alignment: .firstTextBaseline) {
            Text(fuel.displayName)
                .font(nameFont)
                .foregroundStyle(nameColor)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            Spacer(minLength: TRSpacing.s)
            FuelPriceLabel(
                euros: euros,
                prominence: priceProminence,
                foreground: priceForeground
            )
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(priceRowAccessibilityLabel(fuel: fuel, isPreferred: isPreferred))
    }

    private func priceRowAccessibilityLabel(fuel: FuelType, isPreferred: Bool) -> String {
        let pricePart = FuelPriceFormatting.voiceOverString(euros: resolvedStation.price(for: fuel))
        return StationVoiceOverCopy.detailPriceRow(
            fuelDisplayName: fuel.displayName,
            formattedPriceOrUnavailable: pricePart,
            isPreferred: isPreferred
        )
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

// MARK: - Öffnungszeiten-Popover

private struct StationOpeningHoursPopoverView: View {
    var phase: StationDetailFetchPhase
    var enrichedStation: Station?
    var listStation: Station

    private var displayStation: Station {
        enrichedStation ?? listStation
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TRSpacing.m) {
            Text(String(localized: "station.openingHours.title"))
                .font(TRTypography.title2())
                .fixedSize(horizontal: false, vertical: true)

            switch phase {
            case .loading:
                ProgressView()
                Text(String(localized: "station.openingHours.loading"))
                    .font(TRTypography.subheadline())
                    .foregroundStyle(TRColors.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            case .failed:
                Text(String(localized: "station.openingHours.loadFailed"))
                    .font(TRTypography.subheadline())
                    .foregroundStyle(TRColors.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            case .idle, .loaded:
                loadedBody
            }
        }
        .padding(TRSpacing.m)
        .frame(minWidth: 288, maxWidth: 340, alignment: .leading)
    }

    @ViewBuilder
    private var loadedBody: some View {
        let model = StationOpeningHoursPresenter.popoverModel(station: displayStation)

        if let primary = model.primaryLine {
            Text(primary)
                .font(TRTypography.bodyBold())
                .foregroundStyle(TRColors.labelPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }

        if model.scheduleLines.isEmpty {
            Text(String(localized: "station.openingHours.noSchedule"))
                .font(TRTypography.subheadline())
                .foregroundStyle(TRColors.labelSecondary)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(String(localized: "station.openingHours.section.schedule"))
                .font(TRTypography.caption())
                .foregroundStyle(TRColors.labelSecondary)
                .textCase(.uppercase)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: TRSpacing.xs) {
                ForEach(Array(model.scheduleLines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(TRTypography.subheadline())
                        .foregroundStyle(TRColors.labelPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }

        if let overrides = model.overrideLines, !overrides.isEmpty {
            Text(String(localized: "station.openingHours.section.overrides"))
                .font(TRTypography.caption())
                .foregroundStyle(TRColors.labelSecondary)
                .textCase(.uppercase)
                .padding(.top, TRSpacing.xs)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: TRSpacing.xs) {
                ForEach(Array(overrides.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(TRTypography.caption())
                        .foregroundStyle(TRColors.labelPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }

        Text(String(localized: "station.openingHours.footer.source"))
            .font(TRTypography.captionSmall())
            .foregroundStyle(TRColors.labelTertiary)
            .padding(.top, TRSpacing.s)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Previews

private struct StationDetailPreviewEnvelope: Decodable {
    let stations: [Station]
}

#Preview("Station detail · Standard") {
    StationDetailPreviewHost(dynamicType: .medium)
}

#Preview("Station detail · Accessibility 3") {
    StationDetailPreviewHost(dynamicType: .accessibility3)
}

#Preview("Station detail · Accessibility XXL") {
    StationDetailPreviewHost(dynamicType: .accessibility5)
}

@MainActor
private struct StationDetailPreviewHost: View {
    var dynamicType: DynamicTypeSize

    var body: some View {
        let json = Data(
            """
            {"stations":[{"id":"474e5046-deaf-4f9b-9a32-9797b778f047","name":"TOTAL BERLIN",
            "brand":"TOTAL","street":"MARGARETE-SOMMER-STR.","place":"BERLIN","lat":52.53083,
            "lng":13.440946,"dist":1.12,"diesel":1.109,"e5":1.339,"e10":1.319,"isOpen":true,
            "houseNumber":"2","postCode":10407}]}
            """.utf8
        )
        let station = (try? JSONDecoder().decode(StationDetailPreviewEnvelope.self, from: json).stations.first)!
        let detailFetcher = StationDetailPreviewDetailFetcher(previewStationID: station.id)
        return NavigationStack {
            StationDetailView(station: station, preferredFuel: .e10)
        }
        .environment(\.dynamicTypeSize, dynamicType)
        .environment(\.stationDetailFetcher, detailFetcher)
    }
}

private struct StationDetailPreviewDetailFetcher: StationDetailFetching {
    let previewStationID: UUID

    func fetchStationDetail(id: UUID) async throws -> Station {
        guard id == previewStationID else {
            struct PreviewMismatch: Error {}
            throw PreviewMismatch()
        }
        let detailJSON = Data(
            """
            {"id":"474e5046-deaf-4f9b-9a32-9797b778f047","name":"TOTAL BERLIN",
            "brand":"TOTAL","street":"MARGARETE-SOMMER-STR.","place":"BERLIN","lat":52.53083,
            "lng":13.440946,"dist":1.12,"diesel":1.109,"e5":1.339,"e10":1.319,"isOpen":true,
            "houseNumber":"2","postCode":10407,"wholeDay":false,
            "openingTimes":[
              {"text":"Mo-Fr","start":"06:00:00","end":"22:30:00"},
              {"text":"Samstag","start":"07:00:00","end":"22:00:00"}
            ]}
            """.utf8
        )
        return try JSONDecoder().decode(Station.self, from: detailJSON)
    }
}
