# Ads Integration Sample

Single-screen app that loads and presents a RevenueCat-served interstitial through `RevenueCatAds`.

## Configure

Defaults live in `Sources/Constants.swift` and can be edited in the app or overridden through
environment variables:

| Setting | Env var | Default | Notes |
| --- | --- | --- | --- |
| API key | `RC_ADS_API_KEY` | `YOUR_REVENUECAT_API_KEY` | Public API key; configures `Purchases` and `RevenueCatAds` |
| Server URL | `RC_ADS_SERVER_URL` | `http://localhost:8180` | RevenueCat backend that serves ads. Also `Purchases.proxyURL` |
| Placement ID | `RC_ADS_PLACEMENT_ID` | `interstitial` | Any stable string |
| Auto-run | `RC_ADS_AUTO_RUN` | unset | `1` loads at launch and presents as soon as the ad is loaded |

`AdsIntegrationSample-Info.plist` allows plain HTTP for `localhost` only, so the local backend works
from the iOS Simulator. A physical device cannot reach your Mac's `localhost`.

## Run

1. Have a RevenueCat backend that serves ads and a public API key of a project on it. The default
   server URL points at a local backend on port `8180`; pass `RC_ADS_SERVER_URL` or edit the field
   for a different one.
2. Open `AdsIntegrationSample.xcodeproj`. Xcode resolves the local `RevenueCatAds` package (and through
   it RevenueCat and Prebid Mobile).
3. Run the `AdsIntegrationSample` scheme on an iPhone simulator.
4. Tap **Load & Show** to load the ad and present it as soon as it is loaded, then interact with and
   dismiss it. **Load** and **Show** run the two steps separately. Taps while an ad is loading or on
   screen are ignored.

To pre-fill the fields and tap through the flow yourself, build once and launch the installed app with
the env vars through `simctl` (it forwards `SIMCTL_CHILD_*` variables to the app):

```bash
SIMCTL_CHILD_RC_ADS_API_KEY=<public api key> SIMCTL_CHILD_RC_ADS_SERVER_URL=http://localhost:8180 \
  xcrun simctl launch booted com.revenuecat.sample.AdsIntegrationSample
open -a Simulator
```

To drive the whole flow without tapping (CI, agents), add `RC_ADS_AUTO_RUN`, which does what
**Load & Show** does at launch:

```bash
SIMCTL_CHILD_RC_ADS_API_KEY=<public api key> SIMCTL_CHILD_RC_ADS_AUTO_RUN=1 \
  xcrun simctl launch --console-pty booted com.revenuecat.sample.AdsIntegrationSample
```

(Xcode: set the same variables in the scheme's Run > Arguments > Environment Variables.)

The event log shows loaded, failed (with the `AdsError` code), presented, impression, clicked and
dismissed. Everything is also printed to the Xcode console.

`Purchases` is configured at launch (from the env values only; the fields affect the ads alone), and
`RevenueCatAds` reports loaded, failed to load, displayed, opened and revenue through its ad tracker,
with mediator `RevenueCat`. The SDK sends ad events in batches when the app goes to the background or
comes back to the foreground.

Each **Load** calls `RCAds.configure(with:)` with the current field values. A real app configures once
at launch.
