import StoreKit
import SwiftUI
import UIKit
import UserNotifications

/// Einstellungen als nutzerzentrierte `Form` mit Sections — Liquid Glass nur auf primären Aktionen.
///
/// Reihenfolge (TAN-78, angepasst durch TAN-79, TAN-86, TAN-88, TAN-89):
/// 1. **Kraftstoff** – große Karten-Auswahl (E5 / E10 / Diesel) mit aktiver Glas-Karte als visuellem Anker.
///    Seit TAN-86 ohne 1-Zeilen-Untertitel — nur Glyph + Sortenname; Untertitel bleibt VoiceOver-only.
///    Seit TAN-88 ohne Beschreibungs-Footer — die Karten sind selbsterklärend.
/// 2. **Erscheinungsbild** – Drei-Segmente-Icon-Picker (Auto / Hell / Dunkel) mit Akzent-Glas-Pille
///    auf dem aktiven Segment (TAN-86, ersetzt den zuvor genutzten `Picker(.menu)`). Seit TAN-88
///    ohne Beschreibungs-Footer — der Icon-Picker ist visuell selbsterklärend.
/// 3. **FuelNow Plus** – Mini-Hero mit Eyebrow / Headline / 1–2 Benefits / Preis prominent / einem
///    Glas-CTA, der das volle `PlusUpgradeView`-Sheet (TAN-45) öffnet. Bei aktivem Abo erscheint stattdessen
///    eine schlichte Status-Sektion mit Verwaltungs- und Restore-Aktionen.
///    Seit 1.0-Release bewusst hinter `FuelNowFeatureFlags.isPlusUIEnabled` versteckt — Code bleibt
///    kompiliert, das Re-Enable ist ein Flag-Flip ohne strukturelle Änderung.
/// 4. **Datenquellen-Footer** – unauffälliger Tankerkönig/MTS-K-Hinweis (CC BY 4.0).
///
/// Der frühere „Suchradius"-Slider ist mit TAN-79 entfernt; die App nutzt fest das
/// Tankerkönig-API-Maximum von 25 km (`AppSettings.SearchRadius.apiMaxKm`).
/// Der frühere Stammtankstellen-Platzhalter (Phase 9 / Appwrite-Sync) ist mit TAN-89 entfernt;
/// die zugehörigen `settings.section.favorites.placeholder.*`-Strings bleiben im Catalog
/// erhalten (vom Build automatisch als `extractionState: stale` markiert) und können bei
/// Wiederaufnahme reaktiviert werden.
/// Der frühere DEBUG-Toggle „Demo-Modus: FuelNow Plus aktiv" (TAN-90) ist entfernt — Plus-Status
/// kommt ausschließlich aus `Transaction.currentEntitlements` (StoreKit, Sandbox, oder
/// `FuelNowPlus.storekit` Local Testing).
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(EntitlementManager.self) private var entitlementManager
    @Environment(FavoritesStore.self) private var favoritesStore

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
    /// System-Authorization-Status fuer Notifications. Wird beim Erscheinen geladen und bei
    /// jedem Toggle-Anschalten aktualisiert, damit der Preis-Push-Toggle den realen Zustand
    /// reflektiert (bei `denied` springt der Toggle zurueck und ein Hinweis erklaert den
    /// Deep-Link in die Systemeinstellungen).
    @State private var notificationAuthStatus: UNAuthorizationStatus = .notDetermined

    private var plusYearlyProduct: Product? {
        entitlementManager.products.first { $0.id == SubscriptionConstants.plusYearlyProductID }
    }

    var body: some View {
        NavigationStack {
            Form {
                fuelSection
                appearanceSection
                favoritesSection
                priceAlertsSection
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
                #endif
                await entitlementManager.loadProducts()
                if let product = plusYearlyProduct {
                    await purchase.refreshTrialOffer(for: product)
                }
                notificationAuthStatus = await PriceAlertCoordinator.currentAuthorizationStatus()
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
        }
    }

    // MARK: - Sections

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
            plusActiveSection
        } else {
            plusPromoSection
        }
    }

    /// Promo-Sektion für Nicht-Plus-User: Mini-Hero als einziges visuelles Asset, plus dezente Zweit-Aktionen.
    private var plusPromoSection: some View {
        Section {
            PlusMiniHero(
                product: plusYearlyProduct,
                isLoading: plusYearlyProduct == nil,
                trialOffer: purchase.trialOffer,
                openPlusSheet: { showPlusUpgradeSheet = true }
            )
            .listRowInsets(EdgeInsets(top: TRSpacing.xs, leading: 0, bottom: TRSpacing.xs, trailing: 0))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Button {
                Task { await restorePurchases() }
            } label: {
                Label("settings.plus.restore", systemImage: "arrow.clockwise")
            }
            .disabled(purchase.isBusy)
            .accessibilityHint("Synchronisiert Käufe mit deinem Apple-ID-Konto.")
        } header: {
            Text("settings.section.plus")
        } footer: {
            Text("settings.plus.footer")
        }
    }

    /// Status-Sektion für aktive Plus-Abonnenten: keine Promo, klare Verwaltungs-Aktionen.
    private var plusActiveSection: some View {
        Section {
            Label {
                Text("settings.plus.status.active")
                    .font(TRTypography.bodyBold())
            } icon: {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(TRColors.accentText)
            }
            .accessibilityElement(children: .combine)

            Button {
                openURL(Self.manageSubscriptionsURL)
            } label: {
                Label("settings.plus.manage", systemImage: "creditcard")
            }
            .accessibilityHint("Öffnet die Abonnementverwaltung deines Apple-ID-Kontos.")

            Button {
                Task { await restorePurchases() }
            } label: {
                Label("settings.plus.restore", systemImage: "arrow.clockwise")
            }
            .disabled(purchase.isBusy)
            .accessibilityHint("Synchronisiert Käufe mit deinem Apple-ID-Konto.")
        } header: {
            Text("settings.section.plus")
        } footer: {
            Text("settings.plus.footer")
        }
    }

    /// Lokale Favoriten (Roadmap Phase 2). Persistiert in `FavoritesStore` (`UserDefaults` / App-Group).
    private var favoritesSection: some View {
        Section {
            if favoritesStore.favorites.isEmpty {
                Text("Noch keine Favoriten — tippe in der Tankstellen-Detailansicht auf das Herz.")
                    .font(TRTypography.caption())
                    .foregroundStyle(TRColors.labelSecondary)
            } else {
                ForEach(favoritesStore.favorites) { favorite in
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: TRSpacing.xxs) {
                            Text(favorite.displayTitle)
                                .font(TRTypography.bodyBold())
                            if !favorite.street.isEmpty {
                                Text(favorite.street)
                                    .font(TRTypography.caption())
                                    .foregroundStyle(TRColors.labelSecondary)
                            }
                        }
                        Spacer(minLength: TRSpacing.s)
                        Button(role: .destructive) {
                            Haptics.tap(.medium)
                            favoritesStore.remove(stationID: favorite.id)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(TRColors.danger)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(favorite.displayTitle) als Favorit entfernen")
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        favoritesStore.remove(stationID: favoritesStore.favorites[index].id)
                    }
                }
            }
        } header: {
            Text("Favoriten")
        } footer: {
            Text("Lokale Liste — wird mit Widget und Watch geteilt, sobald Sync aktiviert ist.")
                .font(TRTypography.caption())
                .foregroundStyle(TRColors.labelSecondary)
        }
    }

    /// Preis-Pushes (Roadmap Phase 3). Lokal, ohne Server.
    private var priceAlertsSection: some View {
        Section {
            Toggle(isOn: $priceAlertsEnabled) {
                Label("Preis-Pushes (Beta)", systemImage: "bell.badge")
            }
            .tint(TRColors.accent)
            .accessibilityHint("Schickt eine Benachrichtigung, wenn ein Favorit deutlich guenstiger wird.")
            .onChange(of: priceAlertsEnabled) { _, newValue in
                guard newValue else { return }
                Task { await handlePriceAlertsToggleEnabled() }
            }

            if priceAlertsEnabled {
                Picker(selection: $priceAlertsThresholdEuros) {
                    Text("3 Cent").tag(0.03)
                    Text("5 Cent").tag(0.05)
                    Text("10 Cent").tag(0.10)
                } label: {
                    Label("Schwelle", systemImage: "arrow.down.right")
                }
                .accessibilityHint("Mindestpreissturz, ab dem ein Push verschickt wird.")
            }

            if priceAlertsEnabled, notificationAuthStatus == .denied {
                Button(role: .none) {
                    openNotificationSystemSettings()
                } label: {
                    Label("Mitteilungen in Systemeinstellungen erlauben", systemImage: "gear")
                        .foregroundStyle(TRColors.accent)
                }
                .accessibilityHint("Oeffnet die FuelNow-Seite in den iOS-Einstellungen.")
            }
        } header: {
            Text("Preis-Pushes")
        } footer: {
            priceAlertsFooter
        }
    }

    private var priceAlertsFooter: some View {
        Text(priceAlertsFooterText)
            .font(TRTypography.caption())
            .foregroundStyle(TRColors.labelSecondary)
    }

    private var priceAlertsFooterText: String {
        let baseHint = "Beta — laeuft lokal im Hintergrund. iOS bestimmt, wie oft die App nachsehen darf."
        guard priceAlertsEnabled else { return baseHint }
        switch notificationAuthStatus {
        case .denied:
            let denied = "Mitteilungen sind fuer FuelNow in den Systemeinstellungen deaktiviert — "
                + "Pushes kommen erst an, wenn du sie dort wieder erlaubst."
            return baseHint + "\n\n" + denied
        default:
            return baseHint
        }
    }

    /// Holt — wenn der User den Toggle gerade auf an gestellt hat — das System-Permission-Sheet
    /// (oder den aktuellen Status, wenn schon entschieden). Bei `denied`/Fehler springt der
    /// Toggle zurueck und der Footer-Deep-Link in die Systemeinstellungen erscheint.
    private func handlePriceAlertsToggleEnabled() async {
        let granted = await PriceAlertCoordinator.requestNotificationAuthorizationIfNeeded()
        notificationAuthStatus = await PriceAlertCoordinator.currentAuthorizationStatus()
        if !granted {
            await MainActor.run { priceAlertsEnabled = false }
        }
    }

    private func openNotificationSystemSettings() {
        Haptics.tap(.light)
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }

    /// Datenquellen-Hinweis am Listenende — bewusst klein und ohne eigene Glas-Karte.
    private var dataSourceFooterSection: some View {
        Section {
            EmptyView()
        } footer: {
            VStack(alignment: .leading, spacing: TRSpacing.xxs) {
                let attribution = AttributedString(
                    String(
                        format: String(localized: "settings.dataSource.inline"),
                        String(localized: "settings.dataSource.linkLabel")
                    )
                )
                Text(attribution)
                    .font(TRTypography.caption())
                    .foregroundStyle(TRColors.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("Tankerkönig und MTS-K, Lizenz CC BY 4.0")
                    .accessibilityHint("Doppeltippen, um die Lizenzinformationen zu öffnen.")
                    .onTapGesture {
                        openURL(AppSettings.TankerkoenigAttribution.infoURL)
                    }
            }
            .padding(.top, TRSpacing.xs)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Store actions

    @MainActor
    private func restorePurchases() async {
        await purchase.restore(via: entitlementManager)
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
