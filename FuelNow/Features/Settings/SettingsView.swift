import StoreKit
import SwiftUI

/// Einstellungen: Präferenzen-Layout (Sektionslabels, Karten-Auswahl, gruppierte Glas-Karte) — weiterhin als Sheet.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(EntitlementManager.self) private var entitlementManager

    @AppStorage(AppSettings.UserDefaultsKey.preferredFuelType) private var preferredFuelRaw = FuelType.e10.rawValue
    @AppStorage(AppSettings.UserDefaultsKey.searchRadiusKm) private var searchRadiusKm = AppSettings.SearchRadius.defaultKm
    @AppStorage(AppSettings.UserDefaultsKey.appearancePreference) private var appearanceRaw = AppSettings.AppearancePreference.system.rawValue

    private var appearanceBinding: Binding<AppSettings.AppearancePreference> {
        Binding(
            get: { AppSettings.AppearancePreference.resolved(storedRaw: appearanceRaw) },
            set: { appearanceRaw = $0.rawValue }
        )
    }

    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var storeAlertMessage: String?

    private var plusYearlyProduct: Product? {
        entitlementManager.products.first { $0.id == SubscriptionConstants.plusYearlyProductID }
    }

    private var isStoreBusy: Bool { isPurchasing || isRestoring }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: TRSpacing.l) {
                    heroHeader

                    fuelSection

                    displayAndRadiusSection

                    favoritesPlaceholderSection

                    plusSection

                    dataSourceSection
                }
                .padding(.horizontal, TRSpacing.m)
                .padding(.top, TRSpacing.s)
                .padding(.bottom, TRSpacing.xxl)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                saveBar
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(TRColors.labelSecondary, TRColors.labelTertiary.opacity(0.35))
                    }
                    .accessibilityLabel("Schließen")
                    .accessibilityHint("Schließt die Einstellungen.")
                }
            }
            .task {
                await entitlementManager.loadProducts()
            }
            .alert(
                Text("settings.plus.alert.title"),
                isPresented: Binding(
                    get: { storeAlertMessage != nil },
                    set: { if !$0 { storeAlertMessage = nil } }
                ),
                actions: {
                    Button("settings.plus.alert.ok", role: .cancel) {
                        storeAlertMessage = nil
                    }
                },
                message: {
                    if let message = storeAlertMessage {
                        Text(message)
                    }
                }
            )
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: TRSpacing.xs) {
            Text("settings.hero.title")
                .font(TRTypography.preferencesHeroTitle())
                .foregroundStyle(TRColors.labelPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("settings.hero.subtitle")
                .font(TRTypography.callout())
                .foregroundStyle(TRColors.labelSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var fuelSection: some View {
        VStack(alignment: .leading, spacing: TRSpacing.s) {
            TRSettingsSectionHeader("settings.section.fuelType")

            VStack(spacing: TRSpacing.s) {
                ForEach(FuelType.allCases) { fuel in
                    FuelGlassOptionRow(
                        fuel: fuel,
                        isSelected: preferredFuelRaw == fuel.rawValue
                    ) {
                        preferredFuelRaw = fuel.rawValue
                    }
                }
            }

            Text("settings.fuel.footer")
                .font(TRTypography.caption())
                .foregroundStyle(TRColors.labelSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var displayAndRadiusSection: some View {
        VStack(alignment: .leading, spacing: TRSpacing.s) {
            TRSettingsSectionHeader("settings.section.displayAndRadius")

            TRGroupedGlassCard {
                VStack(alignment: .leading, spacing: TRSpacing.m) {
                    VStack(alignment: .leading, spacing: TRSpacing.xs) {
                        Text("settings.appearance.header")
                            .font(TRTypography.bodyBold())
                            .foregroundStyle(TRColors.labelPrimary)

                        Picker("", selection: appearanceBinding) {
                            ForEach(AppSettings.AppearancePreference.allCases) { mode in
                                Text(mode.localizedTitle).tag(mode)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        .accessibilityLabel(Text("settings.appearance.header"))
                        .accessibilityHint(Text("settings.appearance.a11yHint"))
                    }

                    Divider()
                        .foregroundStyle(TRColors.separator)

                    VStack(alignment: .leading, spacing: TRSpacing.xs) {
                        HStack {
                            Text("settings.row.radiusTitle")
                                .font(TRTypography.bodyBold())
                                .foregroundStyle(TRColors.labelPrimary)
                            Spacer()
                            Text("\(searchRadiusKm) km")
                                .font(TRTypography.callout())
                                .foregroundStyle(TRColors.labelSecondary)
                        }
                        .accessibilityElement(children: .ignore)

                        Slider(
                            value: Binding(
                                get: { Double(searchRadiusKm) },
                                set: { searchRadiusKm = AppSettings.SearchRadius.clampedKm(sliderValue: $0) }
                            ),
                            in: Double(AppSettings.SearchRadius.minKm)...Double(AppSettings.SearchRadius.maxKm),
                            step: 1
                        )
                        .tint(TRColors.accent)
                        .accessibilityLabel("Suchradius")
                        .accessibilityValue("\(searchRadiusKm) Kilometer")
                    }
                }
            }

            Text("settings.appearance.footer")
                .font(TRTypography.caption())
                .foregroundStyle(TRColors.labelSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("settings.radius.footer")
                .font(TRTypography.caption())
                .foregroundStyle(TRColors.labelSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var favoritesPlaceholderSection: some View {
        VStack(alignment: .leading, spacing: TRSpacing.s) {
            TRSettingsSectionHeader("settings.section.favorites")

            HStack(alignment: .top, spacing: TRSpacing.m) {
                Image(systemName: "fuelpump.fill")
                    .font(.title2)
                    .foregroundStyle(TRColors.accent)
                    .frame(width: 44, height: 44)
                    .background {
                        RoundedRectangle(cornerRadius: TRRadius.md)
                            .fill(TRColors.backgroundSecondary.opacity(0.6))
                    }

                VStack(alignment: .leading, spacing: TRSpacing.xxs) {
                    Text("settings.favorites.empty.title")
                        .font(TRTypography.bodyBold())
                        .foregroundStyle(TRColors.labelPrimary)
                    Text("settings.favorites.empty.body")
                        .font(TRTypography.caption())
                        .foregroundStyle(TRColors.labelSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(TRSpacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .trCardBackground()
        }
    }

    private var plusSection: some View {
        VStack(alignment: .leading, spacing: TRSpacing.s) {
            TRSettingsSectionHeader("settings.section.plus", accent: true)

            VStack(alignment: .leading, spacing: TRSpacing.m) {
                Text("settings.plus.intro")
                    .font(TRTypography.callout())
                    .foregroundStyle(TRColors.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if entitlementManager.isPlusSubscriber {
                    Text("settings.plus.status.active")
                        .font(TRTypography.body())
                } else if let product = plusYearlyProduct {
                    HStack(alignment: .firstTextBaseline, spacing: TRSpacing.xs) {
                        Text(product.displayPrice)
                            .font(TRTypography.title2())
                            .foregroundStyle(TRColors.labelPrimary)
                        Text("settings.plus.perYear")
                            .font(TRTypography.callout())
                            .foregroundStyle(TRColors.labelSecondary)
                    }
                    .accessibilityElement(children: .combine)

                    Button {
                        Task { await subscribePlusYearly() }
                    } label: {
                        Text("settings.plus.subscribe")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.trPrimaryGlass)
                    .disabled(isStoreBusy)
                    .accessibilityHint("Startet den Jahresabo-Kauf über den App Store.")
                } else {
                    Text("settings.plus.priceLoading")
                        .font(TRTypography.callout())
                        .foregroundStyle(TRColors.labelSecondary)
                }

                Button {
                    openURL(Self.manageSubscriptionsURL)
                } label: {
                    Label("settings.plus.manage", systemImage: "creditcard")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.trSoft)
                .accessibilityHint("Öffnet die Abonnementverwaltung deines Apple-ID-Kontos im Browser oder in den Systemeinstellungen.")

                Button {
                    Task { await restorePurchases() }
                } label: {
                    Text("settings.plus.restore")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.trOutline)
                .disabled(isStoreBusy)
                .accessibilityHint("Synchronisiert Käufe mit deinem Apple-ID-Konto.")

                Text("settings.plus.footer")
                    .font(TRTypography.caption())
                    .foregroundStyle(TRColors.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(TRSpacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .trCardBackground()
        }
    }

    private var dataSourceSection: some View {
        VStack(alignment: .leading, spacing: TRSpacing.s) {
            TRSettingsSectionHeader("settings.section.dataSource")

            TRGroupedGlassCard {
                VStack(alignment: .leading, spacing: TRSpacing.s) {
                    Button {
                        openURL(AppSettings.TankerkoenigAttribution.infoURL)
                    } label: {
                        Label("Tankerkönig / MTS-K (CC BY 4.0)", systemImage: "link")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.trSoft)
                    .accessibilityLabel("Tankerkönig und MTS-K, Lizenz CC BY 4.0")
                    .accessibilityHint("Öffnet die Tankerkönig-Website mit Lizenzinformationen.")

                    Text("settings.dataSource.footer")
                        .font(TRTypography.caption())
                        .foregroundStyle(TRColors.labelSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var saveBar: some View {
        VStack(spacing: 0) {
            Divider()
                .foregroundStyle(TRColors.separator)
            Button {
                dismiss()
            } label: {
                Text("settings.done.save")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.trPrimaryGlass)
            .padding(TRSpacing.m)
            .accessibilityHint("Schließt die Einstellungen und übernimmt die Auswahl.")
        }
        .background(.bar)
    }

    @MainActor
    private func subscribePlusYearly() async {
        guard let product = plusYearlyProduct else {
            storeAlertMessage = String(localized: "settings.plus.priceLoading")
            return
        }
        guard !isStoreBusy else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            try await entitlementManager.purchase(product)
        } catch EntitlementManagerError.userCancelled {
            return
        } catch EntitlementManagerError.pending {
            storeAlertMessage = String(localized: "settings.plus.error.pending")
        } catch EntitlementManagerError.unknownPurchaseResult {
            storeAlertMessage = String(localized: "settings.plus.error.generic")
        } catch {
            storeAlertMessage = error.localizedDescription
        }
    }

    @MainActor
    private func restorePurchases() async {
        guard !isStoreBusy else { return }
        isRestoring = true
        defer { isRestoring = false }
        do {
            try await entitlementManager.restorePurchases()
        } catch {
            storeAlertMessage = error.localizedDescription
        }
    }
}

#Preview("Light") {
    SettingsView()
        .environment(EntitlementManager())
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    SettingsView()
        .environment(EntitlementManager())
        .preferredColorScheme(.dark)
}

#Preview("Accessibility 3") {
    SettingsView()
        .environment(EntitlementManager())
        .environment(\.dynamicTypeSize, .accessibility3)
}

private extension SettingsView {
    /// Öffnet die zentrale Apple-Abonnementübersicht (Review-konformes „Manage“).
    static let manageSubscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")!
}

private extension AppSettings.AppearancePreference {
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

// MARK: - Fuel option row

private struct FuelGlassOptionRow: View {
    let fuel: FuelType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: TRSpacing.m) {
                radioView

                VStack(alignment: .leading, spacing: TRSpacing.xxs) {
                    Text(fuel.displayName)
                        .font(TRTypography.bodyBold())
                        .foregroundStyle(TRColors.labelPrimary)

                    if fuel == .e10 {
                        Text("settings.fuel.badge.recommended")
                            .font(TRTypography.captionSmall())
                            .fontWeight(.semibold)
                            .foregroundStyle(TRColors.accent)
                            .padding(.horizontal, TRSpacing.xs)
                            .padding(.vertical, TRSpacing.xxs)
                            .trGlassPill()
                    }
                }

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(TRColors.accent)
                        .accessibilityHidden(true)
                }
            }
            .padding(TRSpacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .trCardBackground()
            .overlay {
                RoundedRectangle(cornerRadius: TRRadius.lg)
                    .strokeBorder(
                        isSelected ? TRColors.accent : TRColors.separator.opacity(0.65),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(fuel.displayName))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint(Text("settings.fuel.selectHint"))
    }

    private var radioView: some View {
        ZStack {
            Circle()
                .strokeBorder(TRColors.labelSecondary, lineWidth: 1.5)
                .frame(width: 22, height: 22)
            if isSelected {
                Circle()
                    .fill(TRColors.accent)
                    .frame(width: 11, height: 11)
            }
        }
        .accessibilityHidden(true)
    }
}
