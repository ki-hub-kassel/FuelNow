import SwiftUI

struct ContentView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: TRSpacing.l) {
                Image(.brandGlyph)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 56, height: 56)
                    .foregroundStyle(TRColors.accent)

                Text("TankRadar")
                    .font(TRTypography.title())
                    .foregroundStyle(TRColors.labelPrimary)

                Text("Design tokens · TAN-74 + TAN-75")
                    .font(TRTypography.subheadline())
                    .foregroundStyle(TRColors.labelSecondary)

                Text("Glass Pill")
                    .font(TRTypography.caption())
                    .padding(.horizontal, TRSpacing.m)
                    .padding(.vertical, TRSpacing.xs)
                    .trGlassPill(interactive: false)

                VStack(alignment: .leading, spacing: TRSpacing.xs) {
                    Text("Beispiel-Karte")
                        .font(TRTypography.headline())
                        .foregroundStyle(TRColors.labelPrimary)
                    Text("Modifier `trCardBackground` für Listen und Sheets.")
                        .font(TRTypography.callout())
                        .foregroundStyle(TRColors.labelSecondary)
                }
                .padding(TRSpacing.m)
                .frame(maxWidth: .infinity, alignment: .leading)
                .trCardBackground()

                GlassEffectContainer(spacing: TRSpacing.xs) {
                    VStack(spacing: TRSpacing.xs) {
                        Button("Primary Glass") {}
                            .buttonStyle(.trPrimaryGlass)
                        Button("Soft Glass") {}
                            .buttonStyle(.trSoft)
                        Button("Outline") {}
                            .buttonStyle(.trOutline)
                    }
                }
            }
            .padding(TRSpacing.m)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TRColors.background)
    }
}

#Preview {
    ContentView()
        .environment(LocationService())
}
