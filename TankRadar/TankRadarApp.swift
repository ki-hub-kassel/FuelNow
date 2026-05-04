import CoreLocation
import SwiftUI

@main
struct TankRadarApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await requestLocationAuthorizationIfNeeded()
                }
        }
    }

    @MainActor
    private func requestLocationAuthorizationIfNeeded() async {
        guard ProcessInfo.processInfo.environment["UITESTING"] != "1" else { return }
        CLLocationManager().requestWhenInUseAuthorization()
    }
}
