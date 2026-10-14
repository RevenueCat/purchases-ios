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
- **Rewarded** - `loadAndTrack` preloads the ad; `RewardedAdPrompt(ad: ...)` resolves rewards, tracks the prompt,
  and presents the supplied ad
- **Rewarded Interstitial** - `GoogleMobileAds.RewardedInterstitialAd.loadAndTrack(..., fullScreenContentDelegate: self)`
- **Native** - `GoogleMobileAds.AdLoader.loadAndTrack(...)` with AdMob native/ad-loader delegates
- **Native Video** - native loader with a video-oriented ad unit ID
- **Error Handling** - intentionally invalid ad unit ID to validate failed-to-load tracking

### Key files

- `Sources/App.swift` - initializes `GoogleMobileAds.MobileAds` and `Purchases`
- `Sources/HomeView.swift` - UI for loading/showing each ad format and status
- `Sources/DetailViews/RewardedDetailView.swift` - configured rewarded-ad prompt integration
- `Sources/AdManagers/*AdManager.swift` - one focused manager for each remaining ad format integration path
- `Sources/Constants.swift` - RevenueCat API key

---

## Requirements

- Xcode 16+ recommended
- iOS Simulator or device (iOS 15+)
- Adapter APIs shown in this sample are available on iOS 15.0+.
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

1. Open `Sources/Constants.swift`.
2. Replace `YOUR_REVENUECAT_API_KEY` with your real RevenueCat API key.
3. Configure the rewarded test ad unit ID in RevenueCat if you want to exercise the configured-reward prompt.
4. Keep the default AdMob test ad unit IDs in the sample for local testing.

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

In the rewarded interstitial screen:

- Choose whether **Reward Verification** is enabled using the toggle.
- Tap **Load**, then tap **Show** to present using that loaded mode.

In the rewarded screen, tap **Load** to preload an ad using `loadAndTrack`. The prompt receives that ad
and renders immediately, using configured rewards from the local cache when available. It shows a button describing
the configured rewards. Tapping it tracks acceptance and presents the ad. The verification toggle demonstrates
both `RewardedAdPrompt` and `RewardedAdPromptWithoutVerification`.

The result card reflects reward granting and optional reward verification.

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

For regular rewarded ads, the dedicated **Load** button calls `loadAndTrack` and passes the loaded ad to
the prompt. The prompt owns reward-configuration preparation, prompt tracking, and presentation, not ad loading.
`RewardedAdPrompt` enables RevenueCat reward verification, while `RewardedAdPromptWithoutVerification`
clears any existing per-ad SSV options and RevenueCat verification state before presentation, leaving
the app responsible for granting the reward. The custom SwiftUI content reads the configured reward
and calls `prompt.accept()` when tapped. The **Load** button handles ad-loading failures. The prompt
reads reward configuration from the local cache without waiting for a fetch. When metadata is unavailable
or no rewards are configured, the sample uses a generic `Watch an ad to earn a reward` offer;
presentation and verification outcomes are delivered through `onResult`. If the prompt has no attached
presentation controller or AdMob cannot present the ad, the result is `.notPresented` with a `presentationError`.
`onResult` is called once on the main actor: `.rewardEarned` arrives when AdMob reports the reward,
and `.verificationCompleted` arrives when verification finishes. Neither implies the ad has closed;
later dismissal produces no second result. Dismissal before earning a reward reports `.dismissed` instead.
Rewarded interstitials continue to demonstrate the lower-level `enableRewardVerification()` and
`present(..., rewardVerificationStarted:, rewardVerificationCompleted:)` APIs.

Verified results are mapped to real-world behavior:

- grant virtual currency when `reward.virtualCurrency` is present
- handle the `noReward` verified case separately
- use a safe fallback for unknown verified reward shapes
- rely on adapter-managed cache invalidation for verified virtual currency rewards (then refetch balances when needed)

> **Important:** Do not reassign wrapped delegates/handlers after calling `loadAndTrack`.
> For full-screen ads, pass your `fullScreenContentDelegate` through `loadAndTrack` or use
> `setTrackingFullScreenContentDelegate`. The prompt uses the latter when accepting the ad.
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
2. Replace test IDs in the relevant `Sources/AdManagers/*AdManager.swift` file
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

Make sure `revenueCatAPIKey` in `Sources/Constants.swift` is set to your real RevenueCat API key (replace the `YOUR_REVENUECAT_API_KEY` placeholder).

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
