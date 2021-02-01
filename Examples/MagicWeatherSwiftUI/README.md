#  Magic Weather SwiftUI - RevenueCat Sample

Magic Weather is a sample app demonstrating the proper methods for using RevenueCat's *Purchases* SDK. This sample uses only native platform components - no third-party SDK's other than the *Purchases* SDK.

Sign up for a free RevenueCat account [here](https://www.revenuecat.com).

## Requirements

This sample uses:

- SwiftUI
- Xcode 12.2
- iOS 14
- Swift 5

See minimum platform version requirements for RevenueCat's *Purchases* SDK [here](https://github.com/RevenueCat/purchases-ios/blob/develop/Package.swift#L65).

## Features

This sample demonstrates:

- How to [configure](Shared/Sources/Lifecycle/MagicWeatherApp.swift) an instance of *Purchases*
- How to display product prices and names, and how to build a basic [paywall](Shared/Sources/Views/PaywallView.swift)
-  How to check [subscription status](Shared/Sources/Views/WeatherView.swift#L58)
- How to [restore transactions](Shared/Sources/Views/UserView.swift#L72)
- How to [identify](Shared/Sources/ViewModels/UserViewModel.swift) users and how to [logout](Shared/Sources/ViewModels/UserViewModel.swift)

## Support

For more technical resources, check out our [documentation](https://docs.revenuecat.com).

Looking for RevenueCat Support? Visit our [Help Center](https://support.revenuecat.com/hc/en-us).
