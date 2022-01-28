- First RC for RevenueCat framework v4 🎉
    100% Swift framework + ObjC support.

[Full Changelog](https://github.com/revenuecat/purchases-ios/compare/4.0.0-beta.10...4.0.0-rc.1)
- See our [RevenueCat V4 API update doc](docs/V4_API_Updates.md) for API updates.

RC 1 introduces the following updates:

### API changes:

- `Purchases.paymentDiscount(forProductDiscount:product:completion:)` and `Purchases.paymentDiscount(forProductDiscount:product:)` have been removed. Now, instead of obtaining the `SKPaymentDiscount` from a `SKProductDiscount` to then call `purchase(package:discount:)`, you check eligibility for the promo offer by calling `checkPromotionalDiscountEligibility(forProductDiscount:product:)`, then get the `StoreProductDiscount` directly from the `StoreProduct` and pass that into `purchase(package:discount:)`. 

- `StoreProduct` and `StoreProductDiscount`, replace `SKProduct` and `SKProductDiscount` in the following methods:
    - `Purchases.getProducts(_:completion:)`
    - `Purchases.products(_:)`
    - `Purchases.purchase(product:completion:)`
    - `Purchases.purchase(product:)`
    - `Purchases.purchase(product:discount:completion:)`
    - `Purchases.purchase(product:discount:)`
    - `Purchases.purchase(package:discount:completion:)`
    - `Purchases.purchase(package:discount:)`
    - `PurchasesDelegate.purchases(shouldPurchasePromoProduct:defermentBlock:)`
- `StoreProduct.introductoryPrice` has been renamed to `StoreProduct.introductoryDiscount`
- `StoreTransaction` now includes `quantity`
- Renamed `Purchases.restoreTransactions` to `Purchases.restorePurchases`
- Lowered `StoreProduct.introductoryDiscount` availability to iOS 11.2 and equivalent OS versions
- Added several `@available` annotations for automatic migration from StoreKit types

In addition to all of the changes from beta 10, [listed here.](https://github.com/RevenueCat/purchases-ios/blob/4.0.0-beta.10/CHANGELOG.latest.md)


### Other changes: 
- There are lots of under the hood improvements. If you see any issues we'd appreciate [bug reports](https://github.com/RevenueCat/purchases-ios/issues/new?assignees=&labels=bug&template=bug_report.md&title=)!
