# RevenueCatAds

RevenueCat-owned interface for serving ads. Apps talk only to `RevenueCatAds`; the third-party SDK
that requests and renders ads is an internal detail that can be swapped without changing the public
API. The v1 implementation uses [Prebid Mobile](https://github.com/prebid/prebid-mobile-ios) 3.x
(rendering API), pointed at RevenueCat's ad serving API. No AdMob or other mediation SDK is involved.

Apps do **not** `import PrebidMobile`, and no Prebid type appears in any public signature.

## Usage

Import the package with SPI to access the experimental API surface:

```swift
import RevenueCat
@_spi(Experimental) import RevenueCatAds

Purchases.configure(withAPIKey: "appl_...")
try RCAds.configure()  // API key and host are taken from Purchases

let interstitial = AdsInterstitial(placementID: "interstitial")
interstitial.delegate = self          // AdsInterstitialDelegate
try await interstitial.load()         // or load(completion:)
interstitial.present(from: viewController)
```

`RCAds.configure(with: AdsConfiguration(apiKey:serverURL:))` overrides either value. `serverURL`
defaults to `Purchases.proxyURL`, then `https://api.revenuecat.com`. The placement ID only needs to be
a stable string. When no ad is available, loading fails with `AdsError.Code.noFill`.

### Public API

| Type | Purpose |
| --- | --- |
| `RCAds` | `static func configure(with: AdsConfiguration = .init()) throws` |
| `AdsConfiguration` | `apiKey: String?`, `serverURL: URL?` |
| `AdsInterstitial` | `init(placementID:)`, `load() async throws`, `load(completion:)`, `present(from:)`, `isReady`, `delegate` |
| `AdsInterstitialDelegate` | loaded, failed(`AdsError`), presented, impression, click, dismissed (all optional) |
| `AdsError` | `code` (`notConfigured`, `invalidConfiguration`, `invalidState`, `notReady`, `noFill`, `loadFailed`), `message`, `underlyingError` |

`AdsError.Code` is a struct with static constants rather than an enum, so codes can be added without
breaking clients' exhaustive `switch` statements.

Everything is `@MainActor` and iOS 15+.

## Experimental API

This package exposes its Swift API as experimental via `@_spi(Experimental)`.

- Swift usage requires `@_spi(Experimental) import RevenueCatAds`.
- Treat the API shape as experimental and review release notes when upgrading.

## Architecture

```text
 App
  │  RCAds.configure / AdsInterstitial / AdsInterstitialDelegate      (public, RC-owned)
  ▼
┌──────────────────────────────────────────────────────────────┐
│ RevenueCatAds                                                │
│   AdsInterstitial ── state machine, error + event mapping    │
│        │                                                     │
│        ▼  AdModule / AdModuleInterstitial  (internal seam)   │
│   PrebidAdModule ── the only file that imports PrebidMobile  │
└────────┬─────────────────────────────────────────────────────┘
         │ InterstitialRenderingAdUnit (Prebid rendering API)
         ▼
  RevenueCat ad serving API
```

To swap the ad SDK, add another `AdModule` implementation and return it from `RCAds.makeModule`.

### Ad event tracking

`AdsInterstitial` reports its lifecycle to `Purchases.shared.adTracker` through the internal `AdTracking`
seam (`Tracking/`), with mediator `MediatorName.revenueCat` (`"RevenueCat"`), format `interstitial`, the
placement ID as both placement and ad unit ID, and a new impression ID per load:

| `AdsInterstitial` event | Tracked event |
| --- | --- |
| loaded | `trackAdLoaded` |
| failed to load (module failures only) | `trackAdFailedToLoad`, `mediatorErrorCode` = underlying error code |
| presented | `trackAdDisplayed` |
| clicked | `trackAdOpened` |
| impression | `trackAdRevenue`, when the winning bid has a price |

Revenue is the winning bid's CPM / 1000 in USD, with precision `exact`. Prebid's rendering ad unit does
not expose the bid response, so `PrebidAdModule` installs an event handler that behaves like Prebid's
standalone one and keeps the response. The network name is currently always `Equativ`. Tracking is
skipped (with a debug log) while `Purchases` is not configured and never affects the ad flow.

## Development

```bash
cd AdapterSDKs/RevenueCatAds
xcodebuild test -scheme RevenueCatAds -destination 'platform=iOS Simulator,name=iPhone 17'
```

Unit tests drive `AdsInterstitial` through a fake `AdModule`, so they need no network or ad SDK
runtime. Resolving the package also downloads Google Mobile Ads and AppLovin MAX, because
`prebid-mobile-ios` declares them as package dependencies; neither is linked.
