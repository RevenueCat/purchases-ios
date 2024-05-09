# RevenueCat 4.x to 5.x Migration Guide

## StoreKit 2

Version 5.0 of the RevenueCat SDK enables full StoreKit 2 flow on the SDK and the RevenueCat backend by default.

We have been testing StoreKit 2 support in parallel to StoreKit 1 in our backend for a while and we believe it is ready for widespread use.

Here's some of the benefits you get with StoreKit 2:

- Better handling of a few specific edge cases which were unfixable with StoreKit 1:
- No more "Missing receipt" errors in Sandbox that could result in failure restoring purchases or getting trial eligibility status "unknown".
- No more "The purchased product was missing in the receipt" error that could cause an invalid receipt error when making a purchase.
- Future proofing:  StoreKit 1 APIs are being progressively deprecated by Apple, and new features are being added to StoreKit 2.
- Faster processing time: More efficient and performant implementation of receipts validation. We have found that receipts validation can be ~200ms faster comparing to SK1 implementation for p95 of the requests.

In order to use StoreKit 2, you will need to configure your [In-App Purchase Key](https://www.revenuecat.com/docs/in-app-purchase-key-configuration) in the RevenueCat dashboard.

The previously deprecated configuration option `.with(usesStoreKit2IfAvailable: true)` has been removed. Remove it from your configuration option to continue using StoreKit 2.

The SDK will automatically use StoreKit 1 in the following versions where StoreKit 2 is not supported: on macOS 11 or earlier, iOS 14 or earlier, iPadOS 14 or earlier, tvOS 14 or earlier, or watchOS 7 or earlier.

If for any reason you need to always use StoreKit 1, it is possible to switch back using the following configuration API:

```swift
Purchases.configure(with: .builder(withAPIKey: apiKey)
    .with(storeKitVersion: .storeKit1)
    .build()
```

### 3rd Party Analytics SDKs

If you are using any 3rd party analytics SDKs to automatically track in-app purchases, you need to be aware most of them do not completely support logging purchases made with StoreKit 2. This is the case for some popular SDKs like Facebook, Mixpanel, OneSignal, Segment or Firebase. For these services, we recommend you use our [data integrations](https://www.revenuecat.com/integrations/).

If you're using the Firebase SDK, you'll need to follow [these instructions](https://firebase.google.com/docs/analytics/measure-in-app-purchases#swift) to log purchases made with StoreKit 2.

### Observer Mode

Version 5.0 of the SDK introduces support for observer mode when making purchases with StoreKit 2. You can enable it when configuring the SDK:

```swift
Purchases.configure(with: .builder(withAPIKey: apiKey)
		.with(observerMode: true, storeKitVersion: .storeKit2)
    .build()
```

If you're using observer mode with StoreKit 1, you will need to explicitly configure the SDK to use StoreKit 1:

```swift
Purchases.configure(with: .builder(withAPIKey: apiKey)
		.with(observerMode: true, storeKitVersion: .storeKit1)
    .build()
```

### Original Application Version

If you're converting a paid app to in-app subscriptions, and want to provide existing customers with certain features, [we recommend](https://www.revenuecat.com/blog/engineering/converting-a-paid-ios-app-to-subscriptions/) using the "original app version" field in customer info.

Because of a limitation of StoreKit 2, this field is not available if the customer is running on iOS 15, tvOS 15, macOS 12 or watchOS 8. If this is a requirement for you, we recommend switching back to StoreKit 1.

## Trusted Entitlements

Version 5.0 of the SDK enables the Informational mode for Trusted Entitlements by default.
Informational mode logs verification errors and allow you to check `customerInfo.entitlements.verificationResult` to protect your purchases from attackers.

See the [Trusted Entitlements documentation](https://www.revenuecat.com/docs/trusted-entitlements) for more information.

## Deployment Target

The minimum targets have been raised to the following:
- iOS 13.0
- tvOS 13.0
- watchOS 6.2
- macOS 10.15

## Release Assets

Pre-built `.frameworks` are no longer included in releases, only `.xcframeworks`: https://github.com/RevenueCat/purchases-ios/pull/3582

## Breaking Changes

- The scope of the View extension `onChangeOf` is changed from `public` to `internal`
  - This was never intended to be made public and to be used outside of the RevenueCat SDK
