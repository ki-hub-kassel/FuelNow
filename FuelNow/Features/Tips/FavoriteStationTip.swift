// swiftformat:disable isEmpty
import SwiftUI
import TipKit

/// Erklärt das Favoriten-Herz im Tankstellendetail bis zur ersten Nutzung.
struct FavoriteStationTip: Tip {
    var title: Text {
        Text("tip.favoriteStation.title")
    }

    var message: Text? {
        Text("tip.favoriteStation.message")
    }

    var image: Image? {
        Image(systemName: "heart")
    }

    var rules: [Rule] {
        #Rule(FuelNowTipEvents.didUseFavoriteHeart) {
            $0.donations.count == 0
        }
    }
}
