#if canImport(CarPlay)
import CarPlay
import Foundation
import Observation
import UIKit

/// CarPlay Scene Delegate — Plus-Gating (TAN-56), POI-Erfahrung (TAN-55), Limited UI (TAN-57).
final class FuelNowCarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    static var entitlementProviderFactory: @MainActor () -> any CarPlayEntitlementProviding = {
        EntitlementManager()
    }

    private var interfaceController: CPInterfaceController?
    private var carPlayScene: CPTemplateApplicationScene?
    private var entitlementProvider: (any CarPlayEntitlementProviding)?
    /// Letzte Routing-Pfadentscheidung (Plus vs. Limited — nur bei Wechsel wird Limited neu gesetzt).
    private var lastRoutingPath: CarPlayRoute?
    /// Verhindert unnötige `setRootTemplate`-Aufrufe im Plus-Pfad bei gleicher Datenlage.
    private var lastPlusUISnapshot: PlusUISnapshot?
    private var didStartEntitlementObservation = false
    private var didStartStationObservation = false
    private var runtimeBootstrapTask: Task<Void, Never>?

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        carPlayScene = templateApplicationScene
        let provider = Self.entitlementProviderFactory()
        entitlementProvider = provider
        Task { @MainActor in
            await provider.start()
            primeStationFetchForCarPlay()
            lastRoutingPath = nil
            lastPlusUISnapshot = nil
            reconcileCarPlayUI(animated: false)
            armEntitlementObservation()
            armStationObservationIfPossible()
            bootstrapRuntimeDependenciesIfNeeded()
        }
    }

    // MARK: - Observation

    @MainActor
    private func armEntitlementObservation() {
        didStartEntitlementObservation = true
        guard let manager = entitlementProvider as? EntitlementManager else {
            // Existenzials/protocol-property Tracking unter `@Observable` ist unzuverlässig — ohne konkretes
            // EntitlementManager-Objekt (Tests mit Stub) reicht eine einmalige Aktualisierung nach Start.
            return
        }
        withObservationTracking {
            _ = manager.isPlusSubscriber
            _ = manager.isCarPlayUnlocked
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, self.didStartEntitlementObservation else { return }
                self.reconcileCarPlayUI(animated: true)
                self.armEntitlementObservation()
            }
        }
    }

    @MainActor
    private func armStationObservationIfPossible() {
        guard FuelNowRuntimeRegistry.stationStore != nil else { return }
        guard let store = FuelNowRuntimeRegistry.stationStore else { return }
        didStartStationObservation = true
        withObservationTracking {
            _ = store.stations
            _ = store.loadState
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, self.didStartStationObservation else { return }
                self.reconcileCarPlayUI(animated: true)
                self.armStationObservationIfPossible()
            }
        }
    }

    // MARK: - Routing & Templates

    @MainActor
    private func reconcileCarPlayUI(animated: Bool) {
        guard let interfaceController else { return }
        let unlocked = entitlementProvider?.isCarPlayUnlocked ?? false
        let route = CarPlayRoutingPolicy.route(forCarPlayUnlocked: unlocked)

        if route == .limited {
            lastPlusUISnapshot = nil
            if lastRoutingPath != .limited {
                lastRoutingPath = .limited
                interfaceController.setRootTemplate(makeLimitedTemplate(), animated: animated, completion: nil)
            }
            return
        }

        if lastRoutingPath != .plus {
            lastRoutingPath = .plus
            lastPlusUISnapshot = nil
        }
        updatePlusRootIfNeeded(interfaceController: interfaceController, animated: animated)
    }

    @MainActor
    private func updatePlusRootIfNeeded(interfaceController: CPInterfaceController, animated: Bool) {
        guard let store = FuelNowRuntimeRegistry.stationStore else {
            let snapshot = PlusUISnapshot(kind: .waitingForStore)
            guard snapshot != lastPlusUISnapshot else { return }
            lastPlusUISnapshot = snapshot
            interfaceController.setRootTemplate(
                makePlusRootTemplate(store: nil, snapshot: snapshot),
                animated: animated,
                completion: nil
            )
            return
        }

        let snapshot = PlusUISnapshot(store: store)
        guard snapshot != lastPlusUISnapshot else { return }
        lastPlusUISnapshot = snapshot
        interfaceController.setRootTemplate(
            makePlusRootTemplate(store: store, snapshot: snapshot),
            animated: animated,
            completion: nil
        )
    }

    @MainActor
    private func makeLimitedTemplate() -> CPInformationTemplate {
        CPInformationTemplate(
            title: String(localized: "carplay.locked.title"),
            layout: .leading,
            items: [
                CPInformationItem(
                    title: String(localized: "carplay.locked.body"),
                    detail: nil
                ),
                CPInformationItem(
                    title: String(localized: "carplay.locked.detail"),
                    detail: nil
                ),
            ],
            actions: [openOnIPhoneAction()]
        )
    }

    @MainActor
    private func makePlusRootTemplate(store: StationStore?, snapshot: PlusUISnapshot) -> CPTemplate {
        switch snapshot.kind {
        case .waitingForStore, .loadingWithoutStations:
            return makeSimpleInfoTemplate(
                title: String(localized: "carplay.plus.loading.title"),
                body: String(localized: "carplay.plus.loading.body")
            )
        case .idleWithoutStations:
            return makeSimpleInfoTemplate(
                title: String(localized: "carplay.plus.idle.title"),
                body: String(localized: "carplay.plus.idle.body")
            )
        case .loadedEmpty:
            return makeSimpleInfoTemplate(
                title: String(localized: "carplay.plus.empty.title"),
                body: String(localized: "carplay.plus.empty.body")
            )
        case let .failed(errorKind):
            return makeSimpleInfoTemplate(
                title: String(localized: "carplay.plus.error.title"),
                body: localizedCarPlayErrorBody(for: errorKind)
            )
        case .stations:
            guard let store else {
                return makeSimpleInfoTemplate(
                    title: String(localized: "carplay.plus.loading.title"),
                    body: String(localized: "carplay.plus.loading.body")
                )
            }
            guard !store.stations.isEmpty else {
                return makeSimpleInfoTemplate(
                    title: String(localized: "carplay.plus.loading.title"),
                    body: String(localized: "carplay.plus.loading.body")
                )
            }
            return makeStationsListRoot(store: store)
        }
    }

    @MainActor
    private func makeSimpleInfoTemplate(title: String, body: String) -> CPInformationTemplate {
        CPInformationTemplate(
            title: title,
            layout: .leading,
            items: [CPInformationItem(title: body, detail: nil)],
            actions: makeInfoActions()
        )
    }

    @MainActor
    private func makeStationsListRoot(store: StationStore) -> CPTemplate {
        let fuel = AppSettings.preferredFuelFromStorage()
        let stations = store.stations.filter { StationCarPlayPOIMapper.isRenderableStationCoordinate($0) }
        guard !stations.isEmpty else {
            return makeSimpleInfoTemplate(
                title: String(localized: "carplay.plus.empty.title"),
                body: String(localized: "carplay.plus.empty.body")
            )
        }
        let rows = StationCarPlayPOIMapper.buildRows(stations: stations, preferredFuel: fuel)
        let byID = StationCarPlayPOIMapper.stationsByIDReplacingDuplicates(stations)
        guard !rows.isEmpty else {
            return makeSimpleInfoTemplate(
                title: String(localized: "carplay.plus.error.title"),
                body: String(localized: "carplay.plus.error.generic")
            )
        }
        return StationCarPlayPOIMapper.makeNearbyListTemplate(rows: rows, stationsByID: byID) { [weak self] station in
            guard let self, let interfaceController = self.interfaceController else { return }
            let detail = CarPlayStationDetailInformationTemplate.make(
                station: station,
                interfaceController: interfaceController,
                carPlayScene: carPlayScene
            )
            // `presentTemplate` erlaubt laut Apple nur Alert/ActionSheet/VoiceControl — kein CPInformationTemplate.
            interfaceController.pushTemplate(detail, animated: true, completion: nil)
        }
    }

    @MainActor
    private func primeStationFetchForCarPlay() {
        guard let store = FuelNowRuntimeRegistry.stationStore else { return }
        guard let location = FuelNowRuntimeRegistry.locationService?.currentLocation else { return }
        store.handleLocationUpdate(location, radiusKm: AppSettings.SearchRadius.apiMaxKm, force: false)
    }

    @MainActor
    private func refreshStationsFromCarPlay() {
        guard let store = FuelNowRuntimeRegistry.stationStore else { return }
        guard let location = FuelNowRuntimeRegistry.locationService?.currentLocation else { return }
        store.forceRefresh(
            using: location,
            radiusKm: AppSettings.SearchRadius.apiMaxKm,
            trigger: .forcedUserLocation
        )
    }

    @MainActor
    private func makeInfoActions() -> [CPTextButton] {
        [retryAction(), openOnIPhoneAction()]
    }

    @MainActor
    private func retryAction() -> CPTextButton {
        CPTextButton(title: String(localized: "carplay.plus.retry"), textStyle: .confirm) { [weak self] _ in
            self?.refreshStationsFromCarPlay()
        }
    }

    @MainActor
    private func openOnIPhoneAction() -> CPTextButton {
        CPTextButton(title: String(localized: "carplay.openOnIPhone"), textStyle: .normal) { _ in
            // Hinweis-Aktion für den sicheren Handoff: Start/Unlock erfolgen bewusst auf dem iPhone.
        }
    }

    private func localizedCarPlayErrorBody(for errorKind: PlusUISnapshot.CarPlayErrorKind) -> String {
        switch errorKind {
        case .connectivity:
            String(localized: "carplay.plus.error.connectivity")
        case .rateLimited:
            String(localized: "carplay.plus.error.rateLimited")
        case .serviceUnavailable:
            String(localized: "error.tankerkoenig.http503.beta")
        case .generic:
            String(localized: "carplay.plus.error.generic")
        }
    }

    @MainActor
    private func bootstrapRuntimeDependenciesIfNeeded() {
        runtimeBootstrapTask?.cancel()
        runtimeBootstrapTask = Task { @MainActor [weak self] in
            guard let self else { return }

            // CarPlay kann vor dem iPhone-Window connecten. Wir geben der Runtime kurz Zeit,
            // StationStore/LocationService im Registry zu setzen, bevor wir den Plus-Pfad festlegen.
            for _ in 0..<20 {
                try? await Task.sleep(for: .milliseconds(250))
                guard self.interfaceController != nil else { return }

                let hasStore = FuelNowRuntimeRegistry.stationStore != nil
                let hasLocation = FuelNowRuntimeRegistry.locationService?.currentLocation != nil
                guard hasStore || hasLocation else { continue }

                self.armStationObservationIfPossible()
                self.primeStationFetchForCarPlay()
                self.reconcileCarPlayUI(animated: true)
                return
            }
        }
    }
}

// MARK: - Plus UI Snapshot

private struct PlusUISnapshot: Equatable {
    enum CarPlayErrorKind: Equatable {
        case connectivity
        case rateLimited
        case serviceUnavailable
        case generic
    }

    enum Kind: Equatable {
        case waitingForStore
        case loadingWithoutStations
        case idleWithoutStations
        case loadedEmpty
        case failed(CarPlayErrorKind)
        case stations([UUID])
    }

    let kind: Kind

    init(kind: Kind) {
        self.kind = kind
    }

    @MainActor
    init(store: StationStore) {
        switch store.loadState {
        case .failed:
            if store.stations.isEmpty {
                kind = .failed(Self.mapErrorKind(from: store.lastError))
            } else {
                kind = .stations(store.stations.map(\.id))
            }
        case .loading where store.stations.isEmpty:
            kind = .loadingWithoutStations
        case .loading:
            kind = .stations(store.stations.map(\.id))
        case .idle where store.stations.isEmpty:
            kind = .idleWithoutStations
        case .idle:
            kind = .stations(store.stations.map(\.id))
        case .loaded where store.stations.isEmpty:
            kind = .loadedEmpty
        case .loaded:
            kind = .stations(store.stations.map(\.id))
        }
    }

    private static func mapErrorKind(from error: Error?) -> CarPlayErrorKind {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet,
                 .timedOut,
                 .networkConnectionLost,
                 .cannotFindHost,
                 .cannotConnectToHost,
                 .dnsLookupFailed:
                return .connectivity
            default:
                break
            }
        }

        if let tankerkoenigFailure = error as? TankerkoenigClient.Failure {
            switch tankerkoenigFailure {
            case .rateLimited:
                return .rateLimited
            case let .http(statusCode) where statusCode == 429:
                return .rateLimited
            case let .http(statusCode) where statusCode == 503 && FuelNowFeatureFlags.showsTankerkoenig503BetaUserMessage:
                return .serviceUnavailable
            case let .network(urlError):
                return mapErrorKind(from: urlError)
            default:
                break
            }
        }

        return .generic
    }
}

// MARK: - Disconnect

extension FuelNowCarPlaySceneDelegate {
    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnect interfaceController: CPInterfaceController
    ) {
        runtimeBootstrapTask?.cancel()
        runtimeBootstrapTask = nil
        self.interfaceController = nil
        carPlayScene = nil
        entitlementProvider = nil
        lastRoutingPath = nil
        lastPlusUISnapshot = nil
        didStartEntitlementObservation = false
        didStartStationObservation = false
    }
}
#endif
