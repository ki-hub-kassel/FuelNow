import Foundation
import Testing
@testable import FuelNow

@Suite("TankerkoenigAPIConfiguration")
struct TankerkoenigAPIConfigurationTests {
    // MARK: - normalizedProxyURL

    @Test func normalizedProxyURLAcceptsHTTPS() throws {
        let url = try #require(TankerkoenigAPIConfiguration.normalizedProxyURL("https://fuelnow-proxy.vercel.app"))
        #expect(url.absoluteString == "https://fuelnow-proxy.vercel.app")
    }

    @Test func normalizedProxyURLAppendsTankerkoenigPathsWithoutDoubleSlash() throws {
        // Der Client baut im Proxy-Modus `<base>/api/json/list` (TAN-92 — Vercel Edge
        // Function direkt, ohne `.php`, weil Vercel Firewall `.php`-Pfade als Bot-Scan blockt).
        // Sowohl `https://host` als auch `https://host/` müssen einen Single-Slash-Pfad liefern.
        let bareURL = try #require(TankerkoenigAPIConfiguration.normalizedProxyURL("https://host.example.com"))
        let trailingURL = try #require(TankerkoenigAPIConfiguration.normalizedProxyURL("https://host.example.com/"))
        let bareJoined = bareURL
            .appendingPathComponent("api")
            .appendingPathComponent("json")
            .appendingPathComponent("list")
            .absoluteString
        let trailingJoined = trailingURL
            .appendingPathComponent("api")
            .appendingPathComponent("json")
            .appendingPathComponent("list")
            .absoluteString
        #expect(bareJoined == "https://host.example.com/api/json/list")
        #expect(trailingJoined == "https://host.example.com/api/json/list")
    }

    @Test func normalizedProxyURLAcceptsHTTPForLocalDev() throws {
        let url = try #require(TankerkoenigAPIConfiguration.normalizedProxyURL("http://localhost:3000"))
        #expect(url.absoluteString == "http://localhost:3000")
    }

    @Test func normalizedProxyURLTrimsWhitespace() throws {
        let url = try #require(TankerkoenigAPIConfiguration.normalizedProxyURL("  https://example.com  \n"))
        #expect(url.absoluteString == "https://example.com")
    }

    @Test func normalizedProxyURLPreservesNonRootPath() throws {
        let url = try #require(TankerkoenigAPIConfiguration.normalizedProxyURL("https://example.com/proxy/"))
        #expect(url.absoluteString == "https://example.com/proxy")
    }

    @Test func normalizedProxyURLKeepsRootSlashOnly() throws {
        // Only path segments beyond "/" get trimmed; the bare root slash is fine.
        let url = try #require(TankerkoenigAPIConfiguration.normalizedProxyURL("https://example.com/"))
        // URL canonicalization may keep or drop the slash; both are valid for our use.
        #expect(url.absoluteString == "https://example.com" || url.absoluteString == "https://example.com/")
    }

    @Test func normalizedProxyURLRejectsEmptyAndWhitespaceOnly() {
        #expect(TankerkoenigAPIConfiguration.normalizedProxyURL(nil) == nil)
        #expect(TankerkoenigAPIConfiguration.normalizedProxyURL("") == nil)
        #expect(TankerkoenigAPIConfiguration.normalizedProxyURL("   ") == nil)
        #expect(TankerkoenigAPIConfiguration.normalizedProxyURL("\n\t") == nil)
    }

    @Test func normalizedProxyURLRejectsNonHTTPSchemes() {
        #expect(TankerkoenigAPIConfiguration.normalizedProxyURL("ftp://example.com") == nil)
        #expect(TankerkoenigAPIConfiguration.normalizedProxyURL("file:///tmp/data") == nil)
        #expect(TankerkoenigAPIConfiguration.normalizedProxyURL("javascript:alert(1)") == nil)
    }

    @Test func normalizedProxyURLRejectsMissingScheme() {
        #expect(TankerkoenigAPIConfiguration.normalizedProxyURL("example.com") == nil)
    }

    // MARK: - resolved(envProxy:plistProxy:directKey:)

    @Test func resolvedPrefersEnvironmentProxyOverPlist() {
        let configuration = TankerkoenigAPIConfiguration.resolved(
            envProxy: "https://env-proxy.example.com",
            plistProxy: "https://plist-proxy.example.com",
            directKey: "ignored-key"
        )

        guard case .proxy(let baseURL) = configuration else {
            Issue.record("Expected proxy mode, got \(configuration)")
            return
        }
        #expect(baseURL.absoluteString == "https://env-proxy.example.com")
    }

    @Test func resolvedFallsBackToPlistProxyWhenEnvMissing() {
        let configuration = TankerkoenigAPIConfiguration.resolved(
            envProxy: nil,
            plistProxy: "https://plist-proxy.example.com",
            directKey: "ignored-key"
        )

        guard case .proxy(let baseURL) = configuration else {
            Issue.record("Expected proxy mode, got \(configuration)")
            return
        }
        #expect(baseURL.absoluteString == "https://plist-proxy.example.com")
    }

    @Test func resolvedFallsBackToPlistProxyWhenEnvIsEmpty() {
        let configuration = TankerkoenigAPIConfiguration.resolved(
            envProxy: "   ",
            plistProxy: "https://plist-proxy.example.com",
            directKey: "ignored-key"
        )

        guard case .proxy(let baseURL) = configuration else {
            Issue.record("Expected proxy mode, got \(configuration)")
            return
        }
        #expect(baseURL.absoluteString == "https://plist-proxy.example.com")
    }

    @Test func resolvedFallsBackToDirectKeyWhenNoProxyConfigured() {
        let configuration = TankerkoenigAPIConfiguration.resolved(
            envProxy: nil,
            plistProxy: nil,
            directKey: "abc-direct-key"
        )

        guard case .direct(let key) = configuration else {
            Issue.record("Expected direct mode, got \(configuration)")
            return
        }
        #expect(key == "abc-direct-key")
    }

    @Test func resolvedIgnoresInvalidEnvProxyAndUsesPlist() {
        let configuration = TankerkoenigAPIConfiguration.resolved(
            envProxy: "ftp://nope.example.com",
            plistProxy: "https://plist-proxy.example.com",
            directKey: "ignored-key"
        )

        guard case .proxy(let baseURL) = configuration else {
            Issue.record("Expected proxy mode, got \(configuration)")
            return
        }
        #expect(baseURL.absoluteString == "https://plist-proxy.example.com")
    }

    @Test func resolvedIgnoresInvalidPlistProxyAndUsesDirect() {
        let configuration = TankerkoenigAPIConfiguration.resolved(
            envProxy: nil,
            plistProxy: "not-a-url",
            directKey: "fallback-key"
        )

        guard case .direct(let key) = configuration else {
            Issue.record("Expected direct mode, got \(configuration)")
            return
        }
        #expect(key == "fallback-key")
    }
}
