import SwiftUI

/// Kurze animierte Übergangsfläche nach dem statischen System-Launch (Logo + Hintergrund wie Onboarding).
/// iOS-`UILaunchScreen` kann nicht animieren; die Bewegung passiert hier bis `onComplete` die Fläche entfernt.
struct AnimatedLaunchOverlay: View {
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
        LinearGradient(
            colors: [
                TRColors.background,
                TRColors.backgroundSecondary.opacity(0.92),
                TRColors.background.opacity(0.98),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            RadialGradient(
                colors: [
                    TRColors.accentMuted.opacity(0.22),
                    Color.clear,
                ],
                center: .topTrailing,
                startRadius: 40,
                endRadius: 420
            )
        )
        .ignoresSafeArea()
    }

    private var logo: some View {
        Image(.appLogo)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 108, height: 108)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
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
                try? await Task.sleep(for: .milliseconds(140))
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
            try? await Task.sleep(for: .milliseconds(340))
            withAnimation(TRMotion.launchOverlayExit) {
                overlayOpaque = false
            }
            try? await Task.sleep(for: .milliseconds(320))
            onComplete()
        }
    }
}
