// swiftformat:disable isEmpty
import SwiftUI
import TipKit

/// Hebt den Karten-Chip „In diesem Gebiet suchen“ hervor, bis die Funktion einmal genutzt wurde.
struct MapSearchAreaTip: Tip {
    var title: Text {
        Text("tip.mapSearchArea.title")
    }

    var message: Text? {
        Text("tip.mapSearchArea.message")
    }

    var image: Image? {
        Image(systemName: "magnifyingglass")
    }

    var rules: [Rule] {
        #Rule(FuelNowTipEvents.didUseSearchThisArea) {
            $0.donations.count == 0
        }
    }
}
