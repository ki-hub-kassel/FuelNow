import StoreKit
import SwiftUI

/// Einstellungen: Spritart, Suchradius (`@AppStorage`), FuelNow Plus und Pflichtattribution — im TR-Kartenlayout wie das Tankstellen-Detail.
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
                VStack(alignment: .leading, spacing: TRSpacing.m) {
                    TRSectionCard(title: "Spritart") {
                        VStack(alignment: .leading, spacing: TRSpacing.s) {
                            Picker("", selection: $preferredFuelRaw) {
                                ForEach(FuelType.allCases) { fuel in
                                    Text(fuel.displayName).tag(fuel.rawValue)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.segmented)
                            .accessibilityLabel("Spritart")
                            .accessibilityHint("Bestimmt, welche Sorte auf der Karte für Preise verwendet wird.")

                            Text("Auf der Karte wird der Preis für die gewählte Sorte angezeigt.")
                                .font(TRTypography.caption())
                                .foregroundStyle(TRColors.labelSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    TRSectionCard(title: "Suchradius") {
                        VStack(alignment: .leading, spacing: TRSpacing.s) {
                            HStack {
                                Text("\(searchRadiusKm) km")
                                    .font(TRTypography.bodyBold())
                                    .foregroundStyle(TRColors.labelPrimary)
                                Spacer()
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

                            Text("Tankstellen werden bis zu diesem Radius geladen (max. 25 km, entsprechend Tankerkönig).")
                                .font(TRTypography.caption())
                                .foregroundStyle(TRColors.labelSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    TRSectionCard(title: String(localized: "settings.appearance.header")) {
                        VStack(alignment: .leading, spacing: TRSpacing.s) {
                            Picker("", selection: appearanceBinding) {
                                ForEach(AppSettings.AppearancePreference.allCases) { mode in
                                    Text(mode.localizedTitle).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .accessibilityLabel(Text("settings.appearance.header"))
                            .accessibilityHint(Text("settings.appearance.a11yHint"))

                            Text("settings.appearance.footer")
                                .font(TRTypography.caption())
                                .foregroundStyle(TRColors.labelSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    TRSectionCard(title: String(localized: "settings.plus.header"), accentTitle: true) {
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
                    }

                    TRSectionCard(title: "Datenquelle") {
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

                            Text("Datenquelle und Pflichtattribution für die Nutzung der Tankerkönig-API.")
                                .font(TRTypography.caption())
                                .foregroundStyle(TRColors.labelSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(TRSpacing.m)
                .padding(.bottom, TRSpacing.l)
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
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
