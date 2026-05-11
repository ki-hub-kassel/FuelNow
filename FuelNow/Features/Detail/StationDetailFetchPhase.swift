import SwiftUI

enum StationDetailFetchPhase: Equatable {
    case idle
    case loading
    case loaded
    case failed
}
