## 0.9.0
- Add support of checking eligibilty of introductory prices. RevenueCat will now be able to tell you definitively what version of a product you should present in your UI.

## 0.8.0
- Add support of initializing without an `appUserID`. This standardizes and simplifies behavior for apps without account systems.

## 0.7.0
- Change `restoreTransactionsForAppStoreAccount:` to take a completion block since it no long relies on the app store queue. Removed delegate methods.
- Added `updatedPurchaserInfo:` that allows force refreshing of `RCPurchaserInfo`. Useful if your app needs the latest purchaser info.
- Removed `makePurchase:quantity:`.
- Add `nonConsumablePurchases` on `RCPurchaserInfo`. Non-consumable purchases will now Just Work (tm). 

## 0.6.0
- Add support for [promotional purchases](https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/StoreKitGuide/PromotingIn-AppPurchases/PromotingIn-AppPurchases.html). 
- Adds support for `appUserId`s with non-url compatable characters

## 0.5.0
- Add support for restoring purchases via `restoreTransactionsForAppStoreAccount`
- Add support for iOS 9.0

## 0.4.0
- Add tracking of product prices to allow for real time revenue tracking on RevenueCat.com

## 0.3.0
- Improve handling of Apple and Backend errors
- Handles missing receipts case
- Fixed issue with timezone parsing

## 0.2.0
- Rename shared secret to API key
- Remove `purchaserInfoWithCompletion`, now `RCPurchases` fetches updated purchaser info automatically on `UIApplicationDidBecomeActive`.
- Remove `purchasing` KVO property

## 0.1.0

- Initial version
- Requires access to the private beta, email jacob@revenuecat.com for a key.