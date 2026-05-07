import SwiftUI
import WhatsNewKit

struct ContentView: View {
    @Environment(LocationService.self) private var locationService
    @AppStorage(AppSettings.UserDefaultsKey.hasCompletedOnboarding)
    private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                NavigationStack {
                    MapScreen()
                }
                .whatsNewSheet()
            } else {
                OnboardingScreen(
                    onContinue: {
                        hasCompletedOnboarding = true
                        locationService.requestWhenInUseAuthorizationIfNeeded()
                    }
                )
            }
        }
    }
}

private struct OnboardingScreen: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: TRSpacing.l) {
            Image(.appLogo)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 96, height: 96)
                .clipShape(.rect(cornerRadius: 22, style: .continuous))
                .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 6)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, TRSpacing.s)
                .accessibilityHidden(true)

            Text("Willkommen bei FuelNow")
                .font(TRTypography.title())
                .foregroundStyle(TRColors.labelPrimary)

            Text("Finde schnell die passende Tankstelle in deiner Nähe.")
                .font(TRTypography.body())
                .foregroundStyle(TRColors.labelSecondary)

            VStack(alignment: .leading, spacing: TRSpacing.m) {
                OnboardingBullet(
                    icon: "location.fill",
                    title: "Live in deiner Umgebung",
                    detail: "Zeigt dir offene Tankstellen mit Preisen auf einen Blick."
                )
                OnboardingBullet(
                    icon: "slider.horizontal.3",
                    title: "Deine Kraftstoffsorte",
                    detail: "Preisfokus für E5, E10 oder Diesel nach deiner Auswahl."
                )
                OnboardingBullet(
                    icon: "arrow.triangle.turn.up.right.diamond.fill",
                    title: "Direkt zur Navigation",
                    detail: "Starte die Route zur Tankstelle direkt in Apple Maps."
                )
            }
            .padding(.vertical, TRSpacing.s)

            Spacer()

            VStack(spacing: TRSpacing.s) {
                Text("FuelNow benötigt deinen Standort, um Tankstellen in deiner Nähe zu finden.")
                    .font(TRTypography.caption())
                    .foregroundStyle(TRColors.labelTertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Button(action: onContinue) {
                    Text("Standortzugriff erlauben")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.trPrimaryGlass)
                .accessibilityHint("Fordert den Standortzugriff an und startet FuelNow.")
            }
        }
        .padding(TRSpacing.m)
    }
}

private struct OnboardingBullet: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: TRSpacing.s) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(TRColors.accentText)
                .frame(width: 22)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: TRSpacing.xxs) {
                Text(title)
                    .font(TRTypography.bodyBold())
                    .foregroundStyle(TRColors.labelPrimary)
                Text(detail)
                    .font(TRTypography.callout())
                    .foregroundStyle(TRColors.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ContentView()
        .environment(LocationService())
        .environment(StationStore())
        .environment(EntitlementManager())
        .environment(NetworkMonitor())
        .environment(MapDeepLinkStore(defaults: UserDefaults(suiteName: "tr.preview.ContentView.deeplink")!))
}
