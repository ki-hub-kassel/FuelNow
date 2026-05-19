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
    private var lastRoutingPath: CarPlayRoute?
    private var lastPlusUISnapshot: CarPlayPlusUISnapshot?
    private var stationSortMode: CarPlayStationSortMode = .distance
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
            stationSortMode = .distance
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
        guard let manager = entitlementProvider as? EntitlementManager else { return }
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
            let snapshot = CarPlayPlusUISnapshot(kind: .waitingForStore, sortMode: stationSortMode)
            applyPlusSnapshot(snapshot, store: nil, interfaceController: interfaceController, animated: animated)
            return
        }

        let snapshot = CarPlayPlusUISnapshot(store: store, sortMode: stationSortMode)
        applyPlusSnapshot(snapshot, store: store, interfaceController: interfaceController, animated: animated)
    }

    @MainActor
    private func applyPlusSnapshot(
        _ snapshot: CarPlayPlusUISnapshot,
        store: StationStore?,
        interfaceController: CPInterfaceController,
        animated: Bool
    ) {
        guard snapshot != lastPlusUISnapshot else { return }
        lastPlusUISnapshot = snapshot
        interfaceController.setRootTemplate(
            makePlusRootTemplate(store: store, snapshot: snapshot),
            animated: animated,
            completion: nil
        )
    }

    @MainActor
    private func toggleStationSortMode() {
        stationSortMode.toggle()
        lastPlusUISnapshot = nil
        reconcileCarPlayUI(animated: true)
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
    private func makePlusRootTemplate(store: StationStore?, snapshot: CarPlayPlusUISnapshot) -> CPTemplate {
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
                body: CarPlayPlusUISnapshot.localizedErrorBody(for: errorKind)
            )
        case .stations:
            guard let store, !store.stations.isEmpty else {
                return makeSimpleInfoTemplate(
                    title: String(localized: "carplay.plus.loading.title"),
                    body: String(localized: "carplay.plus.loading.body")
                )
            }
            return CarPlayStationListBuilder.makeStationsListRoot(
                store: store,
                sortMode: stationSortMode,
                environment: CarPlayStationListEnvironment(
                    carPlayScene: carPlayScene,
                    interfaceController: interfaceController,
                    onToggleSort: { [weak self] in self?.toggleStationSortMode() },
                    makeSimpleInfoTemplate: { [weak self] title, body in
                        self?.makeSimpleInfoTemplate(title: title, body: body)
                            ?? CPInformationTemplate(title: title, layout: .leading, items: [], actions: [])
                    }
                )
            )
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
        CPTextButton(title: String(localized: "carplay.openOnIPhone"), textStyle: .normal) { _ in }
    }

    @MainActor
    private func bootstrapRuntimeDependenciesIfNeeded() {
        runtimeBootstrapTask?.cancel()
        runtimeBootstrapTask = Task { @MainActor [weak self] in
            guard let self else { return }

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
        stationSortMode = .distance
        didStartEntitlementObservation = false
        didStartStationObservation = false
    }
}
#endif
