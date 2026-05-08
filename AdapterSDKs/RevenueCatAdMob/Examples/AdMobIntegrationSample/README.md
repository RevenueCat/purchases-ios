# AdMob Integration Sample

This sample app demonstrates how to integrate Google AdMob with RevenueCat's ad event tracking using the `RevenueCatAdMob` adapter library. The adapter handles event mapping automatically: load ads through adapter APIs and RevenueCat events are tracked for you.

## Overview

### Ad events tracked

The adapter automatically tracks these RevenueCat ad events for supported formats:

1. **Ad Loaded** - when an ad successfully loads
2. **Ad Displayed** - when an ad is shown to the user (impression)
3. **Ad Opened** - when a user clicks/interacts with the ad
4. **Ad Revenue** - when an ad generates revenue (via AdMob's `paidEventHandler`)
5. **Ad Failed to Load** - when an ad fails to load

### Ad formats demonstrated

This sample uses **Google Mobile Ads SDK v13** Swift API (no `GAD` prefix):

- **Banner** - `GoogleMobileAds.BannerView.loadAndTrack(request:placement:)`
- **Interstitial** - `GoogleMobileAds.InterstitialAd.loadAndTrack(..., fullScreenContentDelegate: self)`
- **App Open** - `GoogleMobileAds.AppOpenAd.loadAndTrack(..., fullScreenContentDelegate: self)`
- **Rewarded** - `GoogleMobileAds.RewardedAd.loadAndTrack(..., fullScreenContentDelegate: self)`
- **Rewarded Interstitial** - `GoogleMobileAds.RewardedInterstitialAd.loadAndTrack(..., fullScreenContentDelegate: self)`
- **Native** - `GoogleMobileAds.AdLoader.loadAndTrack(...)` with AdMob native/ad-loader delegates
- **Native Video** - native loader with a video-oriented ad unit ID
- **Error Handling** - intentionally invalid ad unit ID to validate failed-to-load tracking

### Key files

- `Sources/App.swift` - initializes `GoogleMobileAds.MobileAds` and `Purchases`
- `Sources/HomeView.swift` - UI for loading/showing each ad format and status
- `Sources/AdManagers/*AdManager.swift` - one focused manager per ad format integration path
- `Sources/Constants.swift` - RevenueCat API key

---

## Experimental API notice

This sample uses RevenueCatAdMob APIs exposed as experimental Swift SPI (`@_spi(Experimental)`), and behavior may evolve before full stabilization.

- Adapter APIs shown in this sample are available on iOS 15.0+.
- Swift imports must use `@_spi(Experimental) import RevenueCatAdMob`.
- Review release notes when upgrading `RevenueCatAdMob`.
- Prefer pinning a known-good adapter version during rollout.

---

## Requirements

- Xcode 16+ recommended
- iOS Simulator or device (iOS 15+)
- A valid RevenueCat API key
- AdMob test ad unit IDs (included in this sample)
- **Google Mobile Ads SDK v13** (Swift API; this sample uses v13 naming)
- `RevenueCatAdMob` from the `purchases-ios-admob` package (`RevenueCat` and `GoogleMobileAds` are resolved automatically as transitive dependencies)

---

## Setup & Run

### 1. Prerequisites

1. **Get a RevenueCat API key**
  - Sign up at [revenuecat.com](https://www.revenuecat.com)
  - Get your API key from the [RevenueCat Dashboard](https://app.revenuecat.com/)
2. **AdMob setup** (optional for testing)
  - This sample uses Google's official test ad unit IDs (see below)
  - No AdMob account is required to run the sample as-is
  - For production validation, create an [AdMob account](https://admob.google.com/) and replace IDs

### 2. Configure the app

1. Copy `Local.xcconfig.SAMPLE` to `Local.xcconfig` (repo root). `Local.xcconfig` is ignored by git.
2. Set local override keys in `Local.xcconfig` (without quotes), for example:
   - `RC_REVENUECAT_API_KEY = appl_...`
   - `RC_PROXY_URL = http://localhost:8000/`
   - `RC_REWARDED_AD_UNIT_ID_OVERRIDE = ca-app-pub-.../...`
   - `RC_REWARDED_INTERSTITIAL_AD_UNIT_ID_OVERRIDE = ca-app-pub-.../...`
   - Available ad unit override keys:
     - `RC_BANNER_AD_UNIT_ID_OVERRIDE`
     - `RC_INTERSTITIAL_AD_UNIT_ID_OVERRIDE`
     - `RC_APP_OPEN_AD_UNIT_ID_OVERRIDE`
     - `RC_REWARDED_AD_UNIT_ID_OVERRIDE`
     - `RC_REWARDED_INTERSTITIAL_AD_UNIT_ID_OVERRIDE`
     - `RC_NATIVE_AD_UNIT_ID_OVERRIDE`
     - `RC_NATIVE_VIDEO_AD_UNIT_ID_OVERRIDE`
     - `RC_INVALID_AD_UNIT_ID_OVERRIDE`
3. Run `tuist generate Projects/AdMobIntegrationSample` so these settings are applied to the generated project.
4. Keep committed defaults in source files (placeholder RevenueCat key + Google test AdMob IDs).

### 3. Build and run

1. Open `AdMobIntegrationSample.xcodeproj` directly.
2. Xcode resolves the local `RevenueCatAdMob` package automatically.
3. Select the `AdMobIntegrationSample` scheme.
4. Run on an iPhone simulator or device.

### 4. Verify ad events

In the app:

1. Tap **Load** for a format.
2. Wait for status to become `Ready`.
3. Tap **Show** (where applicable).
4. Interact with the ad and dismiss it.

In both rewarded detail screens:

- Choose whether **Reward Verification** is enabled using the toggle.
- Tap **Load**, then tap **Show** to present using that loaded mode.

The result card reflects the state of ad loading, reward granting, and optional reward verification.

The sample prints diagnostics in the Xcode console and emits RevenueCat ad events for each format. For dashboard verification, background the app after testing to trigger SDK flush.

---

## How it works

`RevenueCatAdMob` sits between AdMob and RevenueCat, mapping AdMob callbacks to RevenueCat ad events automatically:

```text
┌─────────────┐
│   AdMob SDK │
│  (Load Ads) │
└──────┬──────┘
       │
       │ Ad callbacks
       ▼
┌─────────────────────┐
│  RevenueCatAdMob    │
│  (Adapter Library)  │
│                     │
│  Tracks: Loaded,    │
│  Displayed, Opened, │
│  Revenue, Failed    │
└──────┬──────────────┘
       │
       │ RevenueCat events
       ▼
┌────────────────────────┐
│  RevenueCat Dashboard  │
│  (Analytics)           │
└────────────────────────┘
```

All formats in this app use `loadAndTrack` APIs and pass a `placement` value to improve reporting segmentation.

For reward verification flows, the sample explicitly calls `enableRewardVerification()` on loaded rewarded ad instances, then uses `present(..., rewardVerificationStarted:, rewardVerificationResult:)` to show verification progress and map outcomes to real-world behavior:

- grant virtual currency when `verifiedReward.virtualCurrency` is present
- handle the `noReward` verified case separately
- use a safe fallback for unknown verified reward shapes

> **Important:** Do not reassign wrapped delegates/handlers after calling `loadAndTrack`.
> For full-screen ads, pass your `fullScreenContentDelegate` through `loadAndTrack`.
> Replacing delegates/handlers afterward can bypass tracking wrappers.

## Test ad unit IDs used by this sample

This sample uses Google's official test ad unit IDs:


| Ad Format                 | Ad Unit ID                               | Status     |
| ------------------------- | ---------------------------------------- | ---------- |
| **Banner**                | `ca-app-pub-3940256099942544/2435281174` | Working    |
| **Interstitial**          | `ca-app-pub-3940256099942544/4411468910` | Working    |
| **Rewarded**              | `ca-app-pub-3940256099942544/1712485313` | Working    |
| **Rewarded Interstitial** | `ca-app-pub-3940256099942544/6978759866` | Working    |
| **App Open**              | `ca-app-pub-3940256099942544/5575463023` | Working    |
| **Native**                | `ca-app-pub-3940256099942544/2247696110` | Unreliable |
| **Native Video**          | `ca-app-pub-3940256099942544/1044960115` | Unreliable |
| **Error Testing**         | `invalid-ad-unit-id`                     | Working    |


These are official Google test IDs and are safe for development.

### Native ads and test IDs

Native and native video test IDs can be less reliable than other formats depending on environment. For more reliable native testing:

1. Create ad units in your [AdMob account](https://admob.google.com/)
2. Set override keys in `Local.xcconfig` (for example `RC_NATIVE_AD_UNIT_ID_OVERRIDE`) and regenerate with Tuist
3. Configure your device as a test device in AdMob
4. Keep test mode enabled during validation

## Error testing

AdMob does not provide an official "error trigger" test ad unit ID. This sample uses `invalid-ad-unit-id` to intentionally fail ad load requests and validate failed-to-load tracking.

Use the **Error Handling** section in the sample UI:

- Tap **Trigger Ad Load Error**.
- This uses a hard-coded invalid ad unit ID in `ErrorTestingAdManager` to intentionally fail load.
- Confirm failure is logged and failure tracking is emitted.

---

## Troubleshooting

### "Missing RevenueCat API key" or build fails at startup

Set `RC_REVENUECAT_API_KEY` in `Local.xcconfig`, regenerate with Tuist, and relaunch the app.

### Ads not loading

1. **No internet connection** - ensure simulator/device has internet access
2. **AdMob SDK still initializing** - wait a few seconds after launch
3. **Test device not configured** - simulator is typically treated as test; real devices may require explicit setup in AdMob
4. **Ad unit mismatch** - start with Google's test IDs before custom IDs

### "Invalid request" on real device

Your device may not yet be recognized as a test device. Configure it in AdMob and retry after propagation.

### Revenue events not visible

- Verify `Purchases.configure(withAPIKey:)` is called (`Sources/App.swift`)
- Keep `Purchases.logLevel = .debug` during troubleshooting
- Confirm you use adapter methods (`loadAndTrack`) instead of raw AdMob load APIs
- Background the app after interactions so events flush sooner

### Revenue callbacks missing in test mode

AdMob test ads may not always trigger `paidEventHandler`. Revenue tracking is more reliable with production ad units on configured test devices.

### Callbacks stop after loading

If callbacks stop after `loadAndTrack`, check for delegate/handler reassignment:

- For full-screen formats, pass `fullScreenContentDelegate` into `loadAndTrack`
- Avoid replacing ad delegates or handlers after wrapper setup
- For native format, avoid replacing `adLoader.delegate` immediately after `loadAndTrack`

## AdMob SDK version note

This sample uses **Google Mobile Ads v13**; no compiler flag is required. The adapter supports v12.x and v13.x only.