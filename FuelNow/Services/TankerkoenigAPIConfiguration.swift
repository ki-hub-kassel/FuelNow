import Foundation

/// Entscheidet, ob Tankerkönig **direkt** (mit Client-Key) oder über einen **HTTPS-Proxy** erreicht wird.
///
/// **Proxy (Default seit TAN-92):** Der echte API-Key liegt nur als Vercel-Environment-Secret
/// auf dem `tankerkoenig-proxy/`-Edge-Worker. Die App ruft z. B.
/// `https://<projekt>.vercel.app/api/json/list?lat=…&lng=…&rad=…&type=all&sort=dist`
/// (bewusst **ohne** `.php` — Vercel Firewall mitigiert `.php`-Pfade als WordPress-Bot-Scans
/// mit `x-vercel-mitigated: deny`). Der Proxy hängt `apikey` beim Weiterleiten an
/// `creativecommons.tankerkoenig.de/json/list.php` an — weiterhin **on-demand** pro
/// Nutzeraktion (kein Massen-Mirror; siehe `docs/TANKERKOENIG_CACHING.md`).
///
/// **Konfiguration (Reihenfolge):**
/// 1. Umgebungsvariable `TANKERKOENIG_PROXY_BASE_URL` — z. B. Xcode Scheme oder CI (überschreibt Info.plist).
/// 2. Info.plist-Schlüssel `TankerkoenigProxyBaseURL` — Default für Debug- und Release-Builds.
///
/// Ist kein Proxy gesetzt, gilt der **direkte** Modus mit ``APIKeys/tankerkoenig``.
enum TankerkoenigAPIConfiguration: Sendable {
    case direct(apiKey: String)
    case proxy(baseURL: URL)

    nonisolated static func resolved() -> TankerkoenigAPIConfiguration {
        resolved(
            envProxy: ProcessInfo.processInfo.environment["TANKERKOENIG_PROXY_BASE_URL"],
            plistProxy: Bundle.main.object(forInfoDictionaryKey: "TankerkoenigProxyBaseURL") as? String,
            directKey: APIKeys.tankerkoenig
        )
    }

    /// Test-Hook: gleiche Auflösungslogik wie ``resolved()``, aber mit injizierten
    /// Werten. Vermeidet `setenv` / `Bundle`-Mocking in parallelen Test-Suiten.
    nonisolated static func resolved(
        envProxy: String?,
        plistProxy: String?,
        directKey: String
    ) -> TankerkoenigAPIConfiguration {
        if let envURL = normalizedProxyURL(envProxy) {
            return .proxy(baseURL: envURL)
        }
        if let plistURL = normalizedProxyURL(plistProxy) {
            return .proxy(baseURL: plistURL)
        }
        return .direct(apiKey: directKey)
    }

    /// Live-Daten: gültiger direkter Key **oder** konfigurierter Proxy.
    nonisolated static var isLiveAccessConfigured: Bool {
        switch resolved() {
        case .direct(let key):
            APIKeys.isConfiguredTankerkoenigKey(key.trimmingCharacters(in: .whitespacesAndNewlines))
        case .proxy:
            true
        }
    }

    /// Internal für Tests (`@testable import FuelNow`). Gibt die normalisierte URL
    /// zurück — trimmed, http/https-only, ohne trailing slash. Liefert `nil` bei
    /// leeren oder ungültigen Eingaben.
    nonisolated static func normalizedProxyURL(_ raw: String?) -> URL? {
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else { return nil }
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else {
            return nil
        }
        return stripTrailingSlash(from: url)
    }

    nonisolated private static func stripTrailingSlash(from url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }
        if components.path.hasSuffix("/"), components.path.count > 1 {
            components.path.removeLast()
        }
        return components.url ?? url
    }
}
