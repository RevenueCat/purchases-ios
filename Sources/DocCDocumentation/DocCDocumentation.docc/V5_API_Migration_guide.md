# RevenueCat 4.x to 5.x Migration Guide

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

The previously deprecated configuration option `.with(usesStoreKit2IfAvailable: true)` has been removed. Remove it from your configuration option to continue using StoreKit 2.

The SDK will automatically use StoreKit 1 in the following versions where StoreKit 2 is not supported: on macOS 12 or earlier, iOS 15 or earlier, iPadOS 15 or earlier, tvOS 15 or earlier, or watchOS 8 or earlier.

If for any reason you need to always use StoreKit 1, it is possible to switch back using the following configuration API:

```swift
Purchases.configure(with: .builder(withAPIKey: apiKey)
  // Not recommended. Remove to use StoreKit 2 by default.
  .with(storeKitVersion: .storeKit1)
  .build()
```

### 3rd Party Analytics SDKs

If you are using any 3rd party analytics SDKs to automatically track in-app purchases, you need to be aware most of them do not completely support logging purchases made with StoreKit 2. This is the case for some popular SDKs like Facebook, Mixpanel, OneSignal, Segment or Firebase. For these services, we recommend you use our [data integrations](https://www.revenuecat.com/integrations/).

If you're using the Firebase SDK, you'll need to follow [these instructions](https://firebase.google.com/docs/analytics/measure-in-app-purchases#swift) to log purchases made with StoreKit 2.

### Observer Mode is now PurchasesAreCompletedBy

Version 5.0 of the SDK  deprecates the term "Observer Mode" (and the APIs where this term was used), and replaces it
with `PurchasesAreCompletedBy` (either RevenueCat or your app).

Version 5.0 of the SDK also introduces support for tracking purchases made directly by your app calling StoreKit 2.

If you're using RevenueCat only to track purchases, and you have your own implementation of StoreKit to make purchases, you will need to explicitly provide your StoreKit version when you configure the SDK.

Add this configuration only if you previously had `observerMode: true` in your SDK initialization or your app has its own implementation of StoreKit to make purchases.

| Version 4 | Version 5 |
|------------|------------|
| <pre lang="swift"><code>Purchases.configure(with: .builder(withAPIKey: apiKey)<br>  .with(observerMode: true)<br>  .build()</code></pre> | <pre lang="swift"><code>Purchases.configure(with: .builder(withAPIKey: apiKey)<br>  // Set only if your app has its own implementation of StoreKit to make purchases.<br>   Select the version of StoreKit you're using.<br>  .with(purchasesAreCompletedBy: .myApp, storeKitVersion: /* Select .storeKit1 or .storeKit2 */)<br>  .build()</code></pre> |

#### ⚠️ Observing Purchases Completed by Your App on macOS

By default, when purchases are completed by your app using StoreKit 2 on macOS, the SDK does not detect a user's purchase until after the user foregrounds the app after the purchase has been made. If you'd like RevenueCat to immediately detect the user's purchase, call `Purchases.shared.recordPurchase(purchaseResult)` for any new purchases, like so:

```swift
let product = try await StoreKit.Product.products(for: ["my_product_id"]).first
let result = try await product?.purchase()

_ = try await Purchases.shared.recordPurchase(result)
```

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
