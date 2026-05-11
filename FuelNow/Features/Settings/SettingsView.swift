import StoreKit
import SwiftUI
import UserNotifications

/// Einstellungen als nutzerzentrierte `Form` mit Sections — Liquid Glass nur auf primären Aktionen.
///
/// Reihenfolge: Kraftstoff → Erscheinungsbild → Favoriten (Plus) → Preisalarme (Plus) → FuelNow Plus
/// (wenn `isPlusUIEnabled`) → Datenquellen-Footer. Suchradius entfällt (TAN-79, fest 25 km).
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(EntitlementManager.self) private var entitlementManager

    @AppStorage(AppSettings.UserDefaultsKey.preferredFuelType) private var preferredFuelRaw = FuelType.e10.rawValue
    @AppStorage(AppSettings.UserDefaultsKey.appearancePreference)
    private var appearanceRaw = AppSettings.AppearancePreference.system.rawValue
    @AppStorage(AppSettings.UserDefaultsKey.priceAlertsEnabled) private var priceAlertsEnabled = false
    @AppStorage(AppSettings.UserDefaultsKey.priceAlertsThresholdEuros) private var priceAlertsThresholdEuros: Double = 0.05

    private var appearanceBinding: Binding<AppSettings.AppearancePreference> {
        Binding(
            get: { AppSettings.AppearancePreference.resolved(storedRaw: appearanceRaw) },
            set: { appearanceRaw = $0.rawValue }
        )
    }

    private var fuelBinding: Binding<FuelType> {
        Binding(
            get: { FuelType(rawValue: preferredFuelRaw) ?? .e10 },
            set: { preferredFuelRaw = $0.rawValue }
        )
    }

    @State private var purchase = PlusPurchaseController()
    @State private var showPlusUpgradeSheet = false
    @State private var showOfferCodeRedemption = false
    @State private var notificationAuthStatus: UNAuthorizationStatus = .notDetermined

    private var plusYearlyProduct: Product? {
        entitlementManager.products.first { $0.id == SubscriptionConstants.plusYearlyProductID }
    }

    private var plusMonthlyProduct: Product? {
        entitlementManager.products.first { $0.id == SubscriptionConstants.plusMonthlyProductID }
    }

    private var plusHeroProduct: Product? {
        plusYearlyProduct ?? plusMonthlyProduct
    }

    var body: some View {
        NavigationStack {
            Form {
                fuelSection
                appearanceSection
                SettingsFavoritesFormSection(showPlusUpgradeSheet: $showPlusUpgradeSheet)
                SettingsPriceAlertsFormSection(
                    showPlusUpgradeSheet: $showPlusUpgradeSheet,
                    priceAlertsEnabled: $priceAlertsEnabled,
                    priceAlertsThresholdEuros: $priceAlertsThresholdEuros,
                    notificationAuthStatus: $notificationAuthStatus
                )
                if FuelNowFeatureFlags.isPlusUIEnabled {
                    plusSection
                }
                dataSourceFooterSection
            }
            .adaptiveSensoryFeedback(.selection, trigger: preferredFuelRaw)
            .adaptiveSensoryFeedback(.selection, trigger: appearanceRaw)
            .adaptiveSensoryFeedback(.impact(weight: .light), trigger: priceAlertsEnabled)
            .adaptiveSensoryFeedback(.selection, trigger: priceAlertsThresholdEuros)
            .navigationTitle(Text("settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(TRColors.labelSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("settings.done.close"))
                    .accessibilityHint("Schließt die Einstellungen.")
                }
            }
            .task {
                #if DEBUG
                purchase.applyDebugMockIfRequested()
                await entitlementManager.refreshEntitlements()
                #endif
                await entitlementManager.loadProducts()
                if let product = plusYearlyProduct ?? plusMonthlyProduct {
                    await purchase.refreshTrialOffer(for: product)
                }
                notificationAuthStatus = await PriceAlertCoordinator.currentAuthorizationStatus()
            }
            .onChange(of: entitlementManager.isPlusSubscriber) { _, isPlus in
                guard FuelNowFeatureFlags.isPlusMonetizationActive else { return }
                if !isPlus {
                    priceAlertsEnabled = false
                }
            }
            .sheet(isPresented: $showPlusUpgradeSheet) {
                PlusUpgradeView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .alert(
                Text("settings.plus.alert.title"),
                isPresented: Binding(
                    get: { purchase.alertMessage != nil },
                    set: { if !$0 { purchase.alertMessage = nil } }
                ),
                actions: {
                    Button("settings.plus.alert.ok", role: .cancel) {
                        purchase.alertMessage = nil
                    }
                },
                message: {
                    if let message = purchase.alertMessage {
                        Text(message)
                    }
                }
            )
            .offerCodeRedemption(isPresented: $showOfferCodeRedemption) { _ in
                Task { await entitlementManager.refreshEntitlements() }
            }
        }
    }

    private var fuelSection: some View {
        Section {
            FuelTypeCardPicker(selection: fuelBinding)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: TRSpacing.xs, leading: 0, bottom: TRSpacing.xs, trailing: 0))
                .listRowSeparator(.hidden)
        } header: {
            Text("settings.section.fuelType")
        }
    }

    private var appearanceSection: some View {
        Section {
            AppearanceIconPicker(selection: appearanceBinding)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: TRSpacing.xs, leading: 0, bottom: TRSpacing.xs, trailing: 0))
                .listRowSeparator(.hidden)
        } header: {
            Text("settings.section.appearance")
        }
    }

    @ViewBuilder
    private var plusSection: some View {
        if entitlementManager.isPlusSubscriber {
            SettingsPlusFormSections.Active(
                purchase: purchase,
                showOfferCodeRedemption: $showOfferCodeRedemption
            ) {
                await restorePurchases()
            }
        } else {
            SettingsPlusFormSections.Promo(
                purchase: purchase,
                plusHeroProduct: plusHeroProduct,
                showPlusUpgradeSheet: $showPlusUpgradeSheet,
                showOfferCodeRedemption: $showOfferCodeRedemption
            ) {
                await restorePurchases()
            }
        }
    }

    private var dataSourceFooterSection: some View {
        Section {
            EmptyView()
        } footer: {
            SettingsDataSourceAttributionFooter()
        }
        .accessibilityElement(children: .combine)
    }

    @MainActor
    private func restorePurchases() async {
        await purchase.restore(via: entitlementManager)
    }
}

#Preview("Light") {
    SettingsView()
        .environment(EntitlementManager())
        .environment(FavoritesStore())
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    SettingsView()
        .environment(EntitlementManager())
        .environment(FavoritesStore())
        .preferredColorScheme(.dark)
}

#Preview("Accessibility 3") {
    SettingsView()
        .environment(EntitlementManager())
        .environment(FavoritesStore())
        .environment(\.dynamicTypeSize, .accessibility3)
}
