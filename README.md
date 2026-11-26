# purchases-ios

The RevenueCat SDK for Apple platforms. It wraps StoreKit and handles purchases, entitlements, and subscription status.

[![GitHub release](https://img.shields.io/github/v/release/RevenueCat/purchases-ios?filter=!*beta*)](https://github.com/RevenueCat/purchases-ios/releases) [![License: MIT](https://img.shields.io/github/license/RevenueCat/purchases-ios)](https://github.com/RevenueCat/purchases-ios/blob/main/LICENSE) [![Swift Package Index platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FRevenueCat%2Fpurchases-ios%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/RevenueCat/purchases-ios)

[Docs](https://www.revenuecat.com/docs?utm_source=github&utm_medium=sdk_readme&utm_content=purchases-ios) · [Install guide](https://www.revenuecat.com/docs/getting-started/installation/ios?utm_source=github&utm_medium=sdk_readme&utm_content=purchases-ios) · [SDK reference](https://revenuecat.github.io/purchases-ios-docs/) · [Sample app](https://github.com/RevenueCat/purchases-ios/tree/main/Examples/MagicWeather) · [Changelog](https://github.com/RevenueCat/purchases-ios/releases) · [Migration guide](https://www.revenuecat.com/docs/sdk-guides/ios-native-4x-to-5x-migration?utm_source=github&utm_medium=sdk_readme&utm_content=purchases-ios)

## Requirements

| Requirement | Minimum |
|---|---|
| iOS | 13.0 |
| iPadOS | 13.0 |
| macOS | 10.15 |
| Mac Catalyst | Supported |
| tvOS | 13.0 |
| watchOS | 6.2 |
| visionOS | 1.0 |
| Xcode | 15.0 |

Paywalls need iOS 15, Mac Catalyst 15, or macOS 12 or later. Customer Center needs iOS 15 or Mac Catalyst 15 or later. Neither is available on tvOS, watchOS, or visionOS.

## Installation

Install with Swift Package Manager. In Xcode, choose **File > Add Package Dependencies** and enter this URL:

```text
https://github.com/RevenueCat/purchases-ios-spm.git
```

Set **Dependency Rule** to **Up to Next Major Version** from `5.0.0`, then add the `RevenueCat` product to your app target. Add `RevenueCatUI` too if you show Paywalls or Customer Center. Use `purchases-ios-spm.git` throughout your project. Referencing both it and `purchases-ios.git` causes duplicate-target errors.

Then add the In-App Purchase capability under **Signing & Capabilities**. Test Store purchases work without it.

- CocoaPods: releases end on December 2, 2026, and existing versions stay available. To keep getting updates, [migrate to Swift Package Manager](https://www.revenuecat.com/docs/sdk-guides/ios-native-cocoapods-to-spm-migration?utm_source=github&utm_medium=sdk_readme&utm_content=purchases-ios).
- Carthage: add `github "revenuecat/purchases-ios"` to your Cartfile and run `carthage update --use-xcframeworks`. See the [Carthage steps](https://www.revenuecat.com/docs/getting-started/installation/ios?utm_source=github&utm_medium=sdk_readme&utm_content=purchases-ios#other-installation-methods).

| Package | What it's for | When you need it |
|---|---|---|
| `RevenueCat` | Purchases, entitlements, subscription status | Always |
| `RevenueCatUI` | Paywalls and Customer Center | You show RevenueCat Paywalls or Customer Center |
| [`RevenueCatAdMob`](https://github.com/RevenueCat/purchases-ios-admob) | Tracks AdMob ad events in RevenueCat | You show AdMob ads. Separate package; needs iOS 15 or later |

## Quick start

Before you start, create a RevenueCat project, connect your store or start with the Test Store, and add an entitlement. See the [Quickstart](https://www.revenuecat.com/docs/getting-started/quickstart?utm_source=github&utm_medium=sdk_readme&utm_content=purchases-ios).

Configure `Purchases` once at app launch with your public API key (the Test Store key while you test). Omit `appUserID` to have RevenueCat generate an anonymous ID.

```swift
import SwiftUI
import RevenueCat

@main
struct SampleApp: App {
    init() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: <public_apple_api_key>, appUserID: <app_user_id>)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

Check whether the user has an active entitlement before you show a paywall:

```swift
let customerInfo = try await Purchases.shared.customerInfo()
if customerInfo.entitlements.all[<your_entitlement_id>]?.isActive == true {
    // User is "premium"
}
```

## What's included

- [Paywalls](https://www.revenuecat.com/docs/tools/paywalls?utm_source=github&utm_medium=sdk_readme&utm_content=purchases-ios): build single-screen or multi-step paywalls in the dashboard and change them without an app update.
- [Customer Center](https://www.revenuecat.com/docs/tools/customer-center?utm_source=github&utm_medium=sdk_readme&utm_content=purchases-ios): a self-service screen where users cancel, restore purchases, request refunds, and change plans.
- [Placements](https://www.revenuecat.com/docs/tools/targeting/placements?utm_source=github&utm_medium=sdk_readme&utm_content=purchases-ios): serve a different Offering at each paywall location in your app.
- [Test Store](https://www.revenuecat.com/docs/test-and-launch/sandbox/test-store?utm_source=github&utm_medium=sdk_readme&utm_content=purchases-ios): test purchases before you set up App Store Connect.
- [In-app currency](https://www.revenuecat.com/docs/offerings/in-app-currency?utm_source=github&utm_medium=sdk_readme&utm_content=purchases-ios): read the current Customer's in-app currency balances.
- [Redemption Links](https://www.revenuecat.com/docs/web/redemption-links?utm_source=github&utm_medium=sdk_readme&utm_content=purchases-ios): unlock a web purchase in your app from a deep link.
- [iOS subscription offers](https://www.revenuecat.com/docs/subscription-guidance/subscription-offers/ios-subscription-offers?utm_source=github&utm_medium=sdk_readme&utm_content=purchases-ios): promotional offers, the offer code redemption sheet, and win-back offers.
- [Your own purchase code](https://www.revenuecat.com/docs/migrating-to-revenuecat/sdk-or-not/finishing-transactions?utm_source=github&utm_medium=sdk_readme&utm_content=purchases-ios): set `purchasesAreCompletedBy` to keep completing purchases with your existing StoreKit code.
- [Offline entitlements](https://www.revenuecat.com/docs/customers/customer-info?utm_source=github&utm_medium=sdk_readme&utm_content=purchases-ios#offline-entitlements): the SDK grants entitlements for new subscription purchases while RevenueCat's servers are down. It's unavailable when your app completes purchases itself.
- [Trusted Entitlements](https://www.revenuecat.com/docs/customers/trusted-entitlements?utm_source=github&utm_medium=sdk_readme&utm_content=purchases-ios): the SDK checks a signature on entitlement data so your app can detect tampered responses. It runs in informational mode by default: it reports the result and doesn't block access.
- [Ad Monetization](https://www.revenuecat.com/docs/ad-monetization?utm_source=github&utm_medium=sdk_readme&utm_content=purchases-ios): report ad impressions, clicks, and revenue next to subscription data (iOS 15 or later). The [AdMob adapter](https://www.revenuecat.com/docs/getting-started/adapter-sdks/admob?utm_source=github&utm_medium=sdk_readme&utm_content=purchases-ios) tracks AdMob events automatically.

## Documentation

- [Install guide](https://www.revenuecat.com/docs/getting-started/installation/ios?utm_source=github&utm_medium=sdk_readme&utm_content=purchases-ios): Swift Package Manager, CocoaPods, and Carthage steps, and the In-App Purchase capability.
- [Configure the SDK](https://www.revenuecat.com/docs/getting-started/configuring-sdk?utm_source=github&utm_medium=sdk_readme&utm_content=purchases-ios): initialization, debug logs, Test Store, and other configuration options.
- [Displaying paywalls](https://www.revenuecat.com/docs/tools/paywalls/displaying-paywalls?utm_source=github&utm_medium=sdk_readme&utm_content=purchases-ios): present a paywall from SwiftUI or UIKit.
- [Testing purchases](https://www.revenuecat.com/docs/test-and-launch/sandbox?utm_source=github&utm_medium=sdk_readme&utm_content=purchases-ios): Test Store and sandbox testing.
- [Migration guide](https://www.revenuecat.com/docs/sdk-guides/ios-native-4x-to-5x-migration?utm_source=github&utm_medium=sdk_readme&utm_content=purchases-ios): changes in the current major version.
- [SDK reference](https://revenuecat.github.io/purchases-ios-docs/): every public class and method in the `RevenueCat` module.

## Using an AI coding agent

Your agent's training data is likely older than the current version of this SDK. Point it at current sources:

- [llms.txt](https://www.revenuecat.com/docs/llms.txt?utm_source=github&utm_medium=sdk_readme&utm_content=purchases-ios): an index of the docs. Add `.md` to any docs URL for a Markdown version.
- [RevenueCat MCP server](https://www.revenuecat.com/docs/tools/mcp?utm_source=github&utm_medium=sdk_readme&utm_content=purchases-ios): lets your agent read and change your RevenueCat project configuration.
- [AI Toolkit](https://github.com/RevenueCat/ai-toolkit): installs RevenueCat skills and the MCP server in one step.
- [Releases](https://github.com/RevenueCat/purchases-ios/releases): check the latest version before adding the dependency.

## Sample apps

- [MagicWeather](https://github.com/RevenueCat/purchases-ios/tree/main/Examples/MagicWeather): a UIKit app that configures the SDK, shows a paywall, checks subscription status, and restores purchases.
- [MagicWeatherSwiftUI](https://github.com/RevenueCat/purchases-ios/tree/main/Examples/MagicWeatherSwiftUI): a SwiftUI app that configures the SDK, builds a custom paywall from Offerings, checks subscription status, and restores purchases.

## Getting help

- Bugs: open an issue in [this repo](https://github.com/RevenueCat/purchases-ios/issues).
- Account or configuration questions: [RevenueCat Support](https://www.revenuecat.com/docs/revenuecat-support/support-first-steps?utm_source=github&utm_medium=sdk_readme&utm_content=purchases-ios).
- Discussion: [RevenueCat Community](https://community.revenuecat.com/).

## Contributing

This repository is published from the `main` branch and release tags of RevenueCat's internal development repository. Issues are tracked here. Pull requests are welcome: a maintainer reviews them here and brings accepted changes into the internal repository, so they can't be merged directly.

See the [contributing guide](https://github.com/RevenueCat/purchases-ios/blob/main/Contributing/CONTRIBUTING.md).

## License

MIT. See [LICENSE](https://github.com/RevenueCat/purchases-ios/blob/main/LICENSE).
