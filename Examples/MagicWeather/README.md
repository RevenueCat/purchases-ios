#  Magic Weather iOS - RevenueCat Sample

Magic Weather is a sample app demonstrating the proper methods for using RevenueCat's *Purchases* SDK. This sample uses only native platform components - no third-party SDK's other than the *Purchases* SDK.

Sign up for a free RevenueCat account [here](https://www.revenuecat.com).

## Requirements

This sample uses:

- Xcode 12.2
- iOS 14
- Swift 5

See minimum platform version requirements for RevenueCat's *Purchases* SDK [here](https://github.com/RevenueCat/purchases-ios/blob/main/Package.swift#L65).

## Features

This sample demonstrates:

- How to [configure](MagicWeather/Sources/Lifecycle/AppDelegate.swift) an instance of *Purchases*
- How to display product prices and names, and how to build a basic [paywall](MagicWeather/Sources/Controllers/PaywallViewController.swift#L54)
-  How to check [subscription status](MagicWeather/Sources/Controllers/WeatherViewController.swift#L36)
- How to [restore transactions](MagicWeather/Sources/Controllers/UserViewController.swift#L112)
- How to [identify](MagicWeather/Sources/Controllers/UserViewController.swift#L56) users and how to [logout](MagicWeather/Sources/Controllers/UserViewController.swift#L86)

## Support

For more technical resources, check out our [documentation](https://docs.revenuecat.com).

Looking for RevenueCat Support? Visit our [Help Center](https://support.revenuecat.com/hc/en-us).
