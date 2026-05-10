import SwiftUI
import WidgetKit

@main
struct FuelNowWidgetsBundle: WidgetBundle {
    var body: some Widget {
        FuelNowWidget()
        FuelNowCheapestNearbyWidget()
        DrivingToStationLiveActivity()
        FuelNowCheapestStationControl()
        FuelNowRefreshMapRegionControl()
    }
}
