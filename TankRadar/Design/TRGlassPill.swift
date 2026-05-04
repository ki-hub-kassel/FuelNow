import SwiftUI

extension View {
    /// Kompakte Glas-Pille (z. B. Badges, Chips).
    func trGlassPill(interactive: Bool = false) -> some View {
        let style = interactive ? Glass.regular.interactive() : Glass.regular
        return glassEffect(style, in: .capsule)
    }
}
