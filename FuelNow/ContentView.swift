import SwiftUI
import WhatsNewKit

struct ContentView: View {
    @Environment(LocationService.self) private var locationService
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppSettings.UserDefaultsKey.hasCompletedOnboarding)
    private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                NavigationStack {
                    MapScreen()
                }
                .whatsNewSheet()
            } else {
                OnboardingFlowView {
                    hasCompletedOnboarding = true
                    locationService.requestWhenInUseAuthorizationIfNeeded()
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                MapDeepLinkStore.shared.syncPendingControlFromAppGroupIfNeeded()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(LocationService())
        .environment(StationStore())
        .environment(EntitlementManager())
        .environment(NetworkMonitor())
        .environment(MapDeepLinkStore(defaults: UserDefaults(suiteName: "tr.preview.ContentView.deeplink")!))
}
