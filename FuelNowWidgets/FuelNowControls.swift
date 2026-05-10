import AppIntents
import OSLog
import SwiftUI
import WidgetKit

private enum FuelNowControlAppGroupBridge {
    private static let log = Logger(subsystem: "com.vibecoding.fuelnow", category: "ControlCenter")

    /// Nur die echte App-Group — kein Fallback auf `.standard` der Extension (sonst sieht die Haupt-App nichts).
    static func enqueue(_ action: FuelNowPendingMapControlAction) {
        guard let defs = UserDefaults(suiteName: WidgetSnapshotStore.appGroupIdentifier) else {
            log.error("ControlCenter: App-Group UserDefaults nil — Entitlements prüfen.")
            return
        }
        defs.set(action.rawValue, forKey: WidgetSnapshotStore.pendingControlMapActionKey)
        defs.synchronize()
    }
}

/// Steuerzentrum: öffnet FuelNow und markiert die Aktion in der App-Group (`MapDeepLinkStore.syncPendingControlFromAppGroupIfNeeded`).
struct OpenFuelNowCheapestFromControlIntent: AppIntent {
    static var title: LocalizedStringResource {
        LocalizedStringResource("control.cheapest.title")
    }

    static var description: IntentDescription {
        IntentDescription(LocalizedStringResource("control.cheapest.description"))
    }

    static var openAppWhenRun: Bool { true }

    static var isDiscoverable: Bool { false }

    func perform() async throws -> some IntentResult {
        FuelNowControlAppGroupBridge.enqueue(.focusCheapest)
        return .result()
    }
}

/// Entspricht „In diesem Gebiet suchen“ für die aktuell sichtbare Kartenmitte.
struct OpenFuelNowRefreshMapRegionFromControlIntent: AppIntent {
    static var title: LocalizedStringResource {
        LocalizedStringResource("control.refresh.title")
    }

    static var description: IntentDescription {
        IntentDescription(LocalizedStringResource("control.refresh.description"))
    }

    static var openAppWhenRun: Bool { true }

    static var isDiscoverable: Bool { false }

    func perform() async throws -> some IntentResult {
        FuelNowControlAppGroupBridge.enqueue(.refreshVisibleRegion)
        return .result()
    }
}

struct FuelNowCheapestStationControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.vibecoding.fuelnow.control.cheapest") {
            ControlWidgetButton(action: OpenFuelNowCheapestFromControlIntent()) {
                Label(String(localized: "control.cheapest.displayName"), systemImage: "eurosign.circle.fill")
            }
        }
        .displayName(LocalizedStringResource("control.cheapest.displayName"))
        .description(LocalizedStringResource("control.cheapest.controlDescription"))
    }
}

struct FuelNowRefreshMapRegionControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.vibecoding.fuelnow.control.refresh") {
            ControlWidgetButton(action: OpenFuelNowRefreshMapRegionFromControlIntent()) {
                Label(String(localized: "control.refresh.displayName"), systemImage: "magnifyingglass")
            }
        }
        .displayName(LocalizedStringResource("control.refresh.displayName"))
        .description(LocalizedStringResource("control.refresh.controlDescription"))
    }
}
