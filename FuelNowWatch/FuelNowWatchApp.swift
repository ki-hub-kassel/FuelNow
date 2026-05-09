import SwiftUI

/// Entry-Point der Apple-Watch-Companion-App (Roadmap Phase 6 — TAN-Watch).
///
/// **Status:** Code-Skelett. Das **watchOS-Target** in Xcode ist noch nicht angelegt; siehe
/// `FuelNowWatch/README.md` fuer die manuellen Setup-Schritte (File > New > Target >
/// watchOS App). Sobald das Target existiert und die Bundle-ID
/// `com.vibecoding.fuelnow.watch` (Companion-Identifier in Info.plist gesetzt) hat, baut
/// dieser Code direkt — ohne weitere Aenderungen.
@main
struct FuelNowWatchApp: App {
    @State private var snapshotProvider = FuelNowWatchSnapshotProvider()

    var body: some Scene {
        WindowGroup {
            FuelNowWatchRootView()
                .environment(snapshotProvider)
                .task { await snapshotProvider.load() }
        }
    }
}
