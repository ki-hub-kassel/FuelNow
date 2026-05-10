import CoreLocation
import MapKit
import SwiftUI
import TipKit
import UIKit

private enum MapScreenDefaults {
    static let initialRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.52, longitude: 13.405),
        span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
    )
}

/// Abstand Kartenmitte → letztes Abrufzentrum, ab dem „In diesem Gebiet suchen“ erscheint (Meter).
private enum MapRegionSearchOffer {
    static let panThresholdMeters: CLLocationDistance = 800
}

/// Hauptkarte: Standort, Tankstellen-Pins und Verkabelung zu `LocationService` / `StationStore`.
struct MapScreen: View {
    @Environment(LocationService.self) private var locationService
    @Environment(StationStore.self) private var stationStore
    @Environment(NetworkMonitor.self) private var networkMonitor
    @Environment(MapDeepLinkStore.self) private var deepLinks
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage(AppSettings.UserDefaultsKey.preferredFuelType) private var preferredFuelRaw = FuelType.e10.rawValue

    /// Sichtbarer Ausschnitt für Grid-Clustering und „Gebiet suchen“. Nur bei **beendeter** Kamerabewegung aktualisiert — verhindert Flackern beim Schieben (`continuous` würde jedes Frame neu clustern).
    @State private var mapVisibleRegion = MapScreenDefaults.initialRegion

    @State private var cameraPosition: MapCameraPosition = .region(MapScreenDefaults.initialRegion)
    @State private var selectedStation: Station?
    @State private var showSettings = false
    @State private var didApplyInitialCamera = false
    /// Gesetzt bei `.failed`, geleert bei anderem `loadState` — steuert den Retry-Alert (TAN-22).
    @State private var presentedFetchErrorMessage: String?

    @State private var clusterTapTrigger: UInt = 0
    @State private var searchAreaTrigger: UInt = 0

    private var preferredFuel: FuelType {
        FuelType(rawValue: preferredFuelRaw) ?? .e10
    }

    private var isLocationAccessDenied: Bool {
        switch locationService.authorizationStatus {
        case .denied, .restricted:
            true
        default:
            false
        }
    }

    /// Erfolgreicher Fetch ohne Treffer — nicht bei verweigerter Location oder vor erstem Standort.
    private var showEmptyStationsState: Bool {
        guard !isLocationAccessDenied else { return false }
        guard locationService.currentLocation != nil else { return false }
        guard case .loaded = stationStore.loadState else { return false }
        return stationStore.stations.isEmpty
    }

    /// Nutzer hat die Karte vom letzten `list.php`-Zentrum weggeschoben — expliziter Abruf um die Kartenmitte.
    private var shouldOfferSearchInVisibleRegion: Bool {
        guard stationStore.loadState != .loading else { return false }
        guard let anchor = stationStore.lastFetchCenter else { return false }
        let mapLoc = CLLocation(latitude: mapVisibleRegion.center.latitude, longitude: mapVisibleRegion.center.longitude)
        let anchorLoc = CLLocation(latitude: anchor.latitude, longitude: anchor.longitude)
        return mapLoc.distance(from: anchorLoc) >= MapRegionSearchOffer.panThresholdMeters
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $cameraPosition) {
                ForEach(StationMapClustering.annotationItems(for: stationStore.stations, region: mapVisibleRegion)) { item in
                    Group {
                        switch item {
                        case .single(let station):
                            Annotation(station.name, coordinate: station.coordinate) {
                                Button {
                                    selectedStation = station
                                } label: {
                                    StationAnnotationView(station: station, preferredFuel: preferredFuel)
                                }
                                .buttonStyle(.plain)
                            }
                        case let .cluster(stations, coordinate):
                            Annotation("", coordinate: coordinate) {
                                Button {
                                    clusterTapTrigger &+= 1
                                    zoomIntoCluster(stations)
                                } label: {
                                    StationClusterAnnotationView(count: stations.count)
                                }
                                .buttonStyle(.plain)
                            }
                            .annotationTitles(.hidden)
                            .annotationSubtitles(.hidden)
                        }
                    }
                }
                // Explizit aus LocationService — zuverlässiger als UserAnnotation() bei gebundenem MapCamera & vielen Pins.
                if let userLocation = locationService.currentLocation {
                    Annotation("", coordinate: userLocation.coordinate) {
                        UserLocationMapMarker()
                    }
                    .annotationTitles(.hidden)
                    .annotationSubtitles(.hidden)
                }
            }
            .mapStyle(.standard)
            .onMapCameraChange(frequency: .onEnd) { context in
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    mapVisibleRegion = context.region
                }
            }
            .refreshable {
                await refreshStations()
            }

            VStack(spacing: TRSpacing.m) {
                if shouldOfferSearchInVisibleRegion {
                    TipView(MapSearchAreaTip(), arrowEdge: .bottom)
                        .padding(.bottom, TRSpacing.xxs)
                    Button {
                        searchAreaTrigger &+= 1
                        searchStationsForVisibleMapCenter()
                        Task {
                            await FuelNowTipEvents.didUseSearchThisArea.donate()
                        }
                    } label: {
                        Label(String(localized: "map.searchThisArea"), systemImage: "magnifyingglass")
                    }
                    .buttonStyle(TRSoftButtonStyle())
                    .labelStyle(.titleAndIcon)
                    .accessibilityHint(String(localized: "map.searchThisArea.hint"))
                    .frame(maxWidth: .infinity)
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                }

                HStack(alignment: .center, spacing: TRSpacing.s) {
                    Spacer()
                    LocateMeButton {
                        centerMapOnUser()
                    }
                    .disabled(locationService.currentLocation == nil)
                    .opacity(locationService.currentLocation == nil ? 0.45 : 1)
                }
                .padding(.horizontal, TRSpacing.m)
            }
            .padding(.bottom, TRSpacing.m)
        }
        .navigationTitle("FuelNow")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Einstellungen", systemImage: "gearshape.fill") {
                    showSettings = true
                }
                .accessibilityLabel("Einstellungen")
                .accessibilityHint("Öffnet Spritart, Erscheinungsbild und Datenquelle.")
            }
        }
        .sheet(item: $selectedStation) { station in
            StationDetailView(station: station, preferredFuel: preferredFuel)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .overlay(alignment: .top) {
            loadStateBanner
        }
        .overlay {
            if showEmptyStationsState {
                ContentUnavailableView {
                    Label("Keine Tankstellen im 25-km-Umkreis", systemImage: "fuelpump.slash")
                } description: {
                    Text("Versuche es an einem anderen Ort oder lade die Karte erneut.")
                } actions: {
                    Button("Erneut laden") {
                        Haptics.tap(.medium)
                        retryStationFetch()
                    }
                    .buttonStyle(TRPrimaryGlassButtonStyle())
                }
                .padding(TRSpacing.m)
                .accessibilityLabel("Keine Tankstellen im 25-km-Umkreis")
            }
        }
        .overlay {
            if isLocationAccessDenied {
                LocationDeniedCallout {
                    showSettings = true
                }
                .transition(.opacity)
            }
        }
        .overlay {
            if networkMonitor.shouldShowOfflineSplash {
                OfflineSplashView()
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .animation(reduceMotion ? nil : .default, value: isLocationAccessDenied)
        .animation(reduceMotion ? nil : .default, value: showEmptyStationsState)
        .animation(reduceMotion ? nil : .default, value: shouldOfferSearchInVisibleRegion)
        .animation(reduceMotion ? nil : TRMotion.overlayFade, value: networkMonitor.shouldShowOfflineSplash)
        .modifier(MapScreenHapticsModifier(
            selectedStationID: selectedStation?.id,
            clusterTrigger: clusterTapTrigger,
            searchAreaTrigger: searchAreaTrigger
        ))
        .alert(
            "Tankstellen konnten nicht geladen werden",
            isPresented: Binding(
                get: { presentedFetchErrorMessage != nil },
                set: { newValue in
                    if !newValue { presentedFetchErrorMessage = nil }
                }
            )
        ) {
            Button("Erneut versuchen") {
                Haptics.tap(.medium)
                presentedFetchErrorMessage = nil
                retryStationFetch()
            }
            Button("OK", role: .cancel) {
                presentedFetchErrorMessage = nil
            }
        } message: {
            Text(presentedFetchErrorMessage ?? "")
        }
        .task {
            locationService.start()
            applyPendingStationFocusFromDeepLink()
        }
        .onChange(of: deepLinks.pendingStationFocusID) { _, _ in
            applyPendingStationFocusFromDeepLink()
        }
        .onChange(of: deepLinks.pendingControlAction) { _, _ in
            applyPendingMapControlActionIfNeeded()
        }
        .onChange(of: stationStore.stations) { _, _ in
            applyPendingStationFocusFromDeepLink()
            applyPendingMapControlActionIfNeeded()
        }
        .onChange(of: stationStore.loadState) { _, newState in
            switch newState {
            case let .failed(message):
                let outcome = stationStore.lastError.map(NetworkMonitor.FetchOutcome.classify) ?? .otherFailure
                networkMonitor.recordFetchOutcome(outcome)
                // Bei Konnektivitäts-Fehlern übernimmt der Offline-Splash die Kommunikation —
                // der Error-Alert würde sonst doppelt erscheinen.
                presentedFetchErrorMessage = outcome == .connectivityFailure ? nil : message
                if outcome != .connectivityFailure {
                    Haptics.notify(.error)
                }
            case .loaded:
                networkMonitor.recordFetchOutcome(.success)
                presentedFetchErrorMessage = nil
            default:
                presentedFetchErrorMessage = nil
            }
        }
        .onChange(of: networkMonitor.shouldShowOfflineSplash) { oldValue, newValue in
            if !oldValue, newValue {
                Haptics.notify(.warning)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                locationService.refreshAuthorizationStatus()
            }
        }
        .onChange(of: networkMonitor.snapshot.reachability) { oldValue, newValue in
            // Offline → Online: einmaliger Refresh, damit der Splash nicht hängenbleibt.
            // `forceRefresh` umgeht den Debounce; ohne Standort versuchen wir es nicht.
            guard oldValue == .unsatisfied, newValue == .satisfied else { return }
            guard let location = locationService.currentLocation else { return }
            stationStore.forceRefresh(using: location, radiusKm: AppSettings.SearchRadius.apiMaxKm)
        }
        .onChange(of: locationService.currentLocation) { _, newValue in
            guard let location = newValue else { return }
            stationStore.handleLocationUpdate(location, radiusKm: AppSettings.SearchRadius.apiMaxKm)
            if !didApplyInitialCamera {
                didApplyInitialCamera = true
                let region = MKCoordinateRegion(
                    center: location.coordinate,
                    latitudinalMeters: 12_000,
                    longitudinalMeters: 12_000
                )
                mapVisibleRegion = region
                cameraPosition = .region(region)
            }
        }
    }

    /// Tankerkönig-Umkreissuche um die **aktuelle Kartenmitte** (25 km). Umgeht Debounce — nur nach Nutzeraktion.
    private func searchStationsForVisibleMapCenter() {
        let center = mapVisibleRegion.center
        let location = CLLocation(latitude: center.latitude, longitude: center.longitude)
        stationStore.forceRefresh(
            using: location,
            radiusKm: AppSettings.SearchRadius.apiMaxKm,
            trigger: .forcedMapRegion
        )
    }

    /// Cluster antippen: näher zoomen, bis sich Gitter-Zellen aufteilen (Einzelpins).
    private func zoomIntoCluster(_ stations: [Station]) {
        let region = StationMapClustering.regionToExpandCluster(stations, currentRegion: mapVisibleRegion)
        mapVisibleRegion = region
        if reduceMotion {
            cameraPosition = .region(region)
        } else {
            withAnimation(TRMotion.mapRegionEase) {
                cameraPosition = .region(region)
            }
        }
    }

    @ViewBuilder
    private var loadStateBanner: some View {
        switch stationStore.loadState {
        case .loading:
            ProgressView()
                .accessibilityLabel("Tankstellen werden geladen")
                .padding(TRSpacing.s)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.top, TRSpacing.s)
        default:
            EmptyView()
        }
    }

    /// Zentriert die Karte auf den aktuellen User-Standort.
    ///
    /// TAN-87: Apple-Maps-ähnliches Tracking-Niveau (~1,5 km Radius) statt vorheriger 8 km
    /// Übersicht — beim Tap auf den Locate-Button erwarten Nutzer:innen Straßen-/Block-Klarheit,
    /// nicht nur eine grobe Stadtansicht. Der Initial-Zoom (12 km direkt nach Permission-Grant
    /// in `onChange(of: locationService.currentLocation)`) bleibt absichtlich unberührt — das
    /// ist der „Hier ist deine Region"-Moment, nicht der Tracking-Use-Case.
    ///
    /// Animation respektiert `accessibilityReduceMotion`: ohne Bewegungs-Empfindlichkeit ein
    /// sanfter `.easeInOut`-Übergang, mit Reduce Motion ein sofortiger Snap (kein Zoom-Flow).
    private func centerMapOnUser() {
        guard let location = locationService.currentLocation else { return }
        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 1_500,
            longitudinalMeters: 1_500
        )
        mapVisibleRegion = region
        if reduceMotion {
            cameraPosition = .region(region)
        } else {
            withAnimation(TRMotion.mapLocateEase) {
                cameraPosition = .region(region)
            }
        }

        // Wenn zuletzt per „In diesem Gebiet suchen“ ein deutlich anderer Bereich geladen wurde,
        // holen wir beim Zurückkehren zum Nutzerstandort sofort passende Stationen nach.
        if shouldRefreshStationsAfterRecentering(on: location) {
            stationStore.forceRefresh(
                using: location,
                radiusKm: AppSettings.SearchRadius.apiMaxKm,
                trigger: .forcedUserLocation
            )
        }
    }

    private func shouldRefreshStationsAfterRecentering(on userLocation: CLLocation) -> Bool {
        guard stationStore.loadState != .loading else { return false }
        guard let lastFetchCenter = stationStore.lastFetchCenter else { return false }
        let lastCenterLocation = CLLocation(
            latitude: lastFetchCenter.latitude,
            longitude: lastFetchCenter.longitude
        )
        return userLocation.distance(from: lastCenterLocation) >= MapRegionSearchOffer.panThresholdMeters
    }

    private func refreshStations() async {
        guard let location = locationService.currentLocation else { return }
        stationStore.forceRefresh(using: location, radiusKm: AppSettings.SearchRadius.apiMaxKm)
        try? await Task.sleep(for: .milliseconds(400))
    }

    /// Erneuter Abruf nach Netzwerk-/API-Fehler (`StationStore.forceRefresh`).
    private func retryStationFetch() {
        guard let location = locationService.currentLocation else { return }
        stationStore.forceRefresh(using: location, radiusKm: AppSettings.SearchRadius.apiMaxKm)
    }

    /// Kurzbefehle / Custom-URL (`FuelNowDeepLink`): Sheet und Kamera, sobald die Station geladen ist.
    private func applyPendingStationFocusFromDeepLink() {
        guard let id = deepLinks.pendingStationFocusID else { return }
        guard let station = stationStore.stations.first(where: { $0.id == id }) else { return }
        selectedStation = station
        let region = MKCoordinateRegion(
            center: station.coordinate,
            latitudinalMeters: 3_500,
            longitudinalMeters: 3_500
        )
        mapVisibleRegion = region
        cameraPosition = .region(region)
        deepLinks.clearPendingStationFocus()
    }
}

// MARK: - Control Center / map?action (TAN-110)

extension MapScreen {
    private func applyPendingMapControlActionIfNeeded() {
        guard let action = deepLinks.pendingControlAction else { return }
        switch action {
        case .focusCheapest:
            guard !stationStore.stations.isEmpty else { return }
            guard let station = cheapestStationForPreferredFuel() else {
                deepLinks.clearPendingMapControl()
                return
            }
            selectedStation = station
            let region = MKCoordinateRegion(
                center: station.coordinate,
                latitudinalMeters: 3_500,
                longitudinalMeters: 3_500
            )
            mapVisibleRegion = region
            cameraPosition = .region(region)
            deepLinks.clearPendingMapControl()
        case .refreshVisibleRegion:
            searchStationsForVisibleMapCenter()
            deepLinks.clearPendingMapControl()
        }
    }

    private func cheapestStationForPreferredFuel() -> Station? {
        let priced: [(Station, Double)] = stationStore.stations.compactMap { station in
            guard let price = station.price(for: preferredFuel) else { return nil }
            return (station, price)
        }
        return priced.min(by: { $0.1 < $1.1 })?.0
    }
}

/// Bündelt Haptic-Trigger der Karte in einem View-Modifier — entlastet den `MapScreen.body`-
/// Type-Checker, der mit den vielen MapKit-Annotation-Generics ohne diese Auslagerung an die
/// "expression too complex"-Grenze stösst.
private struct MapScreenHapticsModifier: ViewModifier {
    let selectedStationID: UUID?
    let clusterTrigger: UInt
    let searchAreaTrigger: UInt

    func body(content: Content) -> some View {
        content
            .adaptiveSensoryFeedback(.selection, trigger: selectedStationID)
            .adaptiveSensoryFeedback(.impact(weight: .light), trigger: clusterTrigger)
            .adaptiveSensoryFeedback(.impact(weight: .medium), trigger: searchAreaTrigger)
    }
}

// MARK: - Previews

/// Blauer Punkt wie „Mein Standort“ in Apple Maps (SwiftUI-Annotation, nicht MapKit-`UserAnnotation`).
private struct UserLocationMapMarker: View {
    @ScaledMetric(relativeTo: .body) private var diameter: CGFloat = 18
    @Environment(\.colorScheme) private var colorScheme

    private var haloShadowOpacity: Double {
        colorScheme == .dark ? 0.45 : 0.22
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(uiColor: .systemBlue))
                .frame(width: diameter, height: diameter)
            Circle()
                .strokeBorder(Color.white, lineWidth: 3)
                .frame(width: diameter, height: diameter)
        }
        .shadow(color: .black.opacity(haloShadowOpacity), radius: colorScheme == .dark ? 3 : 2, y: 1)
        .accessibilityLabel("Mein Standort")
        .accessibilityHint("Zeigt deine ungefähre Position auf der Karte.")
    }
}
