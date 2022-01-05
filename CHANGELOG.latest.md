- Ninth beta for RevenueCat framework 🎉
    100% Swift framework + ObjC support.

[Full Changelog](https://github.com/revenuecat/purchases-ios/compare/4.0.0-beta.8...HEAD)
- See our [RevenueCat V4 API update doc](docs/V4_API_Updates.md) for API updates.

### Breaking changes:
- `identify`, previously deprecated, has been removed in favor of `logIn`.
- `reset`, previously deprecated, has been removed in favor of `logOut`.
- `Package.product` has been replaced with `Package.storeProduct`. This is an abstraction of StoreKit 1's `SKProduct` and StoreKit 2's `StoreKit.Product`, but it also adds useful features like `pricePerMonth` and `priceFormatter`. The underlying objects from StoreKit are available through `StoreProduct.sk1Product` and `StoreProduct.sk2Product`.

### Xcode version requirements and updated deployment targets
`purchases-ios` v4 requires using Xcode 13.2 or newer. 
It also updates the minimum deployment targets for iOS, macOS and tvOS. 

##### Minimum deployment targets
|  | v3 | v4 |
| :-: | :-: | :-: |
| iOS | 9.0 | 11.0 |
| tvOS | 9.0 | 11.0 |
| macOS | 10.12 | 10.13 |
| watchOS | 6.2 | 6.2 (unchanged) |

### StoreKit 2 support:
- This beta introduces new methods that add functionality using StoreKit 2:
    - `showManageSuscriptions(completion:)`
    - `beginRefundRequest(forProduct:)`
    - `beginRefundRequest(forEntitlement:)`. 
    - `beginRefundRequestForActiveEntitlement()`
 - `checkTrialOrIntroductoryPriceEligibility(productIdentifiers:completion:)` now uses StoreKit 2 if it's available, to make calculation more accurate and fast.
 - A new flag has been introduced to `setup`, `useStoreKit2IfAvailable` (defaults to `false`), to use StoreKit 2 APIs for purchases instead of StoreKit 1.

### `Async` / `Await` alternative APIs
- In purchases-ios v3, `Async` / `Await` alternative APIs were made available through Xcode's auto-generation for Objective-C projects. This beta re-adds the `Async` / `Await` alternative APIs for v4.

### New APIs:

- `showManageSuscriptions(completion:)`: Use this method to show the subscription management for the current user. Depending on where they made the purchase and their OS version, this might take them to the `managementURL`, or open the iOS Subscription Management page. 
- `beginRefundRequestForCurrentEntitlement`: Use this method to begin a refund request for the purchase that granted the current entitlement.
- `beginRefundRequest(forProduct:)`: Use this method to begin a refund request for a purchase, specifying the product identifier.
- `beginRefundRequest(forEntitlement:)`: Use this method to begin a refund request for a purchase, specifying the entitlement identifier.
- Adds an optional `useStoreKit2IfAvailable` parameter to `setup` (defaults to `false`). If enabled, purchases will be done by using StoreKit 2 APIs instead of StoreKit 1. **This is currently experimental, and not all features are supported with StoreKit 2 APIs**.
- Use `verboseLogHandler` or `verboseLogs` to enable more details in logs, including file names, line numbers and method names.

### Known issues:
- Promotional offers and deferred purchases are not currently supported with StoreKit 2. If your app uses either of those, you should omit `useStoreKit2IfAvailable` in `setup` or set it to `false`.

### Other changes: 
- There are lots of under the hood improvements. If you see any issues we'd appreciate [bug reports](https://github.com/RevenueCat/purchases-ios/issues/new?assignees=&labels=bug&template=bug_report.md&title=)!
