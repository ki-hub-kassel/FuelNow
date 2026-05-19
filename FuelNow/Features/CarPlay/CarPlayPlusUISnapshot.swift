#if canImport(CarPlay)
import Foundation

/// Entscheidet, ob `setRootTemplate` im Plus-Pfad erneut laufen muss (Datenlage + Sortierung).
struct CarPlayPlusUISnapshot: Equatable {
    enum CarPlayErrorKind: Equatable {
        case connectivity
        case rateLimited
        case serviceUnavailable
        case generic
    }

    enum Kind: Equatable {
        case waitingForStore
        case loadingWithoutStations
        case idleWithoutStations
        case loadedEmpty
        case failed(CarPlayErrorKind)
        case stations([UUID])
    }

    let kind: Kind
    let sortMode: CarPlayStationSortMode

    init(kind: Kind, sortMode: CarPlayStationSortMode = .distance) {
        self.kind = kind
        self.sortMode = sortMode
    }

    @MainActor
    init(store: StationStore, sortMode: CarPlayStationSortMode) {
        self.sortMode = sortMode
        switch store.loadState {
        case .failed:
            if store.stations.isEmpty {
                kind = .failed(Self.mapErrorKind(from: store.lastError))
            } else {
                kind = .stations(store.stations.map(\.id))
            }
        case .loading where store.stations.isEmpty:
            kind = .loadingWithoutStations
        case .loading:
            kind = .stations(store.stations.map(\.id))
        case .idle where store.stations.isEmpty:
            kind = .idleWithoutStations
        case .idle:
            kind = .stations(store.stations.map(\.id))
        case .loaded where store.stations.isEmpty:
            kind = .loadedEmpty
        case .loaded:
            kind = .stations(store.stations.map(\.id))
        }
    }

    private static func mapErrorKind(from error: Error?) -> CarPlayErrorKind {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet,
                 .timedOut,
                 .networkConnectionLost,
                 .cannotFindHost,
                 .cannotConnectToHost,
                 .dnsLookupFailed:
                return .connectivity
            default:
                break
            }
        }

        if let tankerkoenigFailure = error as? TankerkoenigClient.Failure {
            switch tankerkoenigFailure {
            case .rateLimited:
                return .rateLimited
            case let .http(statusCode) where statusCode == 429:
                return .rateLimited
            case let .http(statusCode) where statusCode == 503 && FuelNowFeatureFlags.showsTankerkoenig503BetaUserMessage:
                return .serviceUnavailable
            case let .network(urlError):
                return mapErrorKind(from: urlError)
            default:
                break
            }
        }

        return .generic
    }

    static func localizedErrorBody(for errorKind: CarPlayErrorKind) -> String {
        switch errorKind {
        case .connectivity:
            String(localized: "carplay.plus.error.connectivity")
        case .rateLimited:
            String(localized: "carplay.plus.error.rateLimited")
        case .serviceUnavailable:
            String(localized: "error.tankerkoenig.http503.beta")
        case .generic:
            String(localized: "carplay.plus.error.generic")
        }
    }
}
#endif
