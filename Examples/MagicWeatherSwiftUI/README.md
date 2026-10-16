#  Magic Weather SwiftUI - RevenueCat Sample

Magic Weather is a sample app demonstrating the proper methods for using RevenueCat's *Purchases* SDK. This sample uses only native platform components - no third-party SDKs other than the *Purchases* SDK.

Sign up for a free RevenueCat account [here](https://www.revenuecat.com).

## Requirements

This sample uses:

- SwiftUI
- Xcode 14.0
- iOS 15.0
- Swift 5

See minimum platform version requirements for RevenueCat's *Purchases* SDK [here](https://github.com/RevenueCat/purchases-ios/blob/main/Package.swift#L65).

## Features

| Feature                          | Sample Project Location                   |
| -------------------------------- | ----------------------------------------- |
| 🕹 Configuring the *Purchases* SDK  | [Lifecycle/MagicWeatherApp.swift](Shared/Sources/Lifecycle/MagicWeatherApp.swift) |
| 💰 Building a basic paywall         | [Views/PaywallView.swift](Shared/Sources/Views/PaywallView.swift) |
| 🔐 Checking subscription status   | [Views/WeatherView.swift](Shared/Sources/Views/WeatherView.swift#L59) |
| 🤑 Restoring transactions           | [Views/UserView.swift](Shared/Sources/Views/UserView.swift#L72) |
| 👥 Identifying the user             | [ViewModels/UserViewModel.swift](Shared/Sources/ViewModels/UserViewModel.swift) |
| 🚪 Logging out the user             | [ViewModels/UserViewModel.swift](Shared/Sources/ViewModels/UserViewModel.swift) |
| 🚩 Reacting to checkpoint results   | [Checkpoints/](MagicWeatherSwiftUI/Sources/Checkpoints) |

## Setup & Run

### Prerequisites
- Be sure to have an [Apple Developer Account](https://developer.apple.com/account/).
    - You must join the [Apple Developer Program](https://developer.apple.com/programs/) to create In-App Purchases.
    - You must sign the [Paid Applications Agreement](https://docs.revenuecat.com/docs/getting-started#3-store-setup) and complete your [bank/tax information](https://docs.revenuecat.com/docs/getting-started#3-store-setup) to test In-App Purchases.
- Be sure to set up a [Sandbox Tester Account](https://help.apple.com/app-store-connect/#/dev8b997bee1) for testing purposes.
- Add your [App-Specific Shared Secret](https://docs.revenuecat.com/docs/itunesconnect-app-specific-shared-secret) to RevenueCat. If you don't have a RevenueCat account yet, sign up for free [here](https://app.revenuecat.com/signup).
- Be sure to set up at least one subscription on the App Store and link it to RevenueCat:
    - Add the [product](https://docs.revenuecat.com/docs/entitlements#products) (e.g. `rc_3999_1y`) to RevenueCat's dashboard. It should match the product ID on the App Store.
    - Attach the product to an [entitlement](https://docs.revenuecat.com/docs/entitlements#creating-an-entitlement), e.g. `premium`.
    - Attach the product to a [package](https://docs.revenuecat.com/docs/entitlements#adding-packages) (e.g. `Annual`) inside an [offering](https://docs.revenuecat.com/docs/entitlements#creating-an-offering) (e.g. `sale` or `default`).
- If you're testing on a simulator instead of a physical device, be sure to set up your [StoreKit configuration files](https://docs.revenuecat.com/docs/apple-app-store#ios-14-only-testing-on-the-simulator).
- Get your [API key](https://docs.revenuecat.com/docs/authentication#obtaining-api-keys) from your RevenueCat project.

### Steps to Run
1. Open the file `Magic Weather SwiftUI.xcodeproj` in Xcode.
2. On the **General** tab of the project editor, match the bundle ID to your bundle ID in App Store Connect and RevenueCat.
    
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

## Checkpoints

The **Checkpoints** tab shows how an app reacts to a checkpoint result. The checkpoints API is invite-only and experimental, so the samples use `@_spi(InviteOnlyCheckpointsApi) import RevenueCatUI`.

Each sample fires a checkpoint ID. Create these checkpoints in your RevenueCat project:

| Checkpoint ID | Sample | What to attach | What the sample does |
| --- | --- | --- | --- |
| `hard_paywall` | Hard paywall | A paywall | The content stays locked until the result has an active entitlement. |
| `soft_paywall` | Soft paywall | A paywall | The content is always available. The result only updates the status. |
| `onboarding_complete` | Onboarding | Any flow | Onboarding goes to its last step when it fires the checkpoint. It does not wait for the result. |
| `entitlement_gate` | Entitlement gate | A paywall | The app checks `CustomerInfo` first. It fires the checkpoint only when the customer has no active entitlement. |

If a checkpoint ID does not exist or no rule matches, the result has no flow, and the sample shows "No completed flow".

## Support

For more technical resources, check out our [documentation](https://docs.revenuecat.com).

Looking for RevenueCat Support? Visit our [community](https://community.revenuecat.com/).