import SwiftUI

extension View {
    /// Standard-Kartenfläche mit Liquid Glass und abgerundeten Ecken.
    func trCardBackground(cornerRadius: CGFloat = TRRadius.lg) -> some View {
        glassEffect(Glass.regular, in: .rect(cornerRadius: cornerRadius))
    }
}
