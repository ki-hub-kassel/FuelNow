import AppIntents
import CoreSpotlight
import Foundation

/// Siri/Shortcuts-Darstellung einer Tankstelle; `id` entspricht dem Domänen-`Station.id`.
///
/// **Spotlight:** Konformität zu `IndexedEntity` indexiert freiwillig Kurzinfos (Adresse + Pumpenpreis),
/// ohne Koordinaten im sichtbaren Snippet — siehe ``StationSpotlightIndexer``.
struct StationEntity: AppEntity, IndexedEntity {
    typealias DefaultQuery = StationQuery

    static var defaultQuery: StationQuery { StationQuery() }

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Tankstelle"
    }

    var displayRepresentation: DisplayRepresentation {
        if let line = indexingDetailLine, !line.isEmpty {
            return DisplayRepresentation(
                title: LocalizedStringResource(stringLiteral: title),
                subtitle: LocalizedStringResource(stringLiteral: line)
            )
        }
        return DisplayRepresentation(title: LocalizedStringResource(stringLiteral: title))
    }

    let id: Station.ID
    let title: String
    /// Zeileninhalt für Spotlight/`contentDescription`; bei Siri-Queries i. d. R. `nil`.
    let indexingDetailLine: String?

    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet()
        if let line = indexingDetailLine, !line.isEmpty {
            attributes.contentDescription = line
        } else {
            attributes.contentDescription = title
        }
        return attributes
    }

    init(station: Station, indexingDetailLine: String? = nil) {
        id = station.id
        title = station.name
        self.indexingDetailLine = indexingDetailLine
    }

    init(id: Station.ID, title: String, indexingDetailLine: String? = nil) {
        self.id = id
        self.title = title
        self.indexingDetailLine = indexingDetailLine
    }
}
