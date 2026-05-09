import SwiftUI
#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

/// Zentraler Einstiegspunkt fuer haptisches Feedback.
///
/// **SwiftUI-Pfad (bevorzugt):** Views nutzen den `adaptiveSensoryFeedback`-Modifier mit einem
/// monoton steigenden Trigger (oder einem `Equatable`-State). Der Modifier respektiert
/// `accessibilityReduceMotion` — analog zu `LocateMeButton`, das diese Konvention im Repo
/// etabliert hat.
///
/// **Imperativer Pfad:** Fuer Closures, die nicht im SwiftUI-Body laufen (z. B. `.task`-Result
/// von `PlusPurchaseController`, App-Lifecycle-Coordinator) bietet `Haptics` direkte
/// `tap` / `selection` / `notify`-Funktionen. Die imperativen Calls respektieren ebenfalls
/// `UIAccessibility.isReduceMotionEnabled` und sind no-ops auf Plattformen ohne UIKit
/// (watchOS, Mac-Catalyst etc.).
enum Haptics {}

#if canImport(UIKit) && !os(watchOS)

@MainActor
extension Haptics {
    /// Leichter bis schwerer Tap-Akzent (Default: `.light`).
    static func tap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    /// "Tick" beim Wechsel zwischen diskreten Auswahlen (Picker, Segmented Control).
    static func selection() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    /// Aktions-Resultat: `.success` / `.warning` / `.error`.
    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}

#else

extension Haptics {
    static func tap(_ style: Int = 0) {}
    static func selection() {}
    static func notify(_ type: Int = 0) {}
}

#endif

extension View {
    /// Bindet `sensoryFeedback` an einen Trigger und respektiert `accessibilityReduceMotion`.
    /// Stiltreu zum bestehenden `LocateMeButton`-Pattern.
    func adaptiveSensoryFeedback(
        _ feedback: SensoryFeedback,
        trigger: some Equatable
    ) -> some View {
        modifier(AdaptiveSensoryFeedbackModifier(feedback: feedback, trigger: trigger))
    }
}

private struct AdaptiveSensoryFeedbackModifier<Trigger: Equatable>: ViewModifier {
    let feedback: SensoryFeedback
    let trigger: Trigger

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.sensoryFeedback(feedback, trigger: trigger)
        }
    }
}
