import AppIntents

/// Kurzbefehle für Siri und die Kurzbefehle-App — deutsche und englische Phrasen.
struct FuelNowAppShortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: FindNearestStationIntent(),
            phrases: [
                "Nächste Tankstelle in \(.applicationName)",
                "Wo ist die nächste Tankstelle in \(.applicationName)",
                "Nächste Tankstelle in meiner Nähe in \(.applicationName)",
                "Tankstelle in der Nähe in \(.applicationName)",
                "Zeig mir die nächste Tankstelle in \(.applicationName)",
                "Finde die nächste Tankstelle in \(.applicationName)",
                "Nearest gas station in \(.applicationName)",
                "Where is the nearest gas station in \(.applicationName)",
                "Find the nearest gas station in \(.applicationName)",
                "Show me the nearest gas station in \(.applicationName)",
            ],
            shortTitle: "Nächste Tankstelle",
            systemImageName: "fuelpump.fill"
        )
        AppShortcut(
            intent: FindCheapestStationIntent(),
            phrases: [
                "Günstigste Tankstelle in \(.applicationName)",
                "Wo ist die günstigste Tankstelle in \(.applicationName)",
                "Günstigste Tankstelle in meiner Nähe in \(.applicationName)",
                "Wo kann ich günstig tanken in \(.applicationName)",
                "Wo gibt es den günstigsten Sprit in \(.applicationName)",
                "Billigste Tankstelle in \(.applicationName)",
                "Cheapest gas station in \(.applicationName)",
                "Where is the cheapest gas station in \(.applicationName)",
                "Cheapest gas station near me in \(.applicationName)",
                "Find me cheap gas in \(.applicationName)",
            ],
            shortTitle: "Günstigste Tankstelle",
            systemImageName: "eurosign.circle.fill"
        )
        AppShortcut(
            intent: OpenFuelNowIntent(),
            phrases: [
                "Öffne \(.applicationName)",
                "Zeig mir \(.applicationName)",
                "Open \(.applicationName)",
                "Show \(.applicationName)",
            ],
            shortTitle: "FuelNow öffnen",
            systemImageName: "map.fill"
        )
        AppShortcut(
            intent: OpenStationIntent(),
            phrases: [
                "Tankstelle in \(.applicationName) öffnen",
                "Öffne Tankstelle in \(.applicationName)",
                "Open station in \(.applicationName)",
                "Show station in \(.applicationName)",
            ],
            shortTitle: "Tankstelle öffnen",
            systemImageName: "mappin.and.ellipse"
        )
    }
}
