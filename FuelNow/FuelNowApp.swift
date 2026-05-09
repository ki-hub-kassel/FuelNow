import AppIntents
import SwiftUI
import WhatsNewKit
import WidgetKit

@main
struct FuelNowApp: App {
    @State private var locationService = LocationService(snapshotStore: UserDefaultsLocationSnapshotStore())
    @State private var stationDetailFetcher = TankerkoenigStationDetailFetcher(client: TankerkoenigClient())
    @State private var stationStore = StationStoreFactory.makeDefault()
    @State private var entitlementManager = EntitlementManager()
    @State private var networkMonitor = NetworkMonitor()
    @State private var widgetSnapshotStore = WidgetSnapshotStore()
    @AppStorage(AppSettings.UserDefaultsKey.appearancePreference)
    private var appearanceRaw = AppSettings.AppearancePreference.system.rawValue

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
            ContentView()
                .preferredColorScheme(appearancePreference.preferredSwiftUIColorScheme)
                .environment(locationService)
                .environment(stationStore)
                .environment(\.stationDetailFetcher, stationDetailFetcher)
                .environment(entitlementManager)
                .environment(networkMonitor)
                .environment(MapDeepLinkStore.shared)
                .environment(\.whatsNew, whatsNewEnvironment)
                .onAppear {
                    FuelNowRuntimeRegistry.stationStore = stationStore
                    FuelNowRuntimeRegistry.locationService = locationService
                    networkMonitor.start()
                    syncWidgetSnapshot()
                    Task {
                        await StationIntentResolution.shared.setResolver(StationStoreIntentResolver())
                    }
                }
                .onChange(of: stationStore.stations) { _, _ in
                    syncWidgetSnapshot()
                }
                .onChange(of: stationStore.loadState) { _, newState in
                    syncWidgetSnapshot()
                    ShortcutSuggestionDonation.donateAfterStationsLoadedIfNeeded(
                        loadState: newState,
                        stationCount: stationStore.stations.count
                    )
                    if case .loaded = newState, !stationStore.stations.isEmpty {
                        FuelNowAppShortcuts.updateAppShortcutParameters()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { notification in
                    // Only react to changes on the standard defaults. Without this guard, our own
                    // write into the App-Group `sharedDefaults` re-fires the notification and we
                    // recurse on the main thread until the UI freezes (black screen on launch).
                    guard (notification.object as? UserDefaults) === UserDefaults.standard else { return }
                    syncWidgetSnapshot()
                }
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
                    await entitlementManager.start()
                    #if DEBUG
                    APIKeys.warnIfPlaceholderActive()
                    #endif
                }
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
            stations: stationStore.stations,
            preferredFuel: preferredFuel,
            loadState: stationStore.loadState
        )
        widgetSnapshotStore.write(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
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
