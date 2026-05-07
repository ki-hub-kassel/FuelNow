import Foundation

enum APIKeys {
    private static let placeholder = ""

    /// Repo-Platzhalter-UUID — gilt nicht als konfigurierter Key (siehe kopiertes `APIKeys.swift`).
    static let tankerkoenigRepositoryPlaceholderUUID = "15d034ae-e9bc-016b-ad9e-ca5a87e4cc5a"

    /// Tankerkönig-UUID. **Nie** echten Key committen.
    ///
    /// **Default-Pfad (TAN-92, Debug + Release):** Die App läuft über den
    /// **Vercel Edge Function Proxy** (`tankerkoenig-proxy/`); die Proxy-URL liegt in
    /// `FuelNow/Info.plist` unter `TankerkoenigProxyBaseURL`, der echte Key bleibt
    /// serverseitig. ``TankerkoenigAPIConfiguration/resolved()`` schaltet automatisch
    /// in den Proxy-Modus, sodass diese Resolver hier dann **gar nicht** aufgerufen
    /// werden — `tankerkoenig` darf leer bleiben.
    ///
    /// **Direct-Modus (Notnagel, nur ohne Proxy nötig):** wird hier in dieser
    /// Reihenfolge resolved. Sinnvoll z. B. wenn der Proxy gerade offline ist oder
    /// du gegen einen alternativen Key testen willst.
    /// 1. **Umgebungsvariable** `TANKERKOENIG_API_KEY` (Xcode Scheme → Run → Environment Variables).
    /// 2. **Dateipfad** `TANKERKOENIG_API_KEY_FILE` = absoluter Pfad zu einer Textdatei (eine Zeile Key).
    /// 3. Nur **DEBUG / Simulator:** `~/.fuelnow/tankerkoenig-api-key` auf dem Mac
    ///    (`mkdir -p ~/.fuelnow && echo <KEY> > ~/.fuelnow/tankerkoenig-api-key`).
    ///    Im Simulator wird das über `SIMULATOR_HOST_HOME` gelesen.
    /// 4. Nur **DEBUG:** UserDefaults-Schlüssel `dev.fuelnow.tankerkoenigAPIKey` (z. B. via `defaults write`).
    ///
    /// Beantragung Key: Linear **TAN-72**. Proxy-Setup: Linear **TAN-92**.
    static var tankerkoenig: String {
        if let key = resolvedFromEnvironmentVariable() { return key }
        if let key = resolvedFromExplicitKeyFile() { return key }
        #if DEBUG
        if let key = resolvedFromSimulatorHostHomeKeyFile() { return key }
        if let key = resolvedFromUserDefaults() { return key }
        #endif
        return placeholder
    }

    static func isConfiguredTankerkoenigKey(_ raw: String) -> Bool {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return false }
        guard t != "PASTE_YOUR_KEY_HERE" else { return false }
        return t.caseInsensitiveCompare(tankerkoenigRepositoryPlaceholderUUID) != .orderedSame
    }

    static var isTankerkoenigKeyConfiguredForRequests: Bool {
        isConfiguredTankerkoenigKey(tankerkoenig)
    }

    private static func resolvedFromEnvironmentVariable() -> String? {
        guard let raw = ProcessInfo.processInfo.environment["TANKERKOENIG_API_KEY"] else { return nil }
        return normalizedKey(raw)
    }

    private static func resolvedFromExplicitKeyFile() -> String? {
        guard let path = ProcessInfo.processInfo.environment["TANKERKOENIG_API_KEY_FILE"],
              !path.isEmpty else { return nil }
        return normalizedKey(readKeyFile(at: URL(fileURLWithPath: path, isDirectory: false)))
    }

    #if DEBUG
    private static func resolvedFromSimulatorHostHomeKeyFile() -> String? {
        #if targetEnvironment(simulator)
        guard let hostHome = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"],
              !hostHome.isEmpty else { return nil }
        let url = URL(fileURLWithPath: hostHome, isDirectory: true)
            .appendingPathComponent(".fuelnow", isDirectory: true)
            .appendingPathComponent("tankerkoenig-api-key", isDirectory: false)
        return normalizedKey(readKeyFile(at: url))
        #else
        return nil
        #endif
    }

    private static func resolvedFromUserDefaults() -> String? {
        guard let raw = UserDefaults.standard.string(forKey: "dev.fuelnow.tankerkoenigAPIKey") else { return nil }
        return normalizedKey(raw)
    }
    #endif

    private static func readKeyFile(at url: URL) -> String? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    private static func normalizedKey(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines.union(.newlines))
        guard !t.isEmpty, t != placeholder else { return nil }
        return t
    }

    #if DEBUG
    static func warnIfPlaceholderActive() {
        guard !TankerkoenigAPIConfiguration.isLiveAccessConfigured else { return }
        print(
            "FuelNow: Weder Tankerkönig-Proxy (Info.plist `TankerkoenigProxyBaseURL` / "
                + "Env `TANKERKOENIG_PROXY_BASE_URL`) noch Direct-Key (Env `TANKERKOENIG_API_KEY` "
                + "bzw. `~/.fuelnow/tankerkoenig-api-key` im Simulator) gesetzt — Live-Daten "
                + "schlagen mit `missingAPIKey` fehl. Standard-Setup: Vercel-Proxy aus "
                + "tankerkoenig-proxy/ deployen und URL in Info.plist eintragen (Linear TAN-92)."
        )
    }
    #endif
}
