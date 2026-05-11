# FuelNow Plus — Subscriptions & Free Trial

This document describes how FuelNow Plus is wired through StoreKit 2,
including the **3-day Free Trial Introductory Offer** introduced with
[Linear TAN-81](https://linear.app/tankradar-app/issue/TAN-81/plus-3-tage-kostenloser-probezeitraum-free-trial-introductory-offer).

## Upgrade UI placement ([TAN-45](https://linear.app/tankradar-app/issue/TAN-45))

**Product decision:** FuelNow ships **one** optional upgrade surface — `PlusUpgradeView`
as a **large sheet** (`presentationDetents: [.large]`), opened from **Settings**
via `PlusMiniHero`, from **gated Favoriten/Preisalarme** rows, or from the **Favoriten-Herz**
in `StationDetailView` when the user is not subscribed. There is **no** automatic
launch paywall, **no** map nag banner, and **no** separate web checkout outside StoreKit.

**Pipeline parity:** Settings and the sheet both use:

- `@Environment(EntitlementManager.self)` for catalog load and entitlement state
- `PlusPurchaseController` for purchase, restore, trial-offer refresh (`refreshTrialOffer(for:)`), and alerts
- `PlusPaywallCopy` + `Product.SubscriptionInfo.isEligibleForIntroOffer` so **trial copy appears only when Apple reports eligibility** ([TAN-81](https://linear.app/tankradar-app/issue/TAN-81))

**ASC / review alignment:** Pricing strings prefer `Product.displayPrice`; trial duration is never hardcoded (see *Eligibility check* below). CarPlay-specific upgrade copy stays in Phase 7 tickets ([TAN-57](https://linear.app/tankradar-app/issue/TAN-57)), not in this sheet.

**Tests:** `PlusPaywallCopyTests`, `PlusPurchaseControllerTests` (deterministic, no `SKTestSession` required).

## Product configuration

- Subscription Group: **FuelNow Plus** (`B17E94D2`)
- Auto-renewable subscription products (same group; app loads both IDs via `SubscriptionConstants.productIDs`):
  - **Yearly — Product ID:** `com.vibecoding.fuelnow.subscription.year`
    - **Period:** 1 year (`P1Y`)
    - **Display price (DEU):** € 6.00 (placeholder — overridden by ASC pricing tier)
    - **Family shareable:** false
  - **Monthly — Product ID:** `com.vibecoding.fuelnow.subscription.month`
    - **Period:** 1 month (`P1M`)
    - **Display price (local `.storekit`):** placeholder — set real price in ASC
    - **Family shareable:** false
- Introductory offer (Free Trial) — configure on **each** product in ASC (same group rules apply):
  - **Payment mode:** Free Trial
  - **Period:** 3 days (`P3D`)
  - **Eligibility:** Apple-managed — first-time purchasers per Subscription Group / Family.

## Local development (`FuelNowPlus.storekit`)

`FuelNowPlus.storekit` is the source of truth for **local Previews,
Simulator runs, and Swift Testing** (`SKTestSession`). It mirrors the
production ASC offer:

```json
"introductoryOffer" : {
  "displayPrice" : "0.00",
  "internalID" : "7A1B9C3D",
  "numberOfPeriods" : 1,
  "paymentMode" : "free",
  "subscriptionPeriod" : "P3D"
}
```

Notes:

- StoreKit Configuration JSON uses `"paymentMode": "free"` for free trials —
  the runtime API exposes the same offer as
  `Product.SubscriptionOffer.PaymentMode.freeTrial`.
- The file is added to the **FuelNowTests** Resources build phase so
  `EntitlementManagerStoreKitTests` can boot a deterministic
  `SKTestSession`.
- A simulator run can be configured with this `.storekit` file via the
  scheme's *Run → Options → StoreKit Configuration*.

## App Store Connect (Production)

Apple's **minimum free-trial duration is 3 days** — 48 h is not selectable
in App Store Connect. The owner decided on Variant A in the TAN-81
discussion (3-day Free Trial via the standard StoreKit Introductory Offer).

Steps to configure once per app:

1. Open **App Store Connect → Apps → FuelNow → Subscriptions** (left
   sidebar).
2. Open the **FuelNow Plus** group, then the
   `com.vibecoding.fuelnow.subscription.year` product.
3. Open the **Subscription Pricing** section.
4. Click **Set Up Introductory Offer**.
5. Configure:
   - **Type:** Free Trial
   - **Eligibility:** *New Subscribers* (Apple's default — only first-time
     purchasers in this Subscription Group)
   - **Duration:** 3 Days
   - **Countries / Regions:** All (default)
   - **Start / End:** No end date (or roll a date-bounded campaign)
6. **Save** and propagate. Allow ~15 minutes for the offer to surface in
   `Product.subscription.introductoryOffer`.
7. Repeat steps **2–6** for **`com.vibecoding.fuelnow.subscription.month`** (monthly tier) so both products exist in ASC and match `FuelNowPlus.storekit`.

> The offer flips on for users who have **never** subscribed to a product
> in the *FuelNow Plus* Subscription Group on the same Family. Apple
> serves at most **one** Introductory Offer per group per Family. See:
> [Implementing introductory offers in your app](https://developer.apple.com/documentation/storekit/implementing-introductory-offers-in-your-app).

### Monthly product checklist (`com.vibecoding.fuelnow.subscription.month`)

Use this when the monthly SKU is **not** in App Store Connect yet, or to verify parity with `FuelNowPlus.storekit` and the app’s `SubscriptionConstants.productIDs`.

1. **App Store Connect → Apps → FuelNow → Subscriptions** → open group **FuelNow Plus** (same group as the yearly product).
2. **Create** a new auto-renewable subscription (blue **+** or **Create** under the group).
3. **Reference name:** e.g. `FuelNow Plus Monthly` (internal only).
4. **Product ID:** exactly `com.vibecoding.fuelnow.subscription.month` — must match code and StoreKit Configuration.
5. **Subscription duration:** **1 month**.
6. **Pricing:** open **Subscription Pricing**, set your base territory (e.g. Germany) and any other regions; ASC applies tiers — align with your intended monthly anchor (see plan note: monthly is typically priced higher *per month* than 1/12 of the yearly tier).
7. **Introductory offer (required for parity with yearly):** on this monthly product, repeat the same pattern as the yearly SKU — **Free Trial**, **3 days**, **New subscribers**, all regions, no end date (unless running a campaign). One introductory offer per subscription group per Apple ID family still applies.
8. **Review information / localizations:** add display name and description per locale if prompted; save all sections until the product shows **Ready to Submit** with the app version that includes both product IDs.
9. **Propagation:** after save, allow time (often ~15 minutes) before Sandbox / TestFlight sees `Product.subscription.introductoryOffer` on the new SKU.
10. **Verify:** Xcode **StoreKit Testing** with `FuelNowPlus.storekit`, or a Sandbox account on device — Settings and `PlusUpgradeView` should list **year** and **month**; trial copy follows `isEligibleForIntroOffer` from the product you refresh in `PlusPurchaseController.refreshTrialOffer(for:)`.

## Eligibility check

The app **never** hardcodes the trial duration or eligibility flag. At
runtime, `PlusPurchaseController.refreshTrialOffer(for:)` reads:

- `Product.subscription?.introductoryOffer` — duration, payment mode,
  number of periods.
- `Product.SubscriptionInfo.isEligibleForIntroOffer` (async) — whether
  the current Apple ID can still redeem the trial.

The result is exposed as `PlusPurchaseController.trialOffer` and consumed
by `PlusPaywallCopy.audience(...)`, which produces one of three deterministic
audiences:

| Audience | Trigger | UI Effect |
| --- | --- | --- |
| `activeSubscriber` | `EntitlementManager.isPlusSubscriber == true` | Status block, no trial copy |
| `eligibleForTrial` | not subscribed + Apple eligibility = true | Trial headline + trial CTA + trial badge |
| `ineligibleForTrial` | not subscribed + Apple eligibility = false | Standard subscribe CTA, standard footer |

`PlusPaywallCopy.formattedTrialDuration(...)` renders the period via
`DateComponentsFormatter` so the string is locale-correct (`3 Tage` /
`3 days`).

## Testing

- **Unit (deterministic):** `PlusPaywallCopyTests` and the extended
  `PlusPurchaseControllerTests` cover audience selection, period
  formatting, and copy output. They run with no `SKTestSession`.
- **StoreKit session:** `EntitlementManagerStoreKitTests` boots
  `SKTestSession` against `FuelNowPlus.storekit`. The suite is
  auto-disabled on iOS 26.3 / 26.4 due to the Apple-confirmed bug
  (release-noted as fixed in iOS 26.5 RC) — see TAN-62.
- **Simulator smoke:** `./scripts/build-and-run-simulator.sh` then open
  *Settings → FuelNow Plus* and the *„FuelNow Plus ansehen"* sheet to see
  the trial badge / headline.

## Local testing fallbacks (TAN-90)

Three layered failure modes can leave the Settings price spinner running
forever — TAN-90 hardens each one:

1. **Scheme `.storekit` reference path.** The shared scheme file
   references `FuelNowPlus.storekit` relative to the implicit
   `.xcworkspace` bundle, i.e. `../../FuelNowPlus.storekit` from
   `FuelNow.xcodeproj/project.xcworkspace/`. If that path is broken,
   even Xcode `Cmd+R` will skip StoreKit Local Testing and
   `Product.products(for:)` returns `[]`.
2. **`xcrun simctl launch` ignores StoreKit Local Testing.** Our
   `./scripts/build-and-run-simulator.sh` and the AXe smoke pipeline
   both go through `simctl`, so they always hit the empty-products path
   unless the simulator is signed into a Sandbox Apple ID.
3. **No loading timeout.** `PlusMiniHero` and `PlusUpgradeView` now
   replace the spinner with a *Price currently unavailable* fallback
   after **8 s** of empty product state. Restore and Manage actions stay
   reachable.

> The original TAN-90 ticket also shipped a DEBUG-only **„Demo-Modus:
> FuelNow Plus aktiv"** toggle (Launch-Arg `--mock-plus-subscriber` plus
> a Settings switch) that flipped `EntitlementManager.isPlusSubscriber`
> without a real purchase. That toggle was removed once the StoreKit
> Local Testing path stabilised — Plus state now comes exclusively from
> `Transaction.currentEntitlements` (Sandbox Apple ID, ASC promo codes,
> or `FuelNowPlus.storekit` Local Testing in Xcode `Cmd+R`).
> Sandbox testers (App Store Connect) remain the source of truth for the
> full StoreKit purchase / restore loop and live in
> [TAN-46](https://linear.app/tankradar-app/issue/TAN-46) /
> [TAN-59](https://linear.app/tankradar-app/issue/TAN-59).

## Sources

- Apple — [Set up introductory offers for auto-renewable subscriptions](https://developer.apple.com/help/app-store-connect/manage-subscriptions/set-up-introductory-offers-for-auto-renewable-subscriptions)
- Apple — [Implementing introductory offers in your app](https://developer.apple.com/documentation/storekit/implementing-introductory-offers-in-your-app)
- Apple — [`Product.SubscriptionInfo.isEligibleForIntroOffer`](https://developer.apple.com/documentation/storekit/product/subscriptioninfo/iseligibleforintrooffer)
- Apple — [`Product.SubscriptionOffer`](https://developer.apple.com/documentation/storekit/product/subscriptionoffer)
- Apple HIG — [In-App Purchase guidelines](https://developer.apple.com/design/human-interface-guidelines/in-app-purchase)
