# AdMob Integration Sample - RevenueCat Ad Event Tracking (iOS)

This sample app demonstrates how to integrate Google AdMob with RevenueCat's ad event tracking API to monitor ad performance and revenue on iOS.

## Overview

This example shows how to track **all 5 RevenueCat ad events** across five different AdMob ad formats:

### Ad Events Tracked
1. ✅ **Ad Loaded** - When an ad successfully loads
2. ✅ **Ad Displayed** - When an ad is shown to the user (impression)
3. ✅ **Ad Opened** - When a user clicks/interacts with the ad
4. ✅ **Ad Revenue** - When an ad generates revenue (via AdMob's paid event handler)
5. ✅ **Ad Failed to Load** - When an ad fails to load (includes error codes)

### Ad Formats Demonstrated
- **Banner Ads** - Always visible at the top of the screen
- **Interstitial Ads** - Full-screen ads triggered by user action
- **App Open Ads** - Full-screen ads designed for app launch/resume scenarios
- **Native Ads** - Custom-styled ads with text and images integrated into the app's UI
- **Native Video Ads** - Custom-styled ads with video content integrated into the app's UI

---

## 🚨 Important Notice: Experimental API

**This sample uses RevenueCat's `@_spi(Experimental)` API for ad tracking.**

⚠️ **What this means:**
- This is an experimental API that may change without warning
- No compatibility guarantees are provided
- Designed for internal RevenueCat use and preview features

### Required Setup

To use this API, you need to opt-in at the code level:

**Code-level opt-in** (already done in `AdMobManager.swift`):
```swift
@_spi(Experimental) import RevenueCat

class AdMobManager: NSObject, ObservableObject {
    // ...
}
```

The `@_spi(Experimental)` annotation indicates access to RevenueCat's experimental APIs.

---

## Requirements

- **Xcode 15.0+** - Required for Swift 5.9
- **iOS 15.0+** - Required for RevenueCat AdTracker API (RevenueCat SDK itself supports iOS 13.0+)
- **Swift 5.9+** - Defined in [Tuist/Package.swift](Tuist/Package.swift#L1)
- **RevenueCat SDK 5.56.1+** - Defined in [Tuist/Package.swift](Tuist/Package.swift#L7)
- **Google Mobile Ads SDK 11.2.0** - Defined in [Tuist/Package.swift](Tuist/Package.swift#L8)
- **Tuist** - For project generation

---

## Features & Code Examples

| Feature | Sample Project Location |
|---------|------------------------|
| 🔧 RevenueCat SDK initialization | [App.swift:10](Sources/App.swift#L10) |
| 🔧 AdMob SDK initialization | [App.swift:14](Sources/App.swift#L14) |
| 📊 Banner ad tracking | [AdMobManager.swift:23](Sources/AdMobManager.swift#L23) |
| 📊 Interstitial ad tracking | [AdMobManager.swift:45](Sources/AdMobManager.swift#L45) |
| 📊 App Open ad tracking | [AdMobManager.swift:103](Sources/AdMobManager.swift#L103) |
| 📊 Native ad tracking | [AdMobManager.swift:161](Sources/AdMobManager.swift#L161) |
| 💰 Ad revenue tracking | [AdMobManager.swift:233](Sources/AdMobManager.swift#L233) |
| ❌ Ad failure tracking | [AdMobManager.swift:250](Sources/AdMobManager.swift#L250) |
| 🎨 SwiftUI integration | [HomeView.swift](Sources/HomeView.swift) |

---

## Setup & Run

### 1. Prerequisites

Before running the sample:

1. **Get a RevenueCat API Key**
   - Sign up for a free account at [revenuecat.com](https://www.revenuecat.com)
   - Get your project API key from the [RevenueCat Dashboard](https://app.revenuecat.com/)

2. **Install Tuist** (if not already installed)
   ```bash
   curl -Ls https://install.tuist.io | bash
   ```

3. **AdMob Setup** (Optional for testing)
   - This sample uses **Google's official test ad unit IDs** (see below)
   - No AdMob account needed to run the sample as-is
   - For production use, create an [AdMob account](https://admob.google.com/) and replace with your own ad unit IDs

### 2. Configure the App

1. **Clone and navigate to the project**
   ```bash
   cd Examples/AdMobIntegrationSample
   ```

2. **Update your RevenueCat API key**

   Edit `AdMobIntegrationSample/Sources/Constants.swift`:
   ```swift
   static let revenueCatAPIKey = "YOUR_REVENUECAT_API_KEY_HERE"
   ```

3. **Install dependencies and generate project**
   ```bash
   tuist install
   tuist generate
   ```

### 3. Run the App

1. Open the generated Xcode project:
   ```bash
   open AdMobIntegrationSample.xcodeproj
   ```

2. Select a simulator or connected device (iOS 15.0+)

3. Build and run (⌘R)

### 4. Monitor Ad Events

**View event tracking in Xcode Console:**
1. Open the **Console** in Xcode (⌘⇧C)
2. Interact with the ads in the app to trigger events

**Example console output:**
```
✅ Banner loaded
✅ Tracked: Loaded (format=banner)
👁 Banner impression
✅ Tracked: Displayed (format=banner)
✅ Tracked: Revenue (format=banner) - $0.00015
👆 Banner clicked
✅ Tracked: Opened (format=banner)
```

---

## AdMob Ad Unit IDs

This sample uses **Google's official test ad unit IDs**:

| Ad Format | Ad Unit ID | Usage | Status |
|-----------|----------------|-------|--------|
| **Banner** | `ca-app-pub-3940256099942544/2435281174` | Google's test banner ad | ✅ Working |
| **Interstitial** | `ca-app-pub-3940256099942544/4411468910` | Google's test interstitial ad | ✅ Working |
| **App Open** | `ca-app-pub-3940256099942544/5575463023` | Google's test app open ad | ✅ Working |
| **Native** | `ca-app-pub-3940256099942544/2247696110` | Google's test native ad (text + images) | ⚠️ Unreliable |
| **Native Video** | `ca-app-pub-3940256099942544/1044960115` | Google's test native video ad | ⚠️ Unreliable |
| **Error Testing** | `"invalid-ad-unit-id"` | Triggers load failures for error handling demo | ✅ Working |

### About These Ad Units

✅ **Official test IDs** - Provided by Google for development and testing
✅ **Always serve test ads** - No risk of affecting production metrics
⚠️ **Native ad limitation** - Test IDs for native ads don't work reliably (see below)

### ⚠️ Important: Native Ads and Test Ad Unit IDs

**Google's official test ad unit IDs do not work reliably with native ads.**

While Google provides test ad unit IDs for banner and interstitial ads, the official test IDs for native ads often fail to load or behave inconsistently.

**Recommended approach for testing native ads:**
1. Create production ad units in your AdMob account
2. Update the ad unit IDs in `Sources/Constants.swift` with your production ad unit IDs
3. Configure your device as a test device in AdMob settings (or use a simulator which is automatically treated as a test device)

This ensures you receive test ads (no real impressions) while having reliable ad loading behavior during development.

### Setting Up Your Own Ad Units

To use your own AdMob ad units:
1. Create a free AdMob account at [admob.google.com](https://admob.google.com)
2. Create ad units for each format you want to test
3. Replace the ad unit IDs in `Sources/Constants.swift`
4. Configure your test device in AdMob settings to receive test ads without affecting metrics

### Error Testing Note

AdMob does not provide an official "error trigger" test ad unit ID. This sample uses an invalid ID (`"invalid-ad-unit-id"`) to simulate load failures and demonstrate error tracking with RevenueCat.

---

## How It Works

### Integration Architecture

```
┌─────────────┐
│   AdMob SDK │
│  (Load Ads) │
└──────┬──────┘
       │
       │ Ad Events (paidEventHandler, delegates)
       ▼
┌──────────────────┐
│  AdMobManager    │
│  (Event Mapper)  │
└──────┬───────────┘
       │
       │ Mapped Events
       ▼
┌────────────────────────┐
│  RevenueCat AdTracker  │
│  (Track Analytics)     │
└────────────────────────┘
```

### Key Integration Points

#### 1. **Ad Revenue Tracking**

AdMob provides revenue data via paid event handler:

```swift
banner.paidEventHandler = { [weak self] adValue in
    self?.trackAdRevenue(
        adFormat: .banner,
        adUnitID: Constants.AdMob.bannerAdUnitID,
        placement: placement,
        responseInfo: banner.responseInfo,
        adValue: adValue
    )
}
```

Inside the tracking method:

```swift
private func trackAdRevenue(adFormat: AdFormat, adUnitID: String, placement: String,
                           responseInfo: GADResponseInfo?, adValue: GADAdValue) {
    let data = AdRevenue(
        networkName: responseInfo?.loadedAdNetworkResponseInfo?.adNetworkClassName ?? "Google AdMob",
        mediatorName: .adMob,
        adFormat: adFormat,
        placement: placement,
        adUnitId: adUnitID,
        impressionId: responseInfo?.responseIdentifier ?? "",
        revenueMicros: Int(adValue.value.int64Value),  // Already in micros
        currency: adValue.currencyCode,
        precision: mapPrecision(adValue.precision)
    )
    Purchases.shared.adTracker.trackAdRevenue(data) { }
    let revenue = Double(adValue.value.int64Value) / 1_000_000.0
    print("✅ Tracked: Revenue (format=\(adFormat)) - $\(revenue)")
}
```

**Important:** AdMob provides revenue in **micros** (1/1,000,000 of currency unit), which matches RevenueCat's expected format.

#### 2. **Precision Type Mapping**

AdMob precision types are mapped to RevenueCat types:

| AdMob GADAdValuePrecision | RevenueCat AdRevenue.Precision | Meaning |
|---------------------------|-------------------------------|---------|
| `.precise` | `.exact` | Publisher is paid for this impression |
| `.estimated` | `.estimated` | Estimate; publisher might not be paid |
| `.publisherProvided` | `.publisherDefined` | Value provided by publisher |
| `.unknown` | `.unknown` | Precision unknown |

See [AdMobManager.swift:263](Sources/AdMobManager.swift#L263) for implementation.

#### 3. **Event Timing**

Different ad formats track events at different times:

**Banner Ads:**
- `Loaded`: `GADBannerViewDelegate.bannerViewDidReceiveAd()`
- `Displayed`: `GADBannerViewDelegate.bannerViewDidRecordImpression()` (automatic)
- `Opened`: `GADBannerViewDelegate.bannerViewDidRecordClick()`
- `Revenue`: `paidEventHandler` closure

**Interstitial Ads:**
- `Loaded`: `GADInterstitialAd.load()` completion handler
- `Displayed`: `GADFullScreenContentDelegate.adDidRecordImpression()`
- `Opened`: `GADFullScreenContentDelegate.adDidRecordClick()`
- `Revenue`: `paidEventHandler` closure

**App Open Ads:**
- `Loaded`: `GADAppOpenAd.load()` completion handler
- `Displayed`: `GADFullScreenContentDelegate.adDidRecordImpression()`
- `Opened`: `GADFullScreenContentDelegate.adDidRecordClick()`
- `Revenue`: `paidEventHandler` closure

**Native Ads (both regular and video):**
- `Loaded`: `GADAdLoaderDelegate.adLoader(_:didReceive:)` callback
- `Displayed`: **Automatic** - `GADNativeAdDelegate.nativeAdDidRecordImpression()`
- `Opened`: `GADNativeAdDelegate.nativeAdDidRecordClick()` callback
- `Revenue`: `paidEventHandler` closure

**Note:** Native and native video ads use the same tracking mechanisms. The only difference is the ad unit ID used and the content returned (with or without video). App Open ads follow the same pattern as Interstitial ads but are designed for app launch/resume scenarios.

**iOS Native Ad Advantage:** Unlike Android, iOS automatically tracks native ad impressions via the `GADNativeAdDelegate.nativeAdDidRecordImpression()` method when using `GADNativeAdView`. No manual impression tracking is required.

---

## Common Issues & Troubleshooting

### Issue: "Missing RevenueCat API key" or SDK initialization fails

**Solution:** Make sure you've updated `Sources/Constants.swift` with your actual RevenueCat API key from the [RevenueCat Dashboard](https://app.revenuecat.com/).

### Issue: Ads not loading

**Possible causes:**
1. **No internet connection** - Ensure device/simulator has internet access
2. **AdMob SDK still initializing** - Wait a few seconds after app launch
3. **Test device not configured** - Simulators are automatically test devices; real devices may take 15 minutes to 24 hours to be recognized

### Issue: Native ads not loading with test ad unit IDs

**Cause:** Google's official test ad unit IDs for native ads (e.g., `ca-app-pub-3940256099942544/2247696110`) do not work reliably. They often fail to load or behave inconsistently.

**Solution:** Use production ad unit IDs configured with test devices:
1. Create native and native video ad units in your [AdMob account](https://admob.google.com)
2. Replace the test IDs in `Sources/Constants.swift` with your production ad unit IDs
3. Configure your device as a test device in AdMob settings (simulators are automatically test devices)
4. You'll receive test ads without affecting your production metrics

This limitation only affects native and native video ad formats. Banner and interstitial test IDs work as expected.

### Issue: "Invalid request" error on real device

**Solution:** Real devices might not be registered as test devices yet. Either:
- Wait up to 24 hours for AdMob to recognize your device as a test device
- Add your device as a test device in AdMob settings

### Issue: Not seeing revenue events

**Cause:** AdMob test ads may not always trigger paid event handlers.

**Note:** Revenue tracking works reliably in production with real ads. Test ads may have inconsistent revenue event behavior.

### Issue: Build errors about `@_spi(Experimental)`

**Solution:** Make sure you have:
1. The latest RevenueCat SDK (5.56.1 or later)
2. The `@_spi(Experimental) import RevenueCat` statement in your code

### Issue: Tuist commands not working

**Solution:** Install Tuist if not already installed:
```bash
curl -Ls https://install.tuist.io | bash
```

Then run:
```bash
tuist install
tuist generate
```

---

## Project Structure

```
AdMobIntegrationSample/
├── Sources/
│   ├── App.swift           # App entry point, SDK initialization
│   ├── Constants.swift     # API keys & ad unit IDs with documentation
│   ├── AdMobManager.swift  # Ad loading and tracking logic
│   └── HomeView.swift      # SwiftUI UI with ad integration
├── Project.swift           # Tuist project configuration
└── README.md               # This file
```

---

## License

This sample app is part of the RevenueCat SDK and follows the same license terms.
