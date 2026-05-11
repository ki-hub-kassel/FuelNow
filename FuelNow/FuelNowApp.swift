import AppIntents
import SwiftUI
import WhatsNewKit
import WidgetKit

@main
struct FuelNowApp: App {
    @State private var coordinator: FuelNowLifecycleCoordinator

    init() {
        let initialCoordinator = FuelNowLifecycleCoordinator()
        _coordinator = State(initialValue: initialCoordinator)

        // BGTask-Handler MUSS in der App-Init registriert werden — vor `body` Aufbau —
        // sonst lehnt iOS den Handler ab. Wir behalten eine schwache Coordinator-Referenz,
        // damit der Handler beim Aufruf an die aktuelle Instanz delegieren kann.
        let coordinatorRef = UnsafeFuelNowCoordinatorReference(coordinator: initialCoordinator)
        PriceAlertCoordinator.registerBackgroundHandler { coordinatorRef.coordinator?.priceAlertCoordinator }
    }

    /// Indirektion fuer den `@Sendable`-Closure des `BGTaskScheduler.register`-Aufrufs.
    /// Eine direkte Capture von `coordinator` waere nicht `Sendable`, aber wir lesen den
    /// Wert nur auf dem Main Actor (siehe `Task { @MainActor in ... }` im Handler).
    private final class UnsafeFuelNowCoordinatorReference: @unchecked Sendable {
        weak var coordinator: FuelNowLifecycleCoordinator?
        init(coordinator: FuelNowLifecycleCoordinator) {
            self.coordinator = coordinator
        }
    }

    @AppStorage(AppSettings.UserDefaultsKey.appearancePreference)
    private var appearanceRaw = AppSettings.AppearancePreference.system.rawValue

    @State private var showLaunchOverlay = true

    private var appearancePreference: AppSettings.AppearancePreference {
        AppSettings.AppearancePreference.resolved(storedRaw: appearanceRaw)
    }

    private var whatsNewEnvironment: WhatsNewEnvironment {
        WhatsNewEnvironment(
            whatsNewCollection: [
                WhatsNew(
                    version: "1.0.0",
                    title: "Was ist neu in FuelNow",
                    features: [
                        .init(
                            image: .init(systemName: "location.fill", foregroundColor: .blue),
                            title: "Stabilere Entfernungen",
                            subtitle: "Entfernungen werden jetzt beim Zuruckkehren zum Standort konsistenter aktualisiert."
                        ),
                        .init(
                            image: .init(systemName: "hand.raised.fill", foregroundColor: .mint),
                            title: "Besserer Start",
                            subtitle: "Neues Onboarding mit klarem Nutzen und optionaler Standortfreigabe."
                        ),
                        .init(
                            image: .init(systemName: "sparkles", foregroundColor: .teal),
                            title: "Plus deutlicher kommuniziert",
                            subtitle: "FuelNow Plus nennt CarPlay jetzt direkt im Einstiegstext."
                        ),
                    ],
                    primaryAction: .init(
                        title: "Weiter",
                        backgroundColor: .accentColor,
                        foregroundColor: .white
                    )
                ),
            ]
        )
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                rootContent
                if showLaunchOverlay {
                    AnimatedLaunchOverlay {
                        showLaunchOverlay = false
                    }
                    .zIndex(1)
                }
            }
        }
    }

    private var rootContent: some View {
        ContentView()
            .preferredColorScheme(appearancePreference.preferredSwiftUIColorScheme)
            .environment(coordinator.locationService)
            .environment(coordinator.stationStore)
            .environment(\.stationDetailFetcher, coordinator.stationDetailFetcher)
            .environment(coordinator.entitlementManager)
            .environment(coordinator.networkMonitor)
            .environment(coordinator.favoritesStore)
            .environment(MapDeepLinkStore.shared)
            .environment(\.whatsNew, whatsNewEnvironment)
            .onAppear {
                coordinator.networkMonitor.start()
                syncWidgetSnapshot()
                coordinator.priceAlertCoordinator.scheduleNextRefresh()
                Task {
                    await StationIntentResolution.shared.setResolver(StationStoreIntentResolver())
                }
            }
            .onChange(of: coordinator.stationStore.stations) { _, newStations in
                syncWidgetSnapshot()
                let fuel = AppSettings.preferredFuelFromStorage(defaults: UserDefaults.standard)
                StationSpotlightIndexer.scheduleReindex(stations: newStations, preferredFuel: fuel)
            }
            .onChange(of: coordinator.stationStore.loadState) { _, newState in
                syncWidgetSnapshot()
                ShortcutSuggestionDonation.donateAfterStationsLoadedIfNeeded(
                    loadState: newState,
                    stationCount: coordinator.stationStore.stations.count
                )
                if case .loaded = newState, !coordinator.stationStore.stations.isEmpty {
                    FuelNowAppShortcuts.updateAppShortcutParameters()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { notification in
                // Only react to changes on the standard defaults. Without this guard, our own
                // write into the App-Group `sharedDefaults` re-fires the notification and we
                // recurse on the main thread until the UI freezes (black screen on launch).
                guard (notification.object as? UserDefaults) === UserDefaults.standard else { return }
                syncWidgetSnapshot()
                let fuel = AppSettings.preferredFuelFromStorage(defaults: UserDefaults.standard)
                StationSpotlightIndexer.scheduleReindex(
                    stations: coordinator.stationStore.stations,
                    preferredFuel: fuel
                )
            }
            // WidgetKit (`widgetURL`): FuelNow-Widgets und Live-Activities nutzen `fuelnow://map` bzw.
            // `fuelnow://station/<uuid>` — bei CarPlay öffnet ein Tap die App-CarPlay-Session, wenn das Fahrzeug Touch unterstützt.
            .onOpenURL { url in
                Task { @MainActor in
                    guard let link = FuelNowDeepLink.parse(url) else { return }
                    switch link {
                    case .map:
                        MapDeepLinkStore.shared.clearPendingStationFocus()
                    case let .station(id):
                        MapDeepLinkStore.shared.enqueueStationFocus(id: id)
                    }
                }
            }
            .task {
                FuelNowTipsBootstrap.configure()
                await coordinator.entitlementManager.start()
                #if DEBUG
                APIKeys.warnIfPlaceholderActive()
                #endif
            }
    }

    private func syncWidgetSnapshot() {
        let sharedDefaults = WidgetSnapshotStore.sharedDefaults
        if let preferredFuelRaw = UserDefaults.standard.string(forKey: AppSettings.UserDefaultsKey.preferredFuelType),
           sharedDefaults.string(forKey: AppSettings.UserDefaultsKey.preferredFuelType) != preferredFuelRaw {
            sharedDefaults.set(preferredFuelRaw, forKey: AppSettings.UserDefaultsKey.preferredFuelType)
        }

        let preferredFuel = AppSettings.preferredFuelFromStorage(defaults: sharedDefaults)
        let snapshot = WidgetSnapshotBuilder.makeSnapshot(
            stations: coordinator.stationStore.stations,
            preferredFuel: preferredFuel,
            loadState: coordinator.stationStore.loadState
        )
        coordinator.widgetSnapshotStore.write(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
        // App-Group ist iPhone-only; die Watch-Companion-App holt sich denselben Snapshot
        // via WatchConnectivity (updateApplicationContext) — siehe WatchConnectivityCoordinator.
        WatchConnectivityCoordinator.shared.publish(snapshot)
    }
}

private extension AppSettings.AppearancePreference {
    var preferredSwiftUIColorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}
