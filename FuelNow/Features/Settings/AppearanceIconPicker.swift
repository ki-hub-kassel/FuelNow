import SwiftUI

/// Drei-Segmente-Icon-Picker für die App-Erscheinung (TAN-86).
///
/// Ersetzt den vorherigen `Picker(.menu)` durch eine sichtbare Icon-Reihe (Auto / Hell / Dunkel).
/// Die aktive Auswahl ist als Akzent-Glas-Pille markiert; die drei Segmente teilen sich einen
/// `GlassEffectContainer`, damit kein „Glas-auf-Glas" entsteht (HIG iOS 26). Bei aktiviertem
/// `Reduce Transparency` fällt die Auswahl-Pille auf einen `regularMaterial`-Hintergrund mit
/// Akzent-Outline zurück.
struct AppearanceIconPicker: View {
    @Binding var selection: AppSettings.AppearancePreference

    var body: some View {
        GlassEffectContainer(spacing: TRSpacing.xs) {
            HStack(spacing: TRSpacing.xs) {
                ForEach(AppSettings.AppearancePreference.allCases) { mode in
                    AppearanceIconSegment(
                        mode: mode,
                        isSelected: mode == selection,
                        action: { selection = mode }
                    )
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("settings.appearance.header"))
        .accessibilityValue(Text(selection.localizedTitle))
    }
}

private struct AppearanceIconSegment: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let mode: AppSettings.AppearancePreference
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: mode.iconName)
                .font(.title3)
                .foregroundStyle(isSelected ? TRColors.accentText : TRColors.labelSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .contentShape(RoundedRectangle(cornerRadius: TRRadius.md, style: .continuous))
                .modifier(AppearanceSegmentSurface(isSelected: isSelected))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(mode.localizedTitle))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint(Text("settings.appearance.a11yHint"))
        .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: isSelected)
    }
}

/// Liquid-Glass-Hintergrund eines Segments. Aktiv: Akzent-Tint-Glas; inaktiv: keine Fläche
/// (Form-Row-Hintergrund bleibt sichtbar). Bei Reduce-Transparency: Material + Akzent-Outline.
private struct AppearanceSegmentSurface: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let isSelected: Bool

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: TRRadius.md, style: .continuous)

        if !isSelected {
            content
        } else if reduceTransparency {
            content
                .background(.regularMaterial, in: shape)
                .overlay(shape.strokeBorder(TRColors.accent, lineWidth: 1.5))
        } else {
            content.glassEffect(
                Glass.regular.tint(TRColors.accent.opacity(0.30)).interactive(),
                in: .rect(cornerRadius: TRRadius.md)
            )
        }
    }
}

extension AppSettings.AppearancePreference {
    /// SF-Symbol für die Icon-Picker-Darstellung (HIG-konform, brand-frei).
    var iconName: String {
        switch self {
        case .system:
            "circle.lefthalf.filled"
        case .light:
            "sun.max.fill"
        case .dark:
            "moon.fill"
        }
    }

    /// Lokalisierte Bezeichnung — geteilt für Picker-Label und VoiceOver.
    var localizedTitle: LocalizedStringResource {
        switch self {
        case .system:
            "settings.appearance.system"
        case .light:
            "settings.appearance.light"
        case .dark:
            "settings.appearance.dark"
        }
    }
}

#Preview("Light") {
    AppearancePickerStatefulPreviewWrapper(.system) { binding in
        AppearanceIconPicker(selection: binding)
            .padding()
            .background(TRColors.background)
    }
}

#Preview("Dark") {
    AppearancePickerStatefulPreviewWrapper(.dark) { binding in
        AppearanceIconPicker(selection: binding)
            .padding()
            .background(TRColors.background)
            .preferredColorScheme(.dark)
    }
}

#Preview("Accessibility 3") {
    AppearancePickerStatefulPreviewWrapper(.light) { binding in
        AppearanceIconPicker(selection: binding)
            .padding()
            .background(TRColors.background)
            .environment(\.dynamicTypeSize, .accessibility3)
    }
}

private struct AppearancePickerStatefulPreviewWrapper<Content: View>: View {
    @State private var value: AppSettings.AppearancePreference
    let content: (Binding<AppSettings.AppearancePreference>) -> Content

    init(
        _ initialValue: AppSettings.AppearancePreference,
        @ViewBuilder content: @escaping (Binding<AppSettings.AppearancePreference>) -> Content
    ) {
        _value = State(initialValue: initialValue)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}
