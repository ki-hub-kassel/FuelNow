import Foundation

/// Sortierung der CarPlay-Plus-Tankstellenliste (Session-State im Scene-Delegate).
enum CarPlayStationSortMode: Equatable {
    case distance
    case price

    mutating func toggle() {
        self = self == .distance ? .price : .distance
    }
}
