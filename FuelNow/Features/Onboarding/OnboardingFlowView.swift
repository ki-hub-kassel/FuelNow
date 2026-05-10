import SwiftUI

private enum OnboardingPhase: Int {
    case welcomeFuel = 0
    case location = 1
}

/// Zweistufiges Ersteinrichten: Willkommen + Kraftstoffsorte → Standortfreigabe.
struct OnboardingFlowView: View {
    let onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(AppSettings.UserDefaultsKey.preferredFuelType) private var preferredFuelRaw = FuelType.e10.rawValue
    @State private var phase = OnboardingPhase.welcomeFuel

    private var fuelBinding: Binding<FuelType> {
        Binding(
            get: { FuelType(rawValue: preferredFuelRaw) ?? .e10 },
            set: { preferredFuelRaw = $0.rawValue }
        )
    }

    var body: some View {
        ZStack {
            onboardingBackdrop
                .ignoresSafeArea()

            VStack(spacing: 0) {
                progressIndicator
                    .padding(.horizontal, TRSpacing.m)
                    .padding(.top, TRSpacing.m)
                    .padding(.bottom, TRSpacing.s)
                    .accessibilityHidden(true)

                stepContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                bottomChrome
                    .padding(TRSpacing.m)
                    .animation(reduceMotion ? nil : TRMotion.onboardingSpring, value: phase)
            }
        }
    }

    private var onboardingBackdrop: some View {
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
    }

    private var progressIndicator: some View {
        HStack(spacing: 6) {
            progressSegment(isActive: phase == .welcomeFuel, isComplete: phase == .location)
            progressSegment(isActive: phase == .location, isComplete: false)
        }
        .frame(height: 4)
    }

    private func progressSegment(isActive: Bool, isComplete: Bool) -> some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(segmentFill(isActive: isActive, isComplete: isComplete))
            .frame(maxWidth: .infinity)
    }

    private func segmentFill(isActive: Bool, isComplete: Bool) -> Color {
        if isActive { return TRColors.accent }
        if isComplete { return TRColors.accentMuted }
        return TRColors.separator.opacity(0.45)
    }

    private var stepContent: some View {
        Group {
            switch phase {
            case .welcomeFuel:
                OnboardingWelcomeFuelStep(fuelSelection: fuelBinding)
            case .location:
                OnboardingLocationStep()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .id(phase)
        .transition(stepTransition)
    }

    private var stepTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }
        return .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    @ViewBuilder
    private var bottomChrome: some View {
        switch phase {
        case .welcomeFuel:
            Button(action: advanceToLocation, label: {
                Text("onboarding.action.next")
                    .frame(maxWidth: .infinity)
            })
            .buttonStyle(.trPrimaryGlass)
            .accessibilityHint(String(localized: "onboarding.action.next.hint"))
        case .location:
            VStack(spacing: TRSpacing.s) {
                Text("onboarding.location.footer")
                    .font(TRTypography.caption())
                    .foregroundStyle(TRColors.labelTertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Button(action: finish, label: {
                    Text("onboarding.location.button")
                        .frame(maxWidth: .infinity)
                })
                .buttonStyle(.trPrimaryGlass)
                .accessibilityHint(String(localized: "onboarding.location.button.hint"))
            }
        }
    }

    private func advanceToLocation() {
        var transaction = Transaction()
        transaction.animation = reduceMotion ? nil : TRMotion.onboardingSpring
        withTransaction(transaction) {
            phase = .location
        }
    }

    private func finish() {
        onFinished()
    }
}
