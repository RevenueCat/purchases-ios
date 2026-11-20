# LevelPlay Manual Integration Sample

This app demonstrates manual ad-event tracking with Unity LevelPlay and RevenueCat on iOS.

The sample covers the LevelPlay formats that have public demo credentials:

- Banner
- Interstitial
- Rewarded
- An explicit load-failure example

Native, app-open, and rewarded-interstitial ads are out of scope because Unity's public LevelPlay demo
configuration does not provide ad units for them.

## Event mapping

Each LevelPlay callback is mapped to the equivalent RevenueCat `AdTracker` call:

| LevelPlay callback | RevenueCat call |
| --- | --- |
| `didLoadAd` | `trackAdLoaded` |
| `didDisplayAd` | `trackAdDisplayed` and `trackAdRevenue` |
| `didClickAd` | `trackAdOpened` |
| `didFailToLoadAd` | `trackAdFailedToLoad` |

`LPMAdInfo.auctionId` is reused as the RevenueCat impression ID so events for the same impression can be
correlated. LevelPlay reports impression revenue in USD as a decimal value; the sample converts it to micros
before calling `trackAdRevenue`.

LevelPlay revenue precision maps as follows:

| LevelPlay | RevenueCat |
| --- | --- |
| `BID` | `exact` |
| `RATE` | `publisherDefined` |
| `CPM` | `estimated` |
| Anything else | `unknown` |

## Setup

### RevenueCat

Copy `Local.xcconfig.SAMPLE` to `Local.xcconfig` in the repository root, then add a RevenueCat public SDK key:

```xcconfig
REVENUECAT_API_KEY = your-api-key
```

`Local.xcconfig` is gitignored. Do not add API keys to source files.

### LevelPlay

By default, the app uses the app key and ad unit IDs from Unity's
[official LevelPlay iOS demo app](https://github.com/ironsource-mobile/Mediation-Demo-Apps/tree/master/iOS/Swift%20SPM).
These public values initialize the SDK but do not guarantee inventory: LevelPlay can return a no-fill error with
an empty waterfall.

For reliable testing:

1. Create an iOS app in the LevelPlay dashboard.
2. Create banner, interstitial, and rewarded ad units.
3. Ensure the mediation configuration has an active ad-network instance for all three formats and that the ad
   units are included in an active mediation group.
4. In **LevelPlay > Settings > Test devices**, add the device and enable test ads for the configured network and
   ad units.
5. Override the public demo values in `Local.xcconfig`:

```xcconfig
LEVELPLAY_APP_KEY = your-app-key
LEVELPLAY_BANNER_AD_UNIT_ID = your-banner-ad-unit-id
LEVELPLAY_INTERSTITIAL_AD_UNIT_ID = your-interstitial-ad-unit-id
LEVELPLAY_REWARDED_AD_UNIT_ID = your-rewarded-ad-unit-id
```

Generate and run the sample:

```bash
tuist generate --path Examples/VanillaAdTrackingSample
```

The LevelPlay Swift package requires the `-ObjC` linker flag; the Tuist project configures it automatically.

LevelPlay's separate Integration Test Suite can verify that a mediated network serves test ads, but it should run
before interacting with the regular LevelPlay ad APIs. It therefore does not exercise the RevenueCat callbacks
demonstrated by this sample.

If every format returns no fill, confirm the test-device assignment is still active and the device is online.

## Key files

- `Sources/App.swift` initializes RevenueCat.
- `Sources/LevelPlayManager.swift` initializes LevelPlay and contains the manual event mappings.
- `Sources/Constants.swift` reads local configuration and provides Unity's public demo defaults.
- `Sources/HomeView.swift` contains the sample UI for each supported format.

## Verify events

Load and display an ad, then background the app so RevenueCat can flush pending events. The events should appear
shortly afterward in the RevenueCat dashboard. Use the error-testing screen to verify `trackAdFailedToLoad`
without waiting for a real inventory failure.
