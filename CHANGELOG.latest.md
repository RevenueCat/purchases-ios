- Fourth RC for RevenueCat framework v4 🎉
    100% Swift framework + ObjC support.

[Full Changelog](https://github.com/revenuecat/purchases-ios/compare/4.0.0-rc.3...4.0.0-rc.4)
- See our [RevenueCat V4 API update doc](Documentation.docc/V4_API_Migration_guide.md) for API updates.

RC 4 introduces the following updates:

### API changes:

#### Breaking changes: 
- Replaced `checkPromotionalDiscountEligibility` with `getPromotionalOffer`, which returns a `PromotionalOffer`. 
- Renamed `Purchases/purchase(package:discount:)` and its variants to `Purchases/purchase(package:promotionalOffer:)`. They now take a `PromotionalOffer` instead of a `StoreProductDiscount`.
- [Objective-C only]: Updated type of `StoreProduct.price` and `StoreProductDiscount.price` from `NSDecimal` to the much more useful `NSDecimalNumber`. 

#### Additions:
- Added `StoreProduct.ProductType`, and `StoreProduct.ProductCategory`, which provide extra information about whether a product is a consumable, non-consumable, auto-renewable or non-auto-renewable subscription.
- Added `currencyCode` to `StoreProduct` and `StoreProductDiscount`.
- Added `localizedPriceString` to `StoreProductDiscount`.

### Documentation: 

- Documentation can be found in https://revenuecat-docs.netlify.app/documentation/Revenuecat. 
- We've made several improvements to docstrings and added a few landing pages for the most important sections of the SDK. 

### Other changes: 
- There are lots of under the hood improvements. If you see any issues we'd appreciate [bug reports](https://github.com/RevenueCat/purchases-ios/issues/new?assignees=&labels=bug&template=bug_report.md&title=)!

### Changes from previous RC

These changes add to all of the changes from beta RC 2, [listed here.](https://github.com/RevenueCat/purchases-ios/blob/4.0.0-rc.3/CHANGELOG.latest.md).
