import CoreLocation
import Foundation
import MapKit
import SwiftUI

/// Einzelpin oder Cluster — SwiftUI-`Map` hat kein natives MKClustering; wir gruppieren nach sichtbarem Ausschnitt und Zoom.
enum MapStationAnnotationItem: Identifiable {
    case single(Station)
    case cluster(stations: [Station], coordinate: CLLocationCoordinate2D)

    var id: String {
        switch self {
        case .single(let station):
            station.id.uuidString
        case .cluster(let stations, _):
            Self.clusterIdentityKey(stations)
        }
    }

    var coordinate: CLLocationCoordinate2D {
        switch self {
        case .single(let station):
            station.coordinate
        case .cluster(_, let coordinate):
            coordinate
        }
    }

    static func clusterIdentityKey(_ stations: [Station]) -> String {
        stations.map(\.id.uuidString).sorted().joined(separator: "|")
    }
}

private enum ClusterZoomMath {
    static let bboxPaddingFactor = 1.45
    /// Mindest-Verkleinerung vs. aktuelle Span, sonst erzwungenes Nachzoomen.
    static let shrinkEnoughRatio = 0.92
    static let forcedZoomFactor = 0.5
    static let softFloorFractionOfCurrent = 0.08
    static let maxSpanFractionOfCurrent = 0.9
    /// Untergrenze ~16 m — verhindert degenerierte Regionen, erlaubt aber mehr als das frühere 0.004°-Plateau.
    static let absoluteMinSpanDegrees = 0.00015
}

enum StationMapClustering {
    /// Gitter über die aktuelle Region — bei großem Zoom (große Span) weniger Zellen ⇒ stärkeres Clustern.
    static func annotationItems(for stations: [Station], region: MKCoordinateRegion) -> [MapStationAnnotationItem] {
        let visible = stationsVisible(in: region, stations: stations)
        guard !visible.isEmpty else { return [] }

        let divisions = gridDivisions(for: region)
        let latMin = region.center.latitude - region.span.latitudeDelta / 2
        let lonMin = region.center.longitude - region.span.longitudeDelta / 2
        let cellLat = max(region.span.latitudeDelta / Double(divisions), 1e-9)
        let cellLon = max(region.span.longitudeDelta / Double(divisions), 1e-9)

        var buckets: [[Station]] = []
        buckets.reserveCapacity(visible.count)

        var bucketIndexByKey: [String: Int] = [:]
        bucketIndexByKey.reserveCapacity(visible.count)

        for station in visible {
            let gi = min(divisions - 1, max(0, Int(floor((station.latitude - latMin) / cellLat))))
            let gj = min(divisions - 1, max(0, Int(floor((station.longitude - lonMin) / cellLon))))
            let key = "\(gi)_\(gj)"
            if let existing = bucketIndexByKey[key] {
                buckets[existing].append(station)
            } else {
                bucketIndexByKey[key] = buckets.count
                buckets.append([station])
            }
        }

        var items: [MapStationAnnotationItem] = []
        items.reserveCapacity(buckets.count)
        for bucket in buckets {
            if bucket.count == 1, let only = bucket.first {
                items.append(.single(only))
            } else {
                let coord = centroid(of: bucket)
                items.append(.cluster(stations: bucket, coordinate: coord))
            }
        }
        return mergeProximitySingles(items)
    }

    /// Bounding box für Zoom nach Cluster-Tap — etwas Luft, damit Pins sich auflösen.
    /// Verhindert Span-Plateaus (zwei fast gleiche Pins + bereits kleiner Ausschnitt): erzwingt multiplikatives Nachzoomen.
    static func regionToExpandCluster(_ stations: [Station], currentRegion: MKCoordinateRegion) -> MKCoordinateRegion {
        guard let minLat = stations.map(\.latitude).min(),
              let maxLat = stations.map(\.latitude).max(),
              let minLon = stations.map(\.longitude).min(),
              let maxLon = stations.map(\.longitude).max()
        else {
            return currentRegion
        }

        let center = centroid(of: stations)
        let curLat = currentRegion.span.latitudeDelta
        let curLon = currentRegion.span.longitudeDelta

        var latDelta = (maxLat - minLat) * ClusterZoomMath.bboxPaddingFactor
        var lonDelta = (maxLon - minLon) * ClusterZoomMath.bboxPaddingFactor

        let softFloorLat = max(curLat * ClusterZoomMath.softFloorFractionOfCurrent, ClusterZoomMath.absoluteMinSpanDegrees)
        let softFloorLon = max(curLon * ClusterZoomMath.softFloorFractionOfCurrent, ClusterZoomMath.absoluteMinSpanDegrees)
        latDelta = max(latDelta, softFloorLat)
        lonDelta = max(lonDelta, softFloorLon)

        latDelta = min(latDelta, curLat * ClusterZoomMath.maxSpanFractionOfCurrent)
        lonDelta = min(lonDelta, curLon * ClusterZoomMath.maxSpanFractionOfCurrent)

        let shrinksEnough =
            latDelta <= curLat * ClusterZoomMath.shrinkEnoughRatio ||
            lonDelta <= curLon * ClusterZoomMath.shrinkEnoughRatio
        if !shrinksEnough {
            latDelta = curLat * ClusterZoomMath.forcedZoomFactor
            lonDelta = curLon * ClusterZoomMath.forcedZoomFactor
        }

        let floorLat = min(ClusterZoomMath.absoluteMinSpanDegrees, curLat * 0.4)
        let floorLon = min(ClusterZoomMath.absoluteMinSpanDegrees, curLon * 0.4)
        latDelta = max(latDelta, floorLat)
        lonDelta = max(lonDelta, floorLon)

        return MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
    }

    private static func stationsVisible(in region: MKCoordinateRegion, stations: [Station]) -> [Station] {
        let padLat = region.span.latitudeDelta * 0.12
        let padLon = region.span.longitudeDelta * 0.12
        let minLat = region.center.latitude - region.span.latitudeDelta / 2 - padLat
        let maxLat = region.center.latitude + region.span.latitudeDelta / 2 + padLat
        let minLon = region.center.longitude - region.span.longitudeDelta / 2 - padLon
        let maxLon = region.center.longitude + region.span.longitudeDelta / 2 + padLon

        return stations.filter { s in
            s.latitude >= minLat && s.latitude <= maxLat && s.longitude >= minLon && s.longitude <= maxLon
        }
    }

    private static func gridDivisions(for region: MKCoordinateRegion) -> Int {
        let extent = max(region.span.latitudeDelta, region.span.longitudeDelta)
        switch extent {
        case ..<0.014:
            return 26
        case ..<0.024:
            return 22
        case ..<0.038:
            return 18
        case ..<0.065:
            return 14
        case ..<0.11:
            return 10
        default:
            return 7
        }
    }

    private static func centroid(of stations: [Station]) -> CLLocationCoordinate2D {
        let lat = stations.map(\.latitude).reduce(0, +) / Double(stations.count)
        let lon = stations.map(\.longitude).reduce(0, +) / Double(stations.count)
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    /// Genau zwei nahe Einzelpins zu einem „2“-Cluster — überlappende Touch-Ziele; ohne Mehrfach-Merge (Gitternetz bleibt bei ≥3 Singles gültig).
    static func mergeProximitySingles(_ items: [MapStationAnnotationItem], radiusMeters: CLLocationDistance = 100) -> [
        MapStationAnnotationItem
    ] {
        var singles: [Station] = []
        for item in items {
            if case .single(let station) = item { singles.append(station) }
        }
        guard singles.count == 2 else { return items }
        let a = singles[0], b = singles[1]
        let distance = CLLocation(latitude: a.latitude, longitude: a.longitude)
            .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
        guard distance <= radiusMeters else { return items }

        var insertedPair = false
        var output: [MapStationAnnotationItem] = []
        output.reserveCapacity(items.count - 1)
        for item in items {
            switch item {
            case .cluster:
                output.append(item)
            case .single(let station):
                if !insertedPair && (station.id == a.id || station.id == b.id) {
                    output.append(.cluster(stations: [a, b], coordinate: centroid(of: [a, b])))
                    insertedPair = true
                } else if station.id != a.id && station.id != b.id {
                    output.append(.single(station))
                }
            }
        }
        return output
    }
}

/// Cluster-Pille (Anzahl) — gleiche Material-Pille wie Einzel-Pins (kein Liquid Glass auf Kartendaten).
struct StationClusterAnnotationView: View {
    let count: Int

    var body: some View {
        Text("\(count)")
            .font(TRTypography.bodyBold())
            .foregroundStyle(TRColors.labelPrimary)
            .frame(minWidth: 44, minHeight: 44)
            .padding(.horizontal, TRSpacing.s)
            .trMapDataPill()
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(count) Tankstellen")
            .accessibilityHint("Tippen, um näher heranzuzoomen und die Stationen einzeln zu sehen.")
    }
}
