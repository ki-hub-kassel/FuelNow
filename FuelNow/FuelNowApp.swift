import SwiftUI
import WhatsNewKit

@main
struct FuelNowApp: App {
    @State private var locationService = LocationService(snapshotStore: UserDefaultsLocationSnapshotStore())
    @State private var stationStore = StationStoreFactory.makeDefault()
    @State private var entitlementManager = EntitlementManager()
    @State private var networkMonitor = NetworkMonitor()
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
                )
            ]
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appearancePreference.preferredSwiftUIColorScheme)
                .environment(locationService)
                .environment(stationStore)
                .environment(entitlementManager)
                .environment(networkMonitor)
                .environment(MapDeepLinkStore.shared)
                .environment(\.whatsNew, whatsNewEnvironment)
                .onAppear {
                    FuelNowRuntimeRegistry.stationStore = stationStore
                    FuelNowRuntimeRegistry.locationService = locationService
                    networkMonitor.start()
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
