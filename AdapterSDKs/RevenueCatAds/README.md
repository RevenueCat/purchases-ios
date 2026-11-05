# RevenueCat Ads (iOS)

Show full-screen interstitial ads served by RevenueCat. Loads, impressions, clicks, and revenue are
tracked in RevenueCat automatically.

## Installation

- **Swift Package Manager:** Add the `purchases-ios-ads` package to your project:
  ```swift
  .package(url: "https://github.com/RevenueCat/purchases-ios-ads", from: "5.0.0")
  ```
  Then add the `RevenueCatAds` product to your target.

  > **Note:** If your project depends on RevenueCat via SPM, use the [`purchases-ios-spm`](https://github.com/RevenueCat/purchases-ios-spm) package (not `purchases-ios`). The published package already declares this dependency correctly, but if you add RevenueCat separately, make sure both resolve from the same `purchases-ios-spm` repository to avoid duplicate package errors.

  > **Note:** The package depends on [Prebid Mobile](https://github.com/prebid/prebid-mobile-ios) and configures its shared instance for you. Using Prebid Mobile directly in the same app is not supported.

## Setup

The API is experimental, so import it with SPI. Configure `Purchases` first, then `RCAds`:

```swift
import RevenueCat
@_spi(Experimental) import RevenueCatAds

Purchases.configure(withAPIKey: "appl_...")
try RCAds.configure()
```

`RCAds.configure()` uses the API key and server of your `Purchases` instance and throws
`AdsError.Code.notConfigured` if `Purchases` has not been configured yet. To use different values,
pass `AdsConfiguration(apiKey:serverURL:)`.

## Interstitial ads

Create an interstitial for a placement, load it ahead of time, and present it when your UI is ready:

```swift
let interstitial = AdsInterstitial(placementID: "level_complete")
interstitial.delegate = self          // AdsInterstitialDelegate: presentation events, all optional
try await interstitial.load()         // or load(completion:)

// Later:
if interstitial.isReady {
    interstitial.present(from: viewController)
}
```

**Placement:** `placementID` is a stable string that identifies where the ad is shown in your app.
RevenueCat uses it for reporting and segmentation, so use consistent values across your app.

An instance shows one ad per load. After the ad is dismissed, or loading fails, load it again.
When no ad is available, `load()` throws `AdsError.Code.noFill`; treat it as normal and continue
without an ad.

Revenue is reported per impression as an estimate: the auction's winning price in USD, recorded
when the ad is about to be shown.

All APIs are `@MainActor` and available on iOS 15.0+.

## API reference

| Type | Purpose |
| --- | --- |
| `RCAds` | `static func configure(with: AdsConfiguration = .init()) throws` |
| `AdsConfiguration` | `apiKey: String?`, `serverURL: URL?` |
| `AdsInterstitial` | `init(placementID:)`, `load() async throws`, `load(completion:)`, `present(from:)`, `isReady`, `delegate` |
| `AdsInterstitialDelegate` | failed to present(`AdsError`), expired, presented, impression, click, dismissed (all optional) |
| `AdsError` | `code` (`notConfigured`, `invalidConfiguration`, `invalidState`, `notReady`, `presentFailed`, `noFill`, `loadFailed`), `message`, `underlyingError` |

`AdsError.Code` is a struct with static constants rather than an enum, so codes can be added without
breaking your exhaustive `switch` statements.

## Experimental API

This package exposes its Swift API as experimental via `@_spi(Experimental)`.

- Swift usage requires `@_spi(Experimental) import RevenueCatAds`.
- Treat the API shape as experimental and review release notes when upgrading.

## Running the sample

The sample is `Examples/AdsIntegrationSample` (one screen: API key, server URL, placement ID,
Load/Show buttons and an event log).

1. Have a RevenueCat backend that serves ads and a public API key of a project on it.
2. Open `Examples/AdsIntegrationSample/AdsIntegrationSample.xcodeproj` and run it on an iOS Simulator
   (for a backend on your Mac, the Simulator reaches its `localhost`; a physical device does not).
3. Enter a RevenueCat API key (or set it in `Sources/Constants.swift`), keep or change the server URL
   and placement ID, tap **Load**, then **Show** once it is ready.

The sample's `Info.plist` allows plain HTTP for `localhost` only. The library itself does not touch
App Transport Security.

