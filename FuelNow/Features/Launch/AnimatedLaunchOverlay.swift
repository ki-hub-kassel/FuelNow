import SwiftUI

/// Kurze animierte Übergangsfläche nach dem statischen System-Launch (Logo + Hintergrund wie Onboarding).
/// iOS-`UILaunchScreen` kann nicht animieren; die Bewegung passiert hier bis `onComplete` die Fläche entfernt.
struct AnimatedLaunchOverlay: View {
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var logoPresented = false
    @State private var overlayOpaque = true

    private var isUITest: Bool {
        ProcessInfo.processInfo.environment["UITESTING"] == "1"
    }

    var body: some View {
        ZStack {
            launchBackground
            logo
        }
        .opacity(overlayOpaque ? 1 : 0)
        .allowsHitTesting(overlayOpaque)
        .accessibilityHidden(true)
        .onAppear(perform: runSequence)
    }

    private var launchBackground: some View {
        ZStack {
            TRColors.background
            if colorScheme == .light {
                LinearGradient(
                    colors: [
                        TRColors.accentMuted.opacity(0.52),
                        TRColors.accentMuted.opacity(0.22),
                        Color.clear,
                    ],
                    startPoint: .topLeading,
                    endPoint: UnitPoint(x: 0.72, y: 0.58)
                )
            }
            LinearGradient(
                colors: launchGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [
                    TRColors.accentMuted.opacity(colorScheme == .light ? 0.5 : 0.22),
                    Color.clear,
                ],
                center: .topTrailing,
                startRadius: 40,
                endRadius: 420
            )
        }
        .ignoresSafeArea()
    }

    /// Light: kräftigerer Teal-Nebel (zusätzliche Schicht oben links) + Verlauf, damit Store-Screens
    /// und heller Simulator nicht wie „weißes Blatt mit ausgeblichenem Icon“ wirken.
    private var launchGradientColors: [Color] {
        if colorScheme == .light {
            [
                TRColors.backgroundTertiary,
                TRColors.background,
                TRColors.accentMuted.opacity(0.22),
            ]
        } else {
            [
                TRColors.background,
                TRColors.backgroundSecondary.opacity(0.92),
                TRColors.background.opacity(0.98),
            ]
        }
    }

    private var logo: some View {
        Image(.appLogo)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 108, height: 108)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(TRColors.separator.opacity(colorScheme == .light ? 0.55 : 0.35), lineWidth: 1)
            )
            .shadow(
                color: .black.opacity(colorScheme == .light ? 0.45 : 0.3),
                radius: colorScheme == .light ? 20 : 12,
                x: 0,
                y: colorScheme == .light ? 10 : 6
            )
            .scaleEffect(logoPresented ? 1 : 0.86)
            .opacity(logoPresented ? 1 : 0)
    }

    private func runSequence() {
        if isUITest {
            onComplete()
            return
        }
        if reduceMotion {
            logoPresented = true
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(1140))
                overlayOpaque = false
                try? await Task.sleep(for: .milliseconds(40))
                onComplete()
            }
            return
        }
        Task { @MainActor in
            withAnimation(TRMotion.launchLogoEntrance) {
                logoPresented = true
            }
            try? await Task.sleep(for: .milliseconds(1340))
            withAnimation(TRMotion.launchOverlayExit) {
                overlayOpaque = false
            }
            try? await Task.sleep(for: .milliseconds(320))
            onComplete()
        }
    }
}
