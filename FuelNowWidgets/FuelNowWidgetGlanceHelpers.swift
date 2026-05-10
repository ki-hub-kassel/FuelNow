import SwiftUI
import WidgetKit

/// StandBy und CarPlay nutzen `systemSmall` oft ohne Container-Hintergrund — etwas größere,
/// gut lesbare Typo (Apple: „larger typography“ für CarPlay/StandBy).
enum FuelNowWidgetGlanceHelpers {
    static func isGlanceSmall(family: WidgetFamily, showsWidgetContainerBackground: Bool) -> Bool {
        family == .systemSmall && !showsWidgetContainerBackground
    }
}
