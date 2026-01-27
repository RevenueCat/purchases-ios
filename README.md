<h3 align="center">😻 In-App Subscriptions Made Easy 😻</h3>

[![License](https://img.shields.io/cocoapods/l/RevenueCat.svg?style=flat)](http://cocoapods.org/pods/RevenueCat)
[![Version](https://img.shields.io/cocoapods/v/RevenueCat.svg?style=flat)](https://cocoapods.org/pods/RevenueCat)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://docs.revenuecat.com/docs/ios#section-install-via-carthage)
[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-orange.svg)](https://docs.revenuecat.com/docs/ios#section-install-via-swift-package-manager)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FRevenueCat%2Fpurchases-ios%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/RevenueCat/purchases-ios)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FRevenueCat%2Fpurchases-ios%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/RevenueCat/purchases-ios)

RevenueCat is a powerful, reliable, and free to use in-app purchase server with cross-platform support. Our open-source framework provides a backend and a wrapper around StoreKit and Google Play Billing to make implementing in-app purchases and subscriptions easy. 

Whether you are building a new app or already have millions of customers, you can use RevenueCat to:

  * Fetch products, make purchases, and check subscription status with our [native SDKs](https://docs.revenuecat.com/docs/installation). 
  * Host and [configure products](https://docs.revenuecat.com/docs/entitlements) remotely from our dashboard. 
  * Analyze the most important metrics for your app business [in one place](https://docs.revenuecat.com/docs/charts).
  * See customer transaction histories, chart lifetime value, and [grant promotional subscriptions](https://www.revenuecat.com/docs/dashboard-and-metrics/customer-history/promotionals).
  * Get notified of real-time events through [webhooks](https://docs.revenuecat.com/docs/webhooks).
  * Send enriched purchase events to analytics and attribution tools with our easy integrations.

Sign up to [get started for free](https://app.revenuecat.com/signup).

## RevenueCat.framework

*RevenueCat* is the client for the [RevenueCat](https://www.revenuecat.com/) subscription and purchase tracking system. It's 100% `Swift` and compatible with `Objective-C`.

## Migrating from Purchases v4 to v5
- See our [Migration guide](https://revenuecat.github.io/purchases-ios-docs/v5_api_migration_guide.html)

## Migrating from Purchases v3 to v4
- See our [Migration guide](https://revenuecat.github.io/purchases-ios-docs/v4_api_migration_guide.html)

## RevenueCat SDK Features
|   | RevenueCat |
| --- | --- |
✅ | Server-side receipt validation
➡️ | [Webhooks](https://docs.revenuecat.com/docs/webhooks) - enhanced server-to-server communication with events for purchases, renewals, cancellations, and more
🖥 | iOS, tvOS, macOS, watchOS, Mac Catalyst, and visionOS support
🎯 | Subscription status tracking - know whether a user is subscribed whether they're on iOS, Android or web
📊 | Analytics - automatic calculation of metrics like conversion, mrr, and churn
📝 | [Online documentation](https://docs.revenuecat.com/docs) and [SDK Reference](http://revenuecat.github.io/purchases-ios-docs/) up to date
🔀 | [Integrations](https://www.revenuecat.com/integrations) - over a dozen integrations to easily send purchase data where you need it
💯 | Well maintained - [frequent releases](https://github.com/RevenueCat/purchases-ios/releases)
📮 | Great support - [Contact us](https://revenuecat.com/support)

## Getting Started
For more detailed information, you can view our complete documentation at [docs.revenuecat.com](https://docs.revenuecat.com/docs).

Please follow the [Quickstart Guide](https://docs.revenuecat.com/docs/) for more information on how to install the SDK.

> [!TIP]
> When integrating with SPM, it is recommended to add the SPM mirror repository for faster download/integration times: https://github.com/RevenueCat/purchases-ios-spm

Or view our iOS sample apps:
- [MagicWeather](Examples/MagicWeather)
- [MagicWeather SwiftUI](Examples/MagicWeatherSwiftUI)

## IAM (Identity and Access Management) Authentication

> [!IMPORTANT]
> IAM authentication is an **experimental feature** currently in development. Only enable this if instructed by RevenueCat support.

RevenueCat now supports IAM-based authentication using JWT tokens as an alternative to API key authentication. When enabled, the SDK:
- Authenticates users via JWT tokens instead of API keys
- Automatically refreshes tokens on expiration
- Stores tokens securely in iOS Keychain
- Uses backend-issued user IDs instead of SDK-generated anonymous IDs

### Enabling IAM Authentication

IAM authentication is **opt-in** and disabled by default. To enable it, configure the SDK using `DangerousSettings`:

```swift
import RevenueCat

// Configure SDK with IAM authentication enabled
let dangerousSettings = DangerousSettings(
    autoSyncPurchases: true,
    iamAuthenticationEnabled: true  // Enable IAM
)

let configuration = Configuration.Builder(withAPIKey: "your_api_key")
    .with(dangerousSettings: dangerousSettings)
    .build()

Purchases.configure(with: configuration)
```

### Anonymous Login

When IAM is enabled, the SDK automatically performs anonymous login during initialization. The backend returns a JWT token and assigns a unique `app_user_id`:

```swift
// SDK automatically performs anonymous login
// No additional code needed - tokens are managed transparently
```

### Manual Token Refresh

While the SDK automatically refreshes tokens when they expire, you can manually refresh them:

```swift
Purchases.shared.refreshIAMTokens { error in
    if let error = error {
        print("Token refresh failed: \(error)")
    } else {
        print("Token refresh successful")
    }
}
```

### Checking IAM Status

You can check if IAM is enabled and if valid tokens are available:

```swift
// Check if IAM is enabled
if Purchases.shared.isIAMEnabled {
    print("IAM authentication is active")
}

// Check if valid tokens are present
if Purchases.shared.hasValidIAMTokens {
    print("Valid tokens available")
}
```

### Behavior Changes with IAM

When IAM is enabled:
- **Authentication**: API requests use JWT tokens (access_token) instead of API keys
- **User IDs**: The backend assigns anonymous user IDs instead of SDK generation (`$RCAnonymousID:...`)
- **Token Storage**: Tokens are securely stored in iOS Keychain
- **Auto-refresh**: Tokens automatically refresh on 401 responses
- **Backward Compatible**: When IAM is disabled (default), everything works exactly as before

### Future Support

IAM authentication currently supports anonymous users only. Future releases will add:
- Named user login (email, social authentication)
- JWT token expiry management
- Multi-user support

For detailed information about IAM authentication, please contact [RevenueCat support](https://revenuecat.com/support).

## Requirements
- Xcode 15.0+

| Platform | Minimum target |
|----------|----------------|
| iOS      | 13.0+          |
| tvOS     | 13.0+          |
| macOS    | 10.15+         |
| watchOS  | 6.2+           |
| visionOS | 1.0+           |

## SDK Reference
Our full SDK reference [can be found here](https://revenuecat.github.io/purchases-ios-docs).

## Contributing
Contributions are always welcome! To learn how you can contribute, please see the [Contributing Guide](./Contributing/CONTRIBUTING.md).
