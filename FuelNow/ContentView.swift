import SwiftUI
import WhatsNewKit

struct ContentView: View {
    @Environment(LocationService.self) private var locationService
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
