import SwiftUI

/// Gemeinsame Animationskurven — konsistente Motion-Sprache, gekoppelt an Reduce Motion am Aufrufort.
enum TRMotion {
    static let mapRegionEase = Animation.easeInOut(duration: 0.35)
    static let mapLocateEase = Animation.easeInOut(duration: 0.45)
    /// Offline-Splash und ähnliche Vollflächen-Overlays (bestehendes Timing).
    static let overlayFade = Animation.easeInOut(duration: 0.35)
    /// Ersteinrichtung: sanfte Feder, kurz genug für mehrere gestaffelte Elemente.
    static let onboardingSpring = Animation.spring(response: 0.48, dampingFraction: 0.86)
    /// Start-Overlay: Logo fährt ein.
    static let launchLogoEntrance = Animation.spring(response: 0.52, dampingFraction: 0.84)
    /// Start-Overlay: ganze Fläche weich aus.
    static let launchOverlayExit = Animation.easeOut(duration: 0.3)
}
