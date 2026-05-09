import CoreLocation
import Foundation

/// Reguläre Öffnungszeiten aus `detail.php` (`openingTimes`).
///
/// Siehe [Tankerkönig API – Detailabfrage](https://creativecommons.tankerkoenig.de/).
struct OpeningSchedule: Hashable, Sendable, Codable {
    var text: String
    var start: String
    var end: String
}

/// Tankstelle entsprechend Tankerkönig Umkreissuche (`stations`-Array) und Detailantwort (`station`-Objekt).
///
/// Preisfelder können in `prices.php` als Zahl **oder** als `false` geliefert werden; beim Dekodieren wird `false` als `nil` interpretiert.
struct Station: Identifiable, Hashable, Sendable, Decodable {
    let id: UUID
    let name: String
    let brand: String
    let street: String
    /// Wird aus String oder Zahl dekodiert; fehlend/`null` → leer (`list.php`-Robustheit).
    let houseNumber: String
    let place: String
    /// PLZ; die API liefert sie als Ganzzahl, wir halten sie als String für die Anzeige.
    let postCode: String
    let latitude: Double
    let longitude: Double
    /// Entfernung zum Suchpunkt in km (nur Umkreissuche); in der Detailantwort fehlt das Feld oft.
    let distanceKilometers: Double?
    let isOpen: Bool
    let e5Price: Double?
    let e10Price: Double?
    let dieselPrice: Double?
    let openingTimes: [OpeningSchedule]?
    let overrides: [String]?
    let wholeDay: Bool?
    let state: String?

    /// Koordinate für MapKit / CoreLocation.
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Straße + Hausnummer + PLZ + Ort.
    var fullAddress: String {
        let trimmedHouse = houseNumber.trimmingCharacters(in: .whitespaces)
        let streetPart = [street, trimmedHouse].filter { !$0.isEmpty }.joined(separator: " ")
        let cityPart = [postCode, place].filter { !$0.isEmpty }.joined(separator: " ")
        return [streetPart, cityPart].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    func price(for fuel: FuelType) -> Double? {
        switch fuel {
        case .e5: e5Price
        case .e10: e10Price
        case .diesel: dieselPrice
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, name, brand, street, houseNumber, place, lat, lng, dist, isOpen
        case postCode
        case e5Price = "e5"
        case e10Price = "e10"
        case dieselPrice = "diesel"
        case openingTimes, overrides, wholeDay, state
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        brand = try c.decode(String.self, forKey: .brand)
        street = try c.decode(String.self, forKey: .street)
        houseNumber = try Self.decodeTankerkoenigHouseNumber(from: c)
        place = try c.decode(String.self, forKey: .place)

        if !c.contains(.postCode) {
            postCode = ""
        } else if try c.decodeNil(forKey: .postCode) {
            postCode = ""
        } else if let code = try? c.decode(Int.self, forKey: .postCode) {
            postCode = String(code)
        } else if let code = try? c.decode(String.self, forKey: .postCode) {
            postCode = code.trimmingCharacters(in: .whitespaces)
        } else {
            let context = DecodingError.Context(
                codingPath: c.codingPath + [CodingKeys.postCode],
                debugDescription: "Expected Int, String, or null for Tankerkönig postCode."
            )
            throw DecodingError.typeMismatch(String.self, context)
        }

        latitude = try c.decode(Double.self, forKey: .lat)
        longitude = try c.decode(Double.self, forKey: .lng)
        distanceKilometers = try c.decodeIfPresent(Double.self, forKey: .dist)
        isOpen = try c.decode(Bool.self, forKey: .isOpen)

        e5Price = try c.decodeTankerkoenigFuelPrice(forKey: .e5Price)
        e10Price = try c.decodeTankerkoenigFuelPrice(forKey: .e10Price)
        dieselPrice = try c.decodeTankerkoenigFuelPrice(forKey: .dieselPrice)

        openingTimes = try c.decodeIfPresent([OpeningSchedule].self, forKey: .openingTimes)
        overrides = try c.decodeIfPresent([String].self, forKey: .overrides)
        wholeDay = try c.decodeIfPresent(Bool.self, forKey: .wholeDay)
        state = try c.decodeIfPresent(String.self, forKey: .state)
    }

    /// Hausnummer: meist String; die API kann sie auch als Zahl liefern — fehlend/`null` → leer.
    private static func decodeTankerkoenigHouseNumber(from c: KeyedDecodingContainer<CodingKeys>) throws -> String {
        guard c.contains(.houseNumber) else { return "" }
        if try c.decodeNil(forKey: .houseNumber) { return "" }
        if let s = try? c.decode(String.self, forKey: .houseNumber) {
            return s.trimmingCharacters(in: .whitespaces)
        }
        if let n = try? c.decode(Int.self, forKey: .houseNumber) {
            return String(n)
        }
        if let d = try? c.decode(Double.self, forKey: .houseNumber) {
            let rounded = d.rounded()
            if abs(d - rounded) < .ulpOfOne {
                return String(Int(rounded))
            }
            return String(d)
        }
        let context = DecodingError.Context(
            codingPath: c.codingPath + [CodingKeys.houseNumber],
            debugDescription: "Expected String, number, or null for Tankerkönig houseNumber."
        )
        throw DecodingError.typeMismatch(String.self, context)
    }

    static func == (lhs: Station, rhs: Station) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension KeyedDecodingContainer {
    /// Dekodiert Tankerkönig-Spritpreis: Zahl, fehlender Schlüssel/`null` → `nil`, booleschem `false` → nicht angeboten (`nil`).
    fileprivate func decodeTankerkoenigFuelPrice(forKey key: Key) throws -> Double? {
        guard contains(key) else { return nil }
        if try decodeNil(forKey: key) { return nil }
        if let value = try? decode(Double.self, forKey: key) {
            return value
        }
        if let flag = try? decode(Bool.self, forKey: key), flag == false {
            return nil
        }
        let context = DecodingError.Context(
            codingPath: codingPath + [key],
            debugDescription: "Expected Double or false for Tankerkönig fuel price."
        )
        throw DecodingError.typeMismatch(Double.self, context)
    }
}
