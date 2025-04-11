# RevenueCat Custom Entitlements Computation Mode 4.x to 5.x Migration Guide

> Note: This migration guide is only applicable if you're using RevenueCat in Custom Entitlements Computation mode. If that's not the case, or you don't know what that is, please use the regular [4.x to 5.x Migration guide](v5_api_migration_guide).

## StoreKit 2

> Warning: When upgrading to v5, you **must** configure your [In-App Purchase Key](/service-credentials/itunesconnect-app-specific-shared-secret/in-app-purchase-key-configuration) in the RevenueCat dashboard. **Purchases will fail if the key is not configured**.

Version 5.0 of the RevenueCat SDK enables full StoreKit 2 flow on the SDK and the RevenueCat backend by default.

We have been testing StoreKit 2 support in parallel to StoreKit 1 in our backend for a while and we believe it is ready for widespread use.

Here's some of the benefits you get with StoreKit 2:

- Better handling of a few specific edge cases which were unfixable with StoreKit 1:
- No more "Missing receipt" errors in Sandbox that could result in failure restoring purchases or getting trial eligibility status "unknown".
- No more "The purchased product was missing in the receipt" error that could cause an invalid receipt error when making a purchase.
- Future proofing: StoreKit 1 APIs are being progressively deprecated by Apple, and new features are being added to StoreKit 2.
- Faster processing time: More efficient and performant implementation of receipts validation. We have found that receipts validation can be ~200ms faster comparing to SK1 implementation for p95 of the requests.

The SDK will automatically use StoreKit 1 in the following platforms where StoreKit 2 is not supported: on macOS 12 or earlier, iOS 15 or earlier, iPadOS 15 or earlier, tvOS 15 or earlier, or watchOS 8 or earlier.

If you want to control the rollout of StoreKit 2, you can use the following configuration API. We recommend defaulting to `.storeKit1`, and using a remotely configured variable to control which percentage of your users receives `.storeKit2`.

```swift
Purchases.configure(with: .builder(withAPIKey: apiKey)
  .with(storeKitVersion: .storeKit1)
  .build())

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
