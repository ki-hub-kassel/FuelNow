import StoreKit
import SwiftUI

/// Einstellungen: Spritart, Suchradius (`@AppStorage`) und Pflichtattribution Tankerkönig (CC BY).
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
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
            Form {
                Section {
                    Picker("", selection: $preferredFuelRaw) {
                        ForEach(FuelType.allCases) { fuel in
                            Text(fuel.displayName).tag(fuel.rawValue)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Spritart")
                    .accessibilityHint("Bestimmt, welche Sorte auf der Karte für Preise verwendet wird.")
                } header: {
                    Text("Spritart")
                } footer: {
                    Text("Auf der Karte wird der Preis für die gewählte Sorte angezeigt.")
                }

                Section {
                    VStack(alignment: .leading, spacing: TRSpacing.s) {
                        HStack {
                            Text("Suchradius")
                                .font(TRTypography.body())
                            Spacer()
                            Text("\(searchRadiusKm) km")
                                .font(TRTypography.callout())
                                .foregroundStyle(TRColors.labelSecondary)
                                .accessibilityHidden(true)
                        }
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
                } footer: {
                    Text("Tankstellen werden bis zu diesem Radius geladen (max. 25 km, entsprechend Tankerkönig).")
                }

                Section {
                    Picker("", selection: appearanceBinding) {
                        ForEach(AppSettings.AppearancePreference.allCases) { mode in
                            Text(mode.localizedTitle).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel(Text("settings.appearance.header"))
                    .accessibilityHint(Text("settings.appearance.a11yHint"))
                } header: {
                    Text("settings.appearance.header")
                } footer: {
                    Text("settings.appearance.footer")
                }

                Section {
                    Text("settings.plus.intro")
                        .font(TRTypography.callout())
                        .foregroundStyle(TRColors.labelSecondary)

                    if entitlementManager.isPlusSubscriber {
                        Text("settings.plus.status.active")
                            .font(TRTypography.body())
                    } else if let product = plusYearlyProduct {
                        HStack(alignment: .firstTextBaseline, spacing: TRSpacing.xs) {
                            Text(product.displayPrice)
                                .font(TRTypography.bodyBold())
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
                        .buttonStyle(.borderedProminent)
                        .tint(TRColors.accent)
                        .disabled(isStoreBusy)
                        .accessibilityHint("Startet den Jahresabo-Kauf über den App Store.")
                    } else {
                        Text("settings.plus.priceLoading")
                            .font(TRTypography.callout())
                            .foregroundStyle(TRColors.labelSecondary)
                    }

                    Link(destination: Self.manageSubscriptionsURL) {
                        Label("settings.plus.manage", systemImage: "creditcard")
                    }
                    .accessibilityHint("Öffnet die Abonnementverwaltung deines Apple-ID-Kontos im Browser oder in den Systemeinstellungen.")

                    Button {
                        Task { await restorePurchases() }
                    } label: {
                        Text("settings.plus.restore")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isStoreBusy)
                    .accessibilityHint("Synchronisiert Käufe mit deinem Apple-ID-Konto.")
                } header: {
                    Text("settings.plus.header")
                } footer: {
                    Text("settings.plus.footer")
                }

                Section {
                    Link(destination: AppSettings.TankerkoenigAttribution.infoURL) {
                        Label("Tankerkönig / MTS-K (CC BY 4.0)", systemImage: "link")
                    }
                    .accessibilityLabel("Tankerkönig und MTS-K, Lizenz CC BY 4.0")
                    .accessibilityHint("Öffnet die Tankerkönig-Website mit Lizenzinformationen.")
                } footer: {
                    Text("Datenquelle und Pflichtattribution für die Nutzung der Tankerkönig-API.")
                }
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
