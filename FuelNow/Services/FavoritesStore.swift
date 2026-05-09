import Foundation
import Observation

/// Lokal persistierter Datensatz fuer eine Favoriten-Tankstelle (Phase 2 / Roadmap-Phase 2).
///
/// **Design (lokal, kein Backend):** Die Liste wird **JSON-codiert in `UserDefaults`** gehalten,
/// damit App und Widget ueber die App-Group-Suite (`AppSettings.widgetAppGroupIdentifier`)
/// gemeinsam darauf zugreifen. SwiftData waere reicher, bringt aber Migrationspflichten und ist
/// fuer eine flache Liste mit ~10–50 Eintraegen unverhaeltnismaessig — die Datenmenge passt
/// problemlos in `UserDefaults`.
///
/// **Stabilitaet:** `id` ist die Tankerkoenig-Stations-`UUID` aus `Station.id` und damit
/// identisch zur ID, die `prices.php` und `detail.php` erwarten. Die uebrigen Felder sind
/// Anzeige-Cache (Marke, Strasse, Koordinate); bei naechstem Live-Refresh werden sie ueber
/// `Station` ueberschrieben, falls sich z. B. die Marke geaendert hat.
struct FavoriteStationRecord: Codable, Hashable, Sendable, Identifiable {
    let id: UUID
    var brand: String
    var name: String
    var street: String
    var place: String
    var latitude: Double
    var longitude: Double
    /// Letzter beobachteter Preis pro Sorte; wird vom Preis-Pushes-Pfad (Phase 3) genutzt,
    /// um Schwellen-Differenzen zu erkennen. `nil`, wenn noch kein Preis gesehen wurde.
    var lastSeenPriceE5: Double?
    var lastSeenPriceE10: Double?
    var lastSeenPriceDiesel: Double?
    /// ISO-Zeitstempel des letzten Refresh fuer diesen Favoriten.
    var lastRefreshedAt: Date?

    /// Bequemer Konstruktor aus einer geladenen `Station`.
    init(station: Station) {
        self.id = station.id
        self.brand = station.brand
        self.name = station.name
        self.street = station.fullAddress
        self.place = station.place
        self.latitude = station.latitude
        self.longitude = station.longitude
        self.lastSeenPriceE5 = station.e5Price
        self.lastSeenPriceE10 = station.e10Price
        self.lastSeenPriceDiesel = station.dieselPrice
        self.lastRefreshedAt = nil
    }

    /// Anzeige-Titel: Marke, falls vorhanden, sonst voller Stationsname.
    var displayTitle: String {
        let trimmed = brand.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? name : trimmed
    }

    /// Letzter bekannter Preis fuer eine Sorte.
    func lastSeenPrice(for fuel: FuelType) -> Double? {
        switch fuel {
        case .e5: return lastSeenPriceE5
        case .e10: return lastSeenPriceE10
        case .diesel: return lastSeenPriceDiesel
        }
    }
}

/// `@Observable`-Store fuer Favoriten-Tankstellen mit JSON-Persistenz in der App-Group.
///
/// **Persistenzpfad:** `UserDefaults(suiteName: AppSettings.widgetAppGroupIdentifier)` mit Key
/// `AppSettings.UserDefaultsKey.favoritesJSON`. Faellt auf `.standard` zurueck, wenn die Group
/// nicht erreichbar ist (z. B. fehlendes Entitlement im Testlauf).
///
/// **Schwellen-Logik fuer Phase 3 (Preis-Pushes):** `recordPriceObservation(...)` aktualisiert
/// `lastSeenPriceXY` **nur**, wenn der neue Preis sich gegenueber dem zuletzt gesehenen so
/// veraendert hat, dass die Schwelle ueberschritten wurde, oder wenn vorher kein Wert
/// vorhanden war. Das macht den Background-Pfad robust gegen API-Jitter.
@MainActor
@Observable
final class FavoritesStore {
    private(set) var favorites: [FavoriteStationRecord] = []

    private let defaults: UserDefaults
    private let storageKey: String

    init(
        defaults: UserDefaults = FavoritesStore.defaultDefaults(),
        storageKey: String = AppSettings.UserDefaultsKey.favoritesJSON
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
        self.favorites = Self.decode(from: defaults, key: storageKey)
    }

    /// Standard-`UserDefaults` aus der App-Group; faellt auf `.standard` zurueck, wenn nicht verfuegbar.
    static func defaultDefaults() -> UserDefaults {
        UserDefaults(suiteName: AppSettings.widgetAppGroupIdentifier) ?? .standard
    }

    func contains(stationID: UUID) -> Bool {
        favorites.contains { $0.id == stationID }
    }

    func add(_ station: Station) {
        guard !contains(stationID: station.id) else { return }
        var record = FavoriteStationRecord(station: station)
        record.lastRefreshedAt = Date()
        favorites.append(record)
        persist()
    }

    func remove(stationID: UUID) {
        let before = favorites.count
        favorites.removeAll { $0.id == stationID }
        if favorites.count != before {
            persist()
        }
    }

    func toggle(_ station: Station) {
        if contains(stationID: station.id) {
            remove(stationID: station.id)
        } else {
            add(station)
        }
    }

    /// Aktualisiert Anzeige-Cache + Preis-Observation; gibt zurueck, ob der Schwellenwert
    /// fuer einen Preisabfall erreicht wurde (`oldPrice - newPrice >= threshold`).
    @discardableResult
    func recordPriceObservation(
        stationID: UUID,
        fuel: FuelType,
        newPrice: Double,
        thresholdEuros: Double
    ) -> PriceDropOutcome {
        guard let index = favorites.firstIndex(where: { $0.id == stationID }) else {
            return .noFavorite
        }
        let oldPrice: Double? = favorites[index].lastSeenPrice(for: fuel)
        favorites[index].lastRefreshedAt = Date()
        switch fuel {
        case .e5: favorites[index].lastSeenPriceE5 = newPrice
        case .e10: favorites[index].lastSeenPriceE10 = newPrice
        case .diesel: favorites[index].lastSeenPriceDiesel = newPrice
        }
        persist()

        guard let oldPrice else {
            return .firstObservation(price: newPrice)
        }
        let drop = oldPrice - newPrice
        if drop >= thresholdEuros {
            return .priceDrop(oldPrice: oldPrice, newPrice: newPrice, dropEuros: drop)
        }
        return .stable(price: newPrice)
    }

    enum PriceDropOutcome: Equatable {
        case noFavorite
        case firstObservation(price: Double)
        case stable(price: Double)
        case priceDrop(oldPrice: Double, newPrice: Double, dropEuros: Double)
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(favorites)
            defaults.set(data, forKey: storageKey)
        } catch {
            #if DEBUG
            print("[FavoritesStore] encode failed: \(error)")
            #endif
        }
    }

    private static func decode(from defaults: UserDefaults, key: String) -> [FavoriteStationRecord] {
        guard let data = defaults.data(forKey: key) else { return [] }
        do {
            return try JSONDecoder().decode([FavoriteStationRecord].self, from: data)
        } catch {
            #if DEBUG
            print("[FavoritesStore] decode failed: \(error) — resetting")
            #endif
            return []
        }
    }
}
