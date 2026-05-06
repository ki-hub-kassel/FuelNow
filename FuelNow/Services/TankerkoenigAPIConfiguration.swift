import Foundation

/// Entscheidet, ob Tankerkönig **direkt** (mit Client-Key) oder über einen **HTTPS-Proxy** erreicht wird.
///
/// **Proxy (empfohlen für App-Store-Builds):** Der echte API-Key liegt nur auf dem Server. Die App ruft z. B.
/// `https://ihr-host/json/list.php?lat=…&lng=…&rad=…&type=all&sort=dist` **ohne** `apikey` auf;
/// der Proxy setzt `apikey` beim Weiterleiten an `creativecommons.tankerkoenig.de` — weiterhin **on-demand**
/// pro Nutzeraktion (kein Massen-Mirror; siehe `docs/TANKERKOENIG_CACHING.md`).
///
/// **Konfiguration (Reihenfolge):**
/// 1. Umgebungsvariable `TANKERKOENIG_PROXY_BASE_URL` — z. B. Xcode Scheme oder CI (überschreibt Info.plist).
/// 2. Info.plist-Schlüssel `TankerkoenigProxyBaseURL` — z. B. Release nur per Xcode Build Setting / nicht versionierte Overrides.
///
/// Ist kein Proxy gesetzt, gilt der **direkte** Modus mit ``APIKeys/tankerkoenig``.
enum TankerkoenigAPIConfiguration: Sendable {
    case direct(apiKey: String)
    case proxy(baseURL: URL)

    nonisolated static func resolved() -> TankerkoenigAPIConfiguration {
        if let base = resolveProxyBaseURL() {
            return .proxy(baseURL: base)
        }
        return .direct(apiKey: APIKeys.tankerkoenig)
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

    nonisolated private static func resolveProxyBaseURL() -> URL? {
        if let url = normalizedProxyURL(ProcessInfo.processInfo.environment["TANKERKOENIG_PROXY_BASE_URL"]) {
            return url
        }
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "TankerkoenigProxyBaseURL") as? String else {
            return nil
        }
        return normalizedProxyURL(raw)
    }

    nonisolated private static func normalizedProxyURL(_ raw: String?) -> URL? {
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else { return nil }
        guard let url = URL(string: trimmed), let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
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
