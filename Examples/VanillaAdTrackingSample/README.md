# Vanilla Ad Tracking Sample

This sample app demonstrates how to manually track Google AdMob ad events with RevenueCat **without** using the `RevenueCatAdMob` adapter library. Instead of automatic tracking via `loadAndTrack` APIs, this sample calls `Purchases.shared.adTracker.trackXxx(...)` directly in each AdMob callback.

## Overview

### Architecture

```text
┌─────────────┐
│   AdMob SDK │
│  (Load Ads) │
└──────┬──────┘
       │
       │ Ad callbacks (delegate, completion, paidEventHandler)
       ▼
┌─────────────────────────┐
│  Your App Code          │
│  (Manual tracking)      │
│                         │
│  Purchases.shared       │
│    .adTracker           │
│    .trackAdLoaded(...)  │
│    .trackAdDisplayed(...)│
│    .trackAdOpened(...)  │
│    .trackAdRevenue(...) │
│    .trackAdFailedToLoad(...)│
└──────┬──────────────────┘
       │
       │ RevenueCat events
       ▼
┌────────────────────────┐
│  RevenueCat Dashboard  │
│  (Analytics)           │
└────────────────────────┘
```

### 5 tracked events

| Event | When to call |
|-------|-------------|
| **Ad Loaded** | Ad successfully loads (completion handler / delegate callback) |
| **Ad Displayed** | Ad impression is recorded (`adDidRecordImpression` / `bannerViewDidRecordImpression`) |
| **Ad Opened** | User clicks/interacts with ad (`adDidRecordClick` / `bannerViewDidRecordClick`) |
| **Ad Revenue** | Ad generates revenue (`paidEventHandler`) |
| **Ad Failed to Load** | Ad fails to load (error callback) |

### Code example — manual interstitial tracking

```swift
import GoogleMobileAds
import RevenueCat
@_spi(Experimental) import RevenueCat

// Load
InterstitialAd.load(withAdUnitID: adUnitID, request: Request()) { [weak self] ad, error in
    guard let self else { return }
    if let error {
        Purchases.shared.adTracker.trackAdFailedToLoad(AdFailedToLoad(
            mediatorName: .adMob,
            adFormat: .interstitial,
            placement: "my_placement",
            adUnitId: adUnitID,
            mediatorErrorCode: (error as NSError).code
        ))
        return
    }
    guard let ad else { return }
    let responseInfo = ad.responseInfo

    // Track loaded
    Purchases.shared.adTracker.trackAdLoaded(AdLoaded(
        networkName: responseInfo?.loadedAdNetworkResponseInfo?.adNetworkClassName ?? "",
        mediatorName: .adMob,
        adFormat: .interstitial,
        placement: "my_placement",
        adUnitId: adUnitID,
        impressionId: responseInfo?.responseIdentifier ?? ""
    ))

    // Track revenue
    ad.paidEventHandler = { adValue in
        Purchases.shared.adTracker.trackAdRevenue(AdRevenue(
            networkName: responseInfo?.loadedAdNetworkResponseInfo?.adNetworkClassName ?? "",
            mediatorName: .adMob,
            adFormat: .interstitial,
            placement: "my_placement",
            adUnitId: adUnitID,
            impressionId: responseInfo?.responseIdentifier ?? "",
            revenueMicros: Int(adValue.value.multiplying(by: 1_000_000).int64Value),
            currency: adValue.currencyCode,
            precision: .estimated // map from adValue.precision
        ))
    }

    // Set delegate for impression/click tracking
    ad.fullScreenContentDelegate = self
}
```

### Ad formats demonstrated

This sample uses **Google Mobile Ads SDK v13** Swift API:

- **Banner** — `BannerView` with `BannerViewDelegate`
- **Interstitial** — `InterstitialAd.load(...)` with `FullScreenContentDelegate`
- **App Open** — `AppOpenAd.load(...)` with `FullScreenContentDelegate`
- **Rewarded** — `RewardedAd.load(...)` with `FullScreenContentDelegate`
- **Rewarded Interstitial** — `RewardedInterstitialAd.load(...)` with `FullScreenContentDelegate`
- **Native** — `AdLoader` with `NativeAdLoaderDelegate` + `NativeAdDelegate`
- **Native Video** — native loader with a video-oriented ad unit ID
- **Error Handling** — intentionally invalid ad unit ID to validate failed-to-load tracking

### Key files

- `Sources/App.swift` — initializes `GoogleMobileAds.MobileAds` and `Purchases`
- `Sources/HomeView.swift` — UI for loading/showing each ad format and status
- `Sources/AdMobManager.swift` — all manual ad tracking code
- `Sources/Constants.swift` — RevenueCat API key and AdMob ad unit IDs

---

## Experimental API notice

This sample uses RevenueCat's ad tracking APIs exposed as experimental Swift SPI (`@_spi(Experimental)`), and behavior may evolve before full stabilization.

- Ad tracking APIs are available on iOS 15.0+.
- Swift imports must use `@_spi(Experimental) import RevenueCat`.
- Review release notes when upgrading RevenueCat.

---

## Mediator name

This sample uses `.adMob` as the `MediatorName` in all tracking calls since it uses the AdMob SDK directly. If you use a different ad network or mediation platform, substitute the appropriate value:

- `.appLovin` for AppLovin MAX
- `MediatorName(rawValue: "YourNetwork")` for custom networks

---

## Requirements

- Xcode 16+ recommended
- iOS Simulator or device (iOS 15+)
- A valid RevenueCat API key
- AdMob test ad unit IDs (included in this sample)
- **Google Mobile Ads SDK v13** (Swift API; this sample uses v13 naming)
- `RevenueCat` from the `purchases-ios` package
- `GoogleMobileAds` from the Google Mobile Ads SPM package

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
3. Keep the default AdMob test ad unit IDs for local testing.

### 3. Build and run

1. Open `VanillaAdTrackingSample.xcodeproj` directly.
2. Xcode resolves the local `RevenueCat` package and remote `GoogleMobileAds` package automatically.
3. Select the `VanillaAdTrackingSample` scheme.
4. Run on an iPhone simulator or device.

### 4. Verify ad events

In the app:

1. Tap an ad format from the list.
2. Tap **Load** and wait for status to become `Ready`.
3. Tap **Show** (where applicable).
4. Interact with the ad and dismiss it.

The sample prints diagnostics in the Xcode console and emits RevenueCat ad events for each format. For dashboard verification, background the app after testing to trigger SDK flush.

---

## Comparison with the adapter sample

| Aspect | Adapter Sample (`RevenueCatAdMob`) | This Vanilla Sample |
|--------|-------------------------------------|---------------------|
| Import | `@_spi(Experimental) import RevenueCatAdMob` | `@_spi(Experimental) import RevenueCat` |
| Load API | `XxxAd.loadAndTrack(...)` | `XxxAd.load(...)` + manual `adTracker.trackAdLoaded(...)` |
| Revenue | Automatic via adapter wrapping | Manual `paidEventHandler` + `adTracker.trackAdRevenue(...)` |
| Delegates | Passed through `loadAndTrack` | Set directly + call `adTracker.trackAdDisplayed/Opened` in callbacks |
| Precision | Handled by adapter | Manual mapping function |
| Boilerplate | Minimal | Significant — every callback needs manual tracking calls |

---

## Test ad unit IDs used by this sample

| Ad Format | Ad Unit ID | Status |
| --------- | ---------- | ------ |
| **Banner** | `ca-app-pub-3940256099942544/2435281174` | Working |
| **Interstitial** | `ca-app-pub-3940256099942544/4411468910` | Working |
| **Rewarded** | `ca-app-pub-3940256099942544/1712485313` | Working |
| **Rewarded Interstitial** | `ca-app-pub-3940256099942544/6978759866` | Working |
| **App Open** | `ca-app-pub-3940256099942544/5575463023` | Working |
| **Native** | `ca-app-pub-3940256099942544/2247696110` | Unreliable |
| **Native Video** | `ca-app-pub-3940256099942544/1044960115` | Unreliable |
| **Error Testing** | `invalid-ad-unit-id` | Working |

These are official Google test IDs and are safe for development.

### Native ads and test IDs

Native and native video test IDs can be less reliable than other formats depending on environment. For more reliable native testing:

1. Create ad units in your [AdMob account](https://admob.google.com/)
2. Replace test IDs in `Sources/Constants.swift`
3. Configure your device as a test device in AdMob
4. Keep test mode enabled during validation

## Error testing

AdMob does not provide an official "error trigger" test ad unit ID. This sample uses `invalid-ad-unit-id` to intentionally fail ad load requests and validate failed-to-load tracking.

Use the **Error Testing** section in the sample UI:

- Tap **Trigger Ad Load Error**.
- This uses `Constants.AdMob.invalidAdUnitID` to intentionally fail load.
- Confirm failure is logged and failure tracking is emitted.

---

## Troubleshooting

### "Missing RevenueCat API key" or build fails at startup

Make sure `revenueCatAPIKey` in `Sources/Constants.swift` is set to your real RevenueCat API key (replace the `YOUR_REVENUECAT_API_KEY` placeholder).

### Ads not loading

1. **No internet connection** — ensure simulator/device has internet access
2. **AdMob SDK still initializing** — wait a few seconds after launch
3. **Test device not configured** — simulator is typically treated as test; real devices may require explicit setup in AdMob
4. **Ad unit mismatch** — start with Google's test IDs before custom IDs

### "Invalid request" on real device

Your device may not yet be recognized as a test device. Configure it in AdMob and retry after propagation.

### Revenue events not visible

- Verify `Purchases.configure(withAPIKey:)` is called (`Sources/App.swift`)
- Keep `Purchases.logLevel = .debug` during troubleshooting
- Confirm you are calling `adTracker.trackAdRevenue(...)` in each ad's `paidEventHandler`
- Background the app after interactions so events flush sooner

### Revenue callbacks missing in test mode

AdMob test ads may not always trigger `paidEventHandler`. Revenue tracking is more reliable with production ad units on configured test devices.

### Tracking calls not appearing in console

- Ensure you have `@_spi(Experimental) import RevenueCat` (not just `import RevenueCat`)
- Confirm you're running on iOS 15+ (ad tracking APIs require `@available(iOS 15.0, *)`)
- Verify `Purchases.isConfigured` is `true` before tracking calls execute

## AdMob SDK version note

This sample uses **Google Mobile Ads v13**; no compiler flag is required.
