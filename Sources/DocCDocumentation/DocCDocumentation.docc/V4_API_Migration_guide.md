# RevenueCat V4 API Migration Guide
Migrating from Objective-C to Swift required a number of API changes, but we feel that the changes resulted in the SDK having a more natural feel for developers.

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

## Migration steps
To start us off, our framework name changed from `Purchases` to `RevenueCat`! 😻  You'll now need to explicitly import `RevenueCat` instead of `Purchases`.

### 1. Update Framework references

##### Swift
| Before | After |
| :-: | :-: |
| `import Purchases` | `import RevenueCat` |

##### Objective-C
| Before | After |
| :-: | :-: |
| `@import Purchases;` | `@import RevenueCat;` |

#### 1.1 Update Swift Package Manager dependency (if needed)

Select your target in Xcode, then go to Build Phases, and ensure that your target's `Link Binary with Libraries` section
references `RevenueCat`, and remove the reference to `Purchases` if it was still there.
| Before | After |
| :-: | :-: |
| ![link binary with libraries before](link_binary_with_libraries_before_spm) | ![link binary with libraries after](link_binary_with_libraries_after_spm) |

**Note:**

Due to an Xcode bug, you might run into a Workspace Integrity error after upgrading, with a message that looks like 
`"Couldn't load project PurchaseTester"`. 
If this happens, you can fix it with the following steps:
1. In Xcode, go to Product -> Clean Build Folder
2. Quit and re-open Xcode

#### 1.2 Update CocoaPods dependency (if needed)

In your Podfile, update the reference to the Pod from `Purchases` to `RevenueCat`. 

| Before | After |
| :-: | :-: |
| `pod 'Purchases'` | `pod 'RevenueCat'` |

#### 1.3 Update Carthage Framework (if needed)

##### 1.3.1 Using XCFrameworks (recommended)

Select your target in Xcode, then go to Build Phases, and ensure that your target's `Link Binary with Libraries` section
references `RevenueCat`, and remove the reference to `Purchases` if it was still there.
Do the same with the Embed Frameworks section. 

| Before | After |
| :-: | :-: |
| ![link binary with libraries before](link_binary_with_libraries_before_carthage) | ![link binary with libraries after](link_binary_with_libraries_after_carthage) |
| ![embed frameworks before](embed_frameworks_before_carthage) | ![embed frameworks after](embed_frameworks_after_carthage) |

##### 1.3.2 Using Platform-specific frameworks

We highly recommend moving into XCFrameworks, since these have a simpler setup and prevent compatibility issues with 
multi-platform setups.

Carthage has a [migration guide to move into XCFrameworks available here](https://github.com/carthage/carthage#migrating-a-project-from-framework-bundles-to-xcframeworks).

After migrating into XCFrameworks, follow the steps outlined in 1.3.1 to set up the `RevenueCat.xcframework`. 

If you can't move into XCFrameworks, you will still need to update the `Link Binary with Libraries` phase as outlined
in 1.3.1 (only using a `.framework` instead of `.xcframework`).

After that, update the your `input.xcfilelist` and `output.xcfilelist` for the Run Script phase of Carthage frameworks, 
replacing `Purchases.framework` with `RevenueCat.framework`. 


## 2. Update code references

### 2.1 Automatic Migration

When building your project using v4, Xcode should automatically provide one-click fixes methods and types that have been renamed. For the most part, the migration should be doable by just building and applying Xcode's automatic fix-its when they pop up.

If you see any issues or new APIs that fix-its didn't cover, we'd appreciate [bug reports](https://github.com/RevenueCat/purchases-ios/issues/new?assignees=&labels=bug&template=bug_report.md&title=)!

### 2.2 Update references to `Purchases.foo` to `RevenueCat.foo`

You might run into compilation errors with a message like `Error: `'_' is not a member type of class 'RevenueCat.Purchases'`. 

The reason is that the class `Purchases` is no longer the parent of classes such as `Offerings`.
You should reference classes directly or as a child of `RevenueCat`, e.g. `RevenueCat.Offerings`
instead of `Purchases.Offerings`. You can also omit the framework entirely, i.e.: just using `Offerings` directly.

### 2.3 Import StoreKit (if needed)

Our V3 SDK automatically imported `StoreKit` whenever you did `import Purchases`. Due to Swift limitations, our 
V4 SDK doesn't do this automatically.

So if you're referencing StoreKit types directly, you might need to add
`import StoreKit` in Swift, and `@import StoreKit;` in Objective-C.

### 2.4 Update code to use the new types (if needed)

Step 2.1 should automatically help you convert your code into the new types. See the "New Types" section for
more information on what the new types introduce. 

### 2.5 Take advantage of our new APIs

We introduced new features for Customer Support, as well as
 [async/await alternatives](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html) for our APIs.
These are optional, but could help make your code more readable and easy to maintain.

Some additional changes include:
- Updated references of `Purchaser` to `Customer` to be more consistent across our platform
- Further abstraction away from `StoreKit` with new types.

See the "New APIs" section of this guide for more details.

## New Types

To better support `StoreKit 2`, `RevenueCat v4` introduces several new types to encapsulate data from `StoreKit 1` and `StoreKit 2`:

- ``StoreProduct``: wraps a `StoreKit.SKProduct` or `StoreKit.Product`
- ``StoreTransaction``: wraps a `StoreKit.SKPaymentTransaction` or `StoreKit.Transaction`
- ``StoreProductDiscount``: wraps a `StoreKit.SKProductDiscount` or `StoreKit.Product.SubscriptionOffer`

These types replace native StoreKit types in all public API methods that used them.

## ObjC Changes

### Type changes

`@import Purchases` is now `@import RevenueCat`

| v3 | v4 |
| ------------ | ------------------------------------- | 
| RCPurchaserInfo | RCCustomerInfo |
| RCTransaction | RCStoreTransaction |
| RCTransaction.productId | RCStoreTransaction.productIdentifier |
| RCTransaction.revenueCatId | RCStoreTransaction.transactionIdentifier |
| RCPackage.product | RCPackage.storeProduct |
| (RCPurchasesErrorCode).RCOperationAlreadyInProgressError | RCOperationAlreadyInProgressForProductError |
| RCPurchasesErrorDomain | RCPurchasesErrorCodeDomain |
| RCBackendError | <i>REMOVED</i> |
| RCErrorUtils | <i>REMOVED</i> |
| RCBackendErrorDomain | <i>REMOVED</i> |
| RCFinishableKey | <i>REMOVED</i> |
| RCReceivePurchaserInfoBlock | <i>REMOVED</i> |
| RCReceiveIntroEligibilityBlock | <i>REMOVED</i> |
| RCReceiveOfferingsBlock | <i>REMOVED</i> |
| RCReceiveProductsBlock | <i>REMOVED</i> |
| RCPurchaseCompletedBlock | <i>REMOVED</i> |
| RCDeferredPromotionalPurchaseBlock | <i>REMOVED</i> |
| RCPaymentDiscountBlock | <i>REMOVED</i> |
| RCPaymentModeNone | <i>REMOVED</i> |

#### PurchasesDelegate
| v3 | v4 |
| ------------ | ------------------------------------- | 
| purchases:didReceiveUpdatedPurchaserInfo: | purchases:receivedUpdatedCustomerInfo: |

### API changes

| v3 | v4 |
| ------------ | ------------------------------------- | 
| purchaserInfoWithCompletion: | getCustomerInfoWithCompletion: |
| invalidatePurchaserInfoCache | invalidateCustomerInfoCache |
| Purchases -restoreTransactionsWithCompletion: | Purchases -restorePurchasesWithCompletion: |
| Purchases -offeringsWithCompletion: | Purchases -getOfferingsWithCompletion: |
| Purchases -productsWithIdentifiers:completion: | Purchases -getProductsWithIdentifiers:completion: |
| Purchases -paymentDiscountForProductDiscount:product:completion: | REMOVED - Check eligibility for a discount using `getPromotionalOffer:forProductDiscount:product:completion:`, then pass the promotional offer directly to `purchasePackage:withPromotionalOffer:completion:` or `purchaseProduct:withPromotionalOffer:completion:` |
| Purchases -purchaseProduct(_:discount:_) | Purchases -purchaseProduct:withPromotionalOffer:completion: |
| Purchases -purchasePackage(_:discount:_) | Purchases -purchasePackage:withPromotionalOffer:completion: |
| Purchases -createAlias: | Purchases -logIn: |
| Purchases -identify: | Purchases -logIn: |
| Purchases -reset: | Purchases -logOut: |

## Swift Changes

### Type changes

`import Purchases` is now `import RevenueCat`

| v3 | v4 |
| ------------ | ------------------------------------- | 
| Purchases.Offering | ``Offering`` |
| Purchases.ErrorDomain | See error handling below |
| Purchases.ErrorCode.Code | See error handling below |
| Purchases.Package | ``Package`` |
| Purchases.PurchaserInfo | <strong>``CustomerInfo``</strong> |
| Purchases.Transaction | ``StoreTransaction`` |
| Purchases.Transaction.productId | ``StoreTransaction/productIdentifier`` |
| Purchases.Transaction.revenueCatId | ``StoreTransaction/transactionIdentifier`` |
| Purchases.EntitlementInfo | ``EntitlementInfo`` |
| Purchases.EntitlementInfos | ``EntitlementInfos`` |
| Purchases.PeriodType | ``PeriodType`` |
| Purchases.Store | ``Store`` |
| RCPurchaseOwnershipType | ``PurchaseOwnershipType`` |
| RCAttributionNetwork | ``AttributionNetwork`` |
| RCIntroEligibility | ``IntroEligibility`` |
| RCIntroEligibilityStatus | ``IntroEligibilityStatus`` |
| RCPaymentMode | ``StoreProductDiscount/PaymentMode-swift.enum`` |
| RCPaymentModeNone | <i>REMOVED</i> |
| Purchases.LogLevel | ``LogLevel`` |
| Purchases.Offerings | ``Offerings`` |
| Purchases.PackageType | ``PackageType`` |
| Purchases.Errors | ``ErrorCode`` |
| Purchases.ErrorCode | ``ErrorCode`` |
| Package.product | ``Package/storeProduct`` |
| Package.product.price: NSDecimalNumber | ``StoreProduct/price``: Decimal |
| Package.localizedIntroductoryPriceString: String | ``Package/localizedIntroductoryPriceString``: String? |
| RCDeferredPromotionalPurchaseBlock | ``StartPurchaseBlock`` |
| Purchases.PurchaseCompletedBlock | ``PurchaseCompletedBlock`` |
| Purchases.ReceivePurchaserInfoBlock | <i>REMOVED</i> |
| Purchases.ReceiveOfferingsBlock | <i>REMOVED</i> |
| Purchases.ReceiveProductsBlock | <i>REMOVED</i> |
| Purchases.PaymentDiscountBlock | <i>REMOVED</i> |
| Purchases.RevenueCatBackendErrorCode | <i>REMOVED</i> |
| Purchases.ErrorCode.operationAlreadyInProgressError | ``RevenueCat/ErrorCode/operationAlreadyInProgressForProductError`` |
| Purchases.ErrorUtils | <i>REMOVED</i> |
| ReadableErrorCodeKey | <i>REMOVED</i> |
| RCFinishableKey | <i>REMOVED</i> |

### API changes

| v3 | v4 |
| ------------ | ------------------------------------- | 
| invalidatePurchaserInfoCache | ``Purchases/invalidateCustomerInfoCache()`` |
| logIn(_ appUserId:, _ completion:) | ``Purchases/logIn(_:completion:)`` |
| createAlias(_ alias:, _ completion:) | ``Purchases/logIn(_:completion:)`` |
| identify(_ appUserID:, _ completion:) | ``Purchases/logIn(_:completion:)`` |
| reset(completion:) | ``Purchases/logOut(completion:)`` |
| purchaserInfo(_ completion:) | ``Purchases/getCustomerInfo(completion:)`` |
| offerings(_ completion:) | ``Purchases/getOfferings(completion:)`` |
| products(_ productIdentifiers:, _ completion:) | ``Purchases/getProducts(_:completion:)`` |
| purchaseProduct(_ product:, _ completion:) | ``Purchases/purchase(product:completion:)`` |
| purchasePackage(_ package:, _ completion:) | ``Purchases/purchase(package:completion:)`` |
| restoreTransactions(_ completion:) | ``Purchases/restorePurchases(completion:)`` |
| syncPurchases(_ completion:) | ``Purchases/syncPurchases(completion:)`` |
| paymentDiscount(for:product:completion:) | REMOVED - Get eligibility for a discount using ``Purchases/promotionalOffer(forProductDiscount:product:)``, then pass the offer directly to ``Purchases/purchase(package:promotionalOffer:)`` or ``Purchases/purchase(product:promotionalOffer:)`` |
| purchaseProduct(_:discount:_) | ``Purchases/purchase(product:promotionalOffer:completion:)`` |
| purchasePackage(_:discount:_) | ``Purchases/purchase(package:promotionalOffer:completion:)`` |

#### PurchasesDelegate
| v3 | v4 |
| ------------ | ------------------------------------- | 
| purchases(_ purchases: Purchases, didReceiveUpdated purchaserInfo: PurchaserInfo) | ``PurchasesDelegate/purchases(_:receivedUpdated:)`` |

### Error handling

Prior to the Swift migration, `Purchases` exposed errors as `NSError`s, so one could detect errors like this:
```swift
if error.domain == Purchases.ErrorDomain {
	switch Purchases.ErrorCode(_nsError: error).code {
		case .purchaseInvalidError: break
		default: break
	}
}
```
Starting from Version 4, this becomes much simpler:
```swift
if let error = error as? RevenueCat.ErrorCode {
	switch error {
		case .purchaseInvalidError: break
		default: break
	}
} else {
	// Error is a different type
}
```

## New APIs
- All applicable methods have an [async/await alternative](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html).
- ``Purchases/showManageSubscriptions(completion:)``: Use this method to show the subscription management for the current user. Depending on where they made the purchase and their OS version, this might take them to the `managementURL`, or open the iOS Subscription Management page. 
- ``Purchases/beginRefundRequestForActiveEntitlement()``: Use this method to begin a refund request for the purchase that granted the current entitlement.
- ``Purchases/beginRefundRequest(forProduct:)``: Use this method to begin a refund request for a purchase, specifying the product identifier.
- ``Purchases/beginRefundRequest(forEntitlement:)``: Use this method to begin a refund request for a purchase, specifying the entitlement identifier.
- You can now use ``Purchases/customerInfoStream`` to be notified whenever there's new ``CustomerInfo`` available, 
as an alternative to ``PurchasesDelegate/purchases(_:receivedUpdated:)``.

## Reporting undocumented issues:

Feel free to file an issue! [New RevenueCat Issue](https://github.com/RevenueCat/purchases-ios/issues/new/).

## Known Issues

#### ObjC + SPM
If you expose any Purchases objects from one target to another (see [example project](https://github.com/taquitos/SPMBug)
for what this could look like), that second target will not build due to a missing autogenerated header.
Currently there is a known bug in SPM whereby Xcode either doesn't pass the RevenueCat ObjC generated interface to SPM,
or SPM just doesn't integrate it. You can follow along: [SR-15154](https://bugs.swift.org/browse/SR-15154). 

##### Workaround: 
You must manually add the autogenerated file we committed to the repository
[RevenueCat-Swift.h](https://github.com/RevenueCat/purchases-ios/blob/main/Tests/InstallationTests/CommonFiles/RevenueCat-Swift.h)
to your project, and `#import RevenueCat-Swift.h` in your bridging header. You can see how we do this in our
[SPMInstallationTests project](https://github.com/RevenueCat/purchases-ios/tree/main/Tests/InstallationTests/SPMInstallation).
