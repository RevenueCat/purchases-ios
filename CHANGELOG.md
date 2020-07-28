## 3.5.2
- Feature/defer cache updates if woken from push notification
https://github.com/RevenueCat/purchases-ios/pull/288

## 3.5.1
- Removes all references to ASIdentifierManager and advertisingIdentifier. This should help with some Kids apps being rejected 
https://github.com/RevenueCat/purchases-ios/pull/286
- Fix for posting wrong duration P0D on consumables
https://github.com/RevenueCat/purchases-ios/pull/289

## 3.5.0
- Added a sample watchOS app to illustrate how to integrate in-app purchases on watchOS with RevenueCat
https://github.com/RevenueCat/purchases-ios/pull/263
- Fixed build warnings from Clang Static Analyzer
https://github.com/RevenueCat/purchases-ios/pull/265
- Added StoreKit Configuration files for local testing + new schemes configured to use them. 
https://github.com/RevenueCat/purchases-ios/pull/267
https://github.com/RevenueCat/purchases-ios/pull/270
- Added GitHub Issue Templates
https://github.com/RevenueCat/purchases-ios/pull/269

## 3.4.0
- Added `proxyKey`, useful for kids category apps, so that they can set up a proxy to send requests through. **Do not use this** unless you've talked to RevenueCat support about it. 
https://github.com/RevenueCat/purchases-ios/pull/258
- Added `managementURL` to purchaserInfo. This provides an easy way for apps to create Manage Subscription buttons that will correctly redirect users to the corresponding subscription management page on all platforms. 
https://github.com/RevenueCat/purchases-ios/pull/259
- Extra fields sent to the post receipt endpoint: `normal_duration`, `intro_duration` and `trial_duration`. These will feed into the LTV model for more accurate LTV values. 
https://github.com/RevenueCat/purchases-ios/pull/256
- Fixed a bug where if the `appUserID` was not found in `NSUserDefaults` and `createAlias` was called, the SDK would create an alias to `(null)`. 
https://github.com/RevenueCat/purchases-ios/pull/255
- Added [mParticle](https://www.mparticle.com/) as an option for attribution. 
https://github.com/RevenueCat/purchases-ios/pull/251
- Fixed build warnings for Mac Catalyst
https://github.com/RevenueCat/purchases-ios/pull/247
- Simplified Podspec and minor cleanup
https://github.com/RevenueCat/purchases-ios/pull/248


## 3.3.1
- Fixed version numbers that accidentally included the `-SNAPSHOT` suffix

## 3.3.0
- Reorganized file system structure for the project
	https://github.com/RevenueCat/purchases-ios/pull/242
- New headers for observer mode and platform version
    https://github.com/RevenueCat/purchases-ios/pull/237
    https://github.com/RevenueCat/purchases-ios/pull/240
    https://github.com/RevenueCat/purchases-ios/pull/241
- Fixes subscriber attributes migration edge cases
	https://github.com/RevenueCat/purchases-ios/pull/233
- Autodetect appUserID deletion
    https://github.com/RevenueCat/purchases-ios/pull/232
    https://github.com/RevenueCat/purchases-ios/pull/236
- Removes old trello link
    https://github.com/RevenueCat/purchases-ios/pull/231
- Removes unused functions
    https://github.com/RevenueCat/purchases-ios/pull/228
- Removes unnecessary no-op call to RCBackend's postSubscriberAttributes
	https://github.com/RevenueCat/purchases-ios/pull/227
- Fixes a bug where subscriber attributes are deleted when an alias is created.
    https://github.com/RevenueCat/purchases-ios/pull/222
- Fixes crash when payment.productIdentifier is nil
    https://github.com/RevenueCat/purchases-ios/pull/226
- Updates invalidatePurchaserInfoCache docs 
    https://github.com/RevenueCat/purchases-ios/pull/223

## 3.2.2
- Fixed build warnings about nil being passed to callees that require non-null parameters
    https://github.com/RevenueCat/purchases-ios/pull/216

## 3.2.1
- Fixed build warnings on tvOS and API availability checks
    https://github.com/RevenueCat/purchases-ios/pull/212

## 3.2.0
- Added support for WatchOS and tvOS, fixed some issues with pre-processor macro checks on different platforms. 
    https://github.com/RevenueCat/purchases-ios/pull/183

## 3.1.2
- Added an extra method, `setPushTokenString`, to be used by multi-platform SDKs that don't 
have direct access to the push token as `NSData *`, but rather as `NSString *`.
    https://github.com/RevenueCat/purchases-ios/pull/208

## 3.1.1
- small fixes to docs and release scripts: 
    - the release script was referencing a fastlane lane that was under the group ios, 
    so it needs to be called with ios first
    - the docs for setPushToken in RCPurchases.m say to pass an empty string or nil to erase data, 
    however since the param is of type NSData, you can't pass in an empty string.
    
    https://github.com/RevenueCat/purchases-ios/pull/203
    
## 3.1.0
- Added Subscriber Attributes, which allow developers to store additional, structured information 
for a user in RevenueCat. More info: // More info: https://docs.revenuecat.com/docs/user-attributes.
https://github.com/RevenueCat/purchases-ios/pull/196
- Fixed an issue where the completion block of `purchaserInfoWithCompletion` would get called more than once if cached information existed and was stale. https://github.com/RevenueCat/purchases-ios/pull/199
- Exposed `original_purchase_date`, which can be useful for migrating data for developers who don't increment the build number on every release and therefore can't rely on it being different on all releases.
- Addressed a couple of build warnings: https://github.com/RevenueCat/purchases-ios/pull/200

## 3.0.4
- Fixed an issue where Swift Package Manager didn't pick up the new Caching group from 3.0.3 https://github.com/RevenueCat/purchases-ios/issues/176

## 3.0.3
- Added new method to invalidate the purchaser info cache, useful when promotional purchases are granted from outside the app. https://github.com/RevenueCat/purchases-ios/pull/168
- Made sure we dispatch offerings, and purchaser info https://github.com/RevenueCat/purchases-ios/pull/146

## 3.0.2
- Fixes an issue where Apple Search Ads attribution information would be sent even if the user hadn't clicked on 
a search ad.

## 3.0.1
- Adds observer_mode to the backend post receipt call.

## 3.0.0
- Support for new Offerings system.
- Deprecates `makePurchase` methods. Replaces with `purchasePackage`
- Deprecates `entitlements` method. Replaces with `offerings`
- See our migration guide for more info: https://docs.revenuecat.com/v3.0/docs/offerings-migration
- Added `Purchases.` prefix to Swift classes to avoid conflicts https://github.com/RevenueCat/purchases-ios/issues/131
- Enabled base internationalisation to silence a warning (#119)
- Migrates tests to Swift 5 (#138)
- New identity changes (#133):
  - The `.createAlias()` method is no longer required, use .identify() instead
  - `.identify()` will create an alias if being called from an anonymous ID generated by RevenueCat
  - Added an `isAnonymous` property to `Purchases.shared`
  - Improved offline use

## 2.6.1
- Support for Swift Package Manager
- Adds a conditional to protect against nil products or productIdentifier (https://github.com/RevenueCat/purchases-ios/pull/129)

## 2.6.0
- Deprecates `activeEntitlements` in `RCPurchaserInfo` and adds `entitlements` object to `RCPurchaserInfo`. For more info look into https://docs.revenuecat.com/docs/purchaserinfo

## 2.5.0
- **BREAKING CHANGE**: fixed a typo in `addAttributionData` Swift's name.
- Error logs for AppsFlyer if using deprecated `rc_appsflyer_id`
- Error logs for AppsFlyer if missing networkUserID

## 2.4.0
- **BUGFIX**: `userId` parameter in identify is not nullable anymore.
- **DEPRECATION**: `automaticAttributionCollection` is now deprecated in favor of `automaticAppleSearchAdsAttributionCollection` since it's a more clear name.
- **NEW FEATURE**: UIKitForMac support.
- **NEW FEATURE**: Facebook Ads Attribution support https://docs.revenuecat.com/docs/facebook-ads.

## 2.3.0
- `addAttribution` is now a class method that can be called before the SDK is configured.
- `addAttribution` will automatically add the `rc_idfa` and `rc_idfv` parameters if the `AdSupport` and `UIKit` frameworks are included, respectively.
- A network user identifier can be send to the `addAttribution` function, replacing the previous `rc_appsflyer_id` parameter.
- Apple Search Ad attribution can be automatically collected by setting the `automaticAttributionCollection` boolean to `true` before the SDK is configured.
- Adds an optional configuration boolean `observerMode`. This will set the value of `finishTransactions` at configuration time.
- Header updates to include client version which will be used for debugging and reporting in the future.

## 2.2.0
- Adds subscription offers

## 2.1.1
- Avoid refreshing receipt everytime restore is called

## 2.1.0
- Adds userCancelled as a parameter to the completion block of the makePurchase function.
- Better error codes.

## 2.0.0
- Refactor to all block based methods
- Optional delegate method to receive changes in Purchaser Info
- Ability to turn on detailed logging by setting `debugLogsEnabled`

## 1.2.1
- Adds support for Tenjin

## 1.2.0
- Singleton management handled by the SDK
- Adds reset, identify and create alias calls

## 1.1.5
- Conform RCPurchasesDelegate to NSObject
- Adds requestDate to the purchaser info to avoid edge cases
- Add iOS 11.2 availability annotations

## 1.1.4
- Make RCPurchases initializer return a non-optional

## 1.1.3
- Add option for disabling transaction finishing.

## 1.1.2
- Fix to ensure prices are properly collected when using entitlements

## 1.1.1
- Delegate methods now only dispatch if they are not on the main thread. This makes sure the cached PurchaserInfo is delivered on setting the delegate.
- Allow developer to indicate anonymous ID behavior
- Add "Purchases.h" to CocoaPods headers

## 1.1.0
- Attribution! You can now pass attribution data from Apple Search Ads, AppsFlyer, Adjust and Branch. You can then view the ROI of your campaigns, including revenue coming from referrals.

## 1.0.5
- Fix for entitlements will now have null active products if the product is not available from StoreKit

## 1.0.4
- Fix version number in Plist for real

## 1.0.3
- Fix version number in Plist

## 1.0.2
- Improved error handling for fetching entitlements
- Delegate methods are now guaranteed to run on the main thread

## 1.0.1
- Fix a bug with parsing dates for Thai locales

## 1.0.0
- Oh my oh whoa! We made it to version one point oh!
- Entitlements now supported by the SDK. See [the guide](https://docs.revenuecat.com/v1.0/docs/entitlements) for more info.
- Improved caching of `RCPurchaserInfo`

## 0.12.0
- Remove Carthage dependencies
- Add delegate methods for restoring
- Allow RCPurchases to be instantiated with a UserDefaults object, useful for syncing between extensions

## 0.11.0
- RCPurchases now caches the most recent RCPurchaserInfo. Apps no longer need to implement there own offline caching of subscription status.
- Change block based methods to use delegate. restoreTransactions and updatePurchaserInfo no longer take blocks. This means all new RCPurchaserInfo objects will be sent via the delegate methods.
- macOS support. Purchases now works with macOS. Contact jacob@revenuecat.com if interested in beta testing.

## 0.10.2
- Workaround for a StoreKit issue (38476489) where priceLocale is missing on promotional purchases

## 0.10.1
- Fix cache preventing prices from being posted

## 0.10.0
- Prevent race conditions refreshing receipts.
- Make processing of multiple receipt posts more efficient.
- Add support for original application version so users can be grandfathered easily

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
