import Testing
@testable import FuelNow

/// Unit-Tests für die reine CarPlay-Routing-Entscheidung (TAN-56). Bewusst frei
/// von `CarPlay`/`UIKit` — der Scene-Delegate selbst lebt erst im CarPlay-
/// Simulator (TAN-59 / Sandbox-QA).
struct CarPlayRoutingPolicyTests {
    @Test("Plus aktiv → POI-Pfad (.plus)")
    func unlockedRoutesToPlus() {
        #expect(
            CarPlayRoutingPolicy.route(
                forCarPlayUnlocked: true,
                isPlusUIEnabled: true,
                isCarPlayCapabilityEnabled: true
            ) == .plus
        )
    }

    @Test("Kein Plus → ehrlicher Limited-Pfad (.limited), wenn Plus-UI verkauft wird")
    func lockedRoutesToLimitedWhenPlusUISellsSubscription() {
        #expect(
            CarPlayRoutingPolicy.route(
                forCarPlayUnlocked: false,
                isPlusUIEnabled: true,
                isCarPlayCapabilityEnabled: true
            ) == .limited
        )
    }

    @Test("Ohne Plus-UI aber mit CarPlay-Capability → immer POI (.plus), auch ohne Abo")
    func plusUIHiddenCarPlayEnabled_alwaysPlusForVerificationBuilds() {
        #expect(
            CarPlayRoutingPolicy.route(
                forCarPlayUnlocked: false,
                isPlusUIEnabled: false,
                isCarPlayCapabilityEnabled: true
            ) == .plus
        )
        #expect(
            CarPlayRoutingPolicy.route(
                forCarPlayUnlocked: true,
                isPlusUIEnabled: false,
                isCarPlayCapabilityEnabled: true
            ) == .plus
        )
    }

    @Test("Routing ist deterministisch & idempotent (kein Hidden State)")
    func routingIsPureFunction() {
        #expect(
            CarPlayRoutingPolicy.route(
                forCarPlayUnlocked: true,
                isPlusUIEnabled: true,
                isCarPlayCapabilityEnabled: true
            )
                == CarPlayRoutingPolicy.route(
                    forCarPlayUnlocked: true,
                    isPlusUIEnabled: true,
                    isCarPlayCapabilityEnabled: true
                )
        )
        #expect(
            CarPlayRoutingPolicy.route(
                forCarPlayUnlocked: false,
                isPlusUIEnabled: true,
                isCarPlayCapabilityEnabled: true
            )
                == CarPlayRoutingPolicy.route(
                    forCarPlayUnlocked: false,
                    isPlusUIEnabled: true,
                    isCarPlayCapabilityEnabled: true
                )
        )
        #expect(
            CarPlayRoutingPolicy.route(
                forCarPlayUnlocked: true,
                isPlusUIEnabled: true,
                isCarPlayCapabilityEnabled: true
            )
                != CarPlayRoutingPolicy.route(
                    forCarPlayUnlocked: false,
                    isPlusUIEnabled: true,
                    isCarPlayCapabilityEnabled: true
                )
        )
    }
}
