# RevenueCat AdMob Adapter (iOS)

Wraps AdMob ad lifecycle callbacks to automatically track ad events in RevenueCat. Drop-in replacement for standard AdMob loading calls — add one method call and RevenueCat tracks loaded, displayed, opened, revenue, and failed-to-load events for you.

The adapter is a **product of the main RevenueCat Swift package**. Add the main `purchases-ios` package and link the `RevenueCatAdMob` product only for targets that use it; other targets can depend only on RevenueCat or RevenueCatUI without resolving Google Mobile Ads.

## Installation

- **Swift Package Manager:** Add the main RevenueCat package and the `RevenueCatAdMob` product to the target that uses the adapter:
  ```swift
  .package(url: "https://github.com/RevenueCat/purchases-ios", from: "5.0.0")  // or your preferred version
  ```
  Then add the `RevenueCatAdMob` product to your target. Your app will resolve Google Mobile Ads only for targets that depend on `RevenueCatAdMob`.

- **Swift Package Manager (local development):** To use the adapter from a local checkout of this repo, add the package by path to the **root** of the repo (not the `RevenueCatAdMob` folder):
  ```swift
  .package(path: "path/to/purchases-ios")
  ```
  Then add the `RevenueCatAdMob` product to your target.

- **CocoaPods:** Use the `RevenueCatAdMob` pod (if published). It will pull in RevenueCat and Google Mobile Ads only for targets that use it.

## Supported AdMob SDK versions

The adapter supports **Google Mobile Ads SDK v12.x and v13.x** (Swift API). Use as-is; no extra setup required.

## Usage

Import the adapter with SPI to access the experimental API surface:

```swift
@_spi(Experimental) import RevenueCatAdMob
```

**Placement:** All load-and-track APIs take a `placement` parameter — a string that identifies where the ad is shown in your app (e.g. `"home_banner"`, `"level_complete"`, `"app_launch"`). RevenueCat uses it for reporting and segmentation. Use consistent values across your app.

> **Important:** Do not reassign AdMob delegates/handlers after calling `loadAndTrack`.
> The adapter wraps them with tracking listeners. Reassigning them later replaces those wrappers and can break event tracking.
> Pass your callbacks via `loadAndTrack` parameters where available.

### Banner ads

**AdMob only** ([docs](https://developers.google.com/admob/ios/banner)):

```swift
let bannerView = BannerView(adSize: AdSize(size: CGSize(width: 320, height: 50), flags: 0))
bannerView.adUnitID = "ca-app-pub-3940256099942544/2435281174"
bannerView.delegate = self
bannerView.load(Request())
```

**With RevenueCat tracking:**

```swift
let bannerView = BannerView(adSize: AdSize(size: CGSize(width: 320, height: 50), flags: 0))
bannerView.adUnitID = "ca-app-pub-3940256099942544/2435281174"
bannerView.loadAndTrack(request: Request(), placement: "home_banner")
```

Pass `delegate` and/or `paidEventHandler` via the `loadAndTrack` overload that accepts them; the adapter forwards callbacks to them and adds tracking. Do not reassign `bannerView.delegate` or `bannerView.paidEventHandler` after calling `loadAndTrack`, or you'll override RevenueCat's listeners.

### Interstitial ads

**AdMob only** ([docs](https://developers.google.com/admob/ios/interstitial)):

```swift
InterstitialAd.load(with: "ca-app-pub-3940256099942544/4411468910", request: Request()) { ad, error in
    if let error = error { return }
    self.interstitialAd = ad
    ad?.fullScreenContentDelegate = self
}

// Later, to show:
interstitialAd?.present(from: self)
```

**With RevenueCat tracking:**

```swift
// Pass fullScreenContentDelegate here. The adapter forwards callbacks to it and adds tracking.
// Do not set ad.fullScreenContentDelegate or ad.paidEventHandler later, or you'll override RevenueCat's listeners.
InterstitialAd.loadAndTrack(
    withAdUnitID: "ca-app-pub-3940256099942544/4411468910",
    request: Request(),
    placement: "level_complete",
    fullScreenContentDelegate: self
) { ad, error in
    if let error = error { return }
    self.interstitialAd = ad
}

// Later, to show (unchanged): same ad instance, same present flow.
interstitialAd?.present(from: self)
```

### App open ads

**AdMob only** ([docs](https://developers.google.com/admob/ios/app-open)):

```swift
AppOpenAd.load(with: "AD_UNIT_ID", request: Request()) { ad, error in
    if let error = error { return }
    self.appOpenAd = ad
    ad?.fullScreenContentDelegate = self
}

// Later, to show:
appOpenAd?.present(from: self)
```

**With RevenueCat tracking:**

```swift
// Pass fullScreenContentDelegate here. The adapter forwards callbacks to it and adds tracking.
// Do not set ad.fullScreenContentDelegate or ad.paidEventHandler later, or you'll override RevenueCat's listeners.
AppOpenAd.loadAndTrack(
    withAdUnitID: "AD_UNIT_ID",
    request: Request(),
    placement: "app_launch",
    fullScreenContentDelegate: self
) { ad, error in
    if let error = error { return }
    self.appOpenAd = ad
}

// Later, to show (unchanged):
appOpenAd?.present(from: self)
```

### Rewarded ads

**AdMob only** ([docs](https://developers.google.com/admob/ios/rewarded)):

```swift
RewardedAd.load(with: "AD_UNIT_ID", request: Request()) { ad, error in
    if let error = error { return }
    self.rewardedAd = ad
    ad?.fullScreenContentDelegate = self
}

// Later, to show:
rewardedAd?.present(from: self, userDidEarnRewardHandler: {
    // User earned reward
})
```

**With RevenueCat tracking:**

```swift
// Pass fullScreenContentDelegate here. The adapter forwards callbacks to it and adds tracking.
// Do not set ad.fullScreenContentDelegate or ad.paidEventHandler later, or you'll override RevenueCat's listeners.
RewardedAd.loadAndTrack(
    withAdUnitID: "AD_UNIT_ID",
    request: Request(),
    placement: "bonus_coins",
    fullScreenContentDelegate: self
) { ad, error in
    if let error = error { return }
    self.rewardedAd = ad
}

// Later, to show (unchanged):
rewardedAd?.present(from: self, userDidEarnRewardHandler: {
    // User earned reward
})
```

### Rewarded interstitial ads

**AdMob only** ([docs](https://developers.google.com/admob/ios/rewarded-interstitial)):

```swift
RewardedInterstitialAd.load(with: "AD_UNIT_ID", request: Request()) { ad, error in
    if let error = error { return }
    self.rewardedInterstitialAd = ad
    ad?.fullScreenContentDelegate = self
}

// Later, to show:
rewardedInterstitialAd?.present(from: self, userDidEarnRewardHandler: {
    // User earned reward
})
```

**With RevenueCat tracking:**

```swift
// Pass fullScreenContentDelegate here. The adapter forwards callbacks to it and adds tracking.
// Do not set ad.fullScreenContentDelegate or ad.paidEventHandler later, or you'll override RevenueCat's listeners.
RewardedInterstitialAd.loadAndTrack(
    withAdUnitID: "AD_UNIT_ID",
    request: Request(),
    placement: "between_levels",
    fullScreenContentDelegate: self
) { ad, error in
    if let error = error { return }
    self.rewardedInterstitialAd = ad
}

// Later, to show (unchanged):
rewardedInterstitialAd?.present(from: self, userDidEarnRewardHandler: {
    // User earned reward
})
```

### Native ads

**AdMob only** ([docs](https://developers.google.com/admob/ios/native/start)):

```swift
let adLoader = AdLoader(
    adUnitID: "AD_UNIT_ID",
    rootViewController: self,
    adTypes: [.native],
    options: nil
)
adLoader.delegate = self
adLoader.load(Request())
```

**With RevenueCat tracking:**

```swift
let adLoader = AdLoader(
    adUnitID: "AD_UNIT_ID",
    rootViewController: self,
    adTypes: [.native],
    options: nil
)
adLoader.delegate = self
// Pass nativeAdDelegate here. The adapter forwards callbacks to your delegates and adds tracking.
// The adapter uses the loader's adUnitID (set when creating the AdLoader above) for tracking.
// Do not replace adLoader.delegate after calling loadAndTrack. Avoid overwriting nativeAd.delegate
// and nativeAd.paidEventHandler on loaded ads, or you'll override RevenueCat's listeners.
adLoader.loadAndTrack(
    Request(),
    placement: "feed",
    nativeAdDelegate: self
)
```

Use standard AdMob delegates:

- `NativeAdLoaderDelegate` for `adLoader(_:didReceive:)`
- `AdLoaderDelegate` for `adLoader(_:didFailToReceiveAdWithError:)`
- `NativeAdDelegate` for native impression/click callbacks

The adapter reports loaded, displayed, revenue, and failed-to-load and forwards callbacks to your delegates.

## Swift-only adapter

This adapter is Swift-only and does not expose Objective-C entrypoints.
Use RevenueCat's base `AdTracker` APIs directly from Objective-C integrations.

## Supported ad formats

| Format | API |
| -------- | --- |
| Banner | `BannerView.loadAndTrack(request:placement:)` |
| Interstitial | `InterstitialAd.loadAndTrack(withAdUnitID:request:placement:fullScreenContentDelegate:...)` |
| App Open | `AppOpenAd.loadAndTrack(withAdUnitID:request:placement:fullScreenContentDelegate:...)` |
| Rewarded | `RewardedAd.loadAndTrack(withAdUnitID:request:placement:fullScreenContentDelegate:...)` |
| Rewarded Interstitial | `RewardedInterstitialAd.loadAndTrack(withAdUnitID:request:placement:fullScreenContentDelegate:...)` |
| Native | `AdLoader.loadAndTrack(_:placement:nativeAdDelegate:)` |

## Events tracked

All formats automatically report these RevenueCat ad events:

- **Ad Loaded** — ad successfully loaded
- **Ad Displayed** — impression recorded
- **Ad Opened** — user clicked/interacted
- **Ad Revenue** — revenue reported via AdMob's `paidEventHandler`
- **Ad Failed to Load** — load error

## Experimental API

This adapter currently relies on RevenueCat's experimental surface and exposes its Swift API as experimental via `@_spi(Experimental)`.

- APIs are available on iOS 15.0+ (`@available(iOS 15.0, *)`).
- Swift usage requires `@_spi(Experimental) import RevenueCatAdMob`.
- Treat adapter API shape as experimental and review release notes when upgrading.
- Prefer pinning to a known-good version during initial rollout.

## Test ad unit IDs

Use [Google's test ad unit IDs](https://developers.google.com/admob/ios/test-ads) during development. Examples in this doc use the official test IDs (e.g. `ca-app-pub-3940256099942544/2435281174` for banners). Replace with your own ad unit IDs before release.
