# Magic Weather iOS - RevenueCat Sample

Magic Weather is a sample app demonstrating the proper methods for using RevenueCat's *Purchases* SDK. This sample uses only native platform components - no third-party SDKs other than the *Purchases* SDK.

Sign up for a free RevenueCat account [here](https://www.revenuecat.com).

## Requirements

This sample uses:

- Xcode 13.4.1
- iOS 14
- Swift 5

See minimum platform version requirements for RevenueCat's *Purchases* SDK [here](https://github.com/RevenueCat/purchases-ios/blob/main/Package.swift#L65).

## Features

| Feature                          | Sample Project Location                   |
| -------------------------------- | ----------------------------------------- |
| 🕹 Configuring the *Purchases* SDK  | [Lifecycle/AppDelegate.swift](MagicWeather/Sources/Lifecycle/AppDelegate.swift) |
| 💰 Building a basic paywall         | [Controllers/PaywallViewController.swift](MagicWeather/Sources/Controllers/PaywallViewController.swift) |
| 🔐 Checking subscription status     | [Controllers/WeatherViewController.swift](MagicWeather/Sources/Controllers/WeatherViewController.swift#L36) |
| 🤑 Restoring transactions           | [Controllers/UserViewController.swift](MagicWeather/Sources/Controllers/UserViewController.swift#L112) |
| 👥 Identifying the user             | [Controllers/UserViewController.swift](MagicWeather/Sources/Controllers/UserViewController.swift#L56) |
| 🚪 Logging out the user             | [Controllers/UserViewController.swift](MagicWeather/Sources/Controllers/UserViewController.swift#L86) |

## Setup & Run

### Prerequisites
- Be sure to have an [Apple Developer Account](https://developer.apple.com/account/).
    - You must join the [Apple Developer Program](https://developer.apple.com/programs/) to create In-App Purchases.
    - You must sign the [Paid Applications Agreement](https://docs.revenuecat.com/docs/getting-started#3-store-setup) and complete your [bank/tax information](https://docs.revenuecat.com/docs/getting-started#3-store-setup) to test In-App Purchases.
- Be sure to set up a [Sandbox Tester Account](https://help.apple.com/app-store-connect/#/dev8b997bee1) for testing purposes.
- Add your [App-Specific Shared Secret](https://docs.revenuecat.com/docs/itunesconnect-app-specific-shared-secret) to RevenueCat. If you don't have a RevenueCat account yet, sign up for free [here](https://app.revenuecat.com/signup).
- Be sure to set up at least one subscription on the App Store following our [guide](https://docs.revenuecat.com/docs/apple-app-store) and link it to RevenueCat:
    - Add the [product](https://docs.revenuecat.com/docs/entitlements#products) (e.g. `rc_3999_1y`) to RevenueCat's dashboard. It should match the product ID on the App Store.
    - Attach the product to an [entitlement](https://docs.revenuecat.com/docs/entitlements#creating-an-entitlement), e.g. `premium`.
    - Attach the product to a [package](https://docs.revenuecat.com/docs/entitlements#adding-packages) (e.g. `Annual`) inside an [offering](https://docs.revenuecat.com/docs/entitlements#creating-an-offering) (e.g. `sale` or `default`).
- Get your [API key](https://docs.revenuecat.com/docs/authentication#obtaining-api-keys) from your RevenueCat project.

### Steps to Run
1. Download or clone this repository
    >git clone https://github.com/RevenueCat/purchases-ios.git

2. Navigate to the `Examples` directory and open the file `MagicWeather.xcodeproj` in Xcode.
3. On the **General** tab of the project editor, match the bundle ID to your bundle ID in App Store Connect and RevenueCat.
    
    <img src="https://i.imgur.com/1z32GRo.png" alt="General tab in Xcode" width="250px" />
4. On the **Signing & Capabilities** tab of the project editor, select the correct development team from the **Team** dropdown.  
    
    <img src="https://i.imgur.com/FiDJ1Wq.png" alt="Signing & Capabilities tab in Xcode" width="250px" />
5. In the `Constants.swift` file: 
    - Replace the value for `apiKey` with the API key from your RevenueCat project.
    - Replace the value for `entitlementID` with the entitlement ID of your product in RevenueCat's dashboard.
    - Comment out the error directives.
6. Build the app and run it on your device. 

### Example Flow: Purchasing a Subscription

1. On the home page, select **Change the Weather**.
2. On the prompted payment sheet, select the product listed.
3. On the next modal, select **Subscribe**.
4. On the next modal, sign in with your Sandbox Apple ID.
5. On the next modal, select **Ok**.
6. Return to the home page and select **Change the Weather** to see the weather change!

#### Purchase Flow Demo
<img src="https://i.imgur.com/SSbRLhr.gif" width="220px" />

## Support

For more technical resources, check out our [documentation](https://docs.revenuecat.com).

Looking for RevenueCat Support? Visit our [community](https://community.revenuecat.com/).