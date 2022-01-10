- Tenth beta for RevenueCat framework 🎉
    100% Swift framework + ObjC support.

[Full Changelog](https://github.com/revenuecat/purchases-ios/compare/4.0.0-beta.9...4.0.0-beta.10)
- See our [RevenueCat V4 API update doc](docs/V4_API_Updates.md) for API updates.

In addition to all of the changes from beta 9, beta 10 introduces the following updates:

### Breaking changes:
- A new type, `StoreTransaction`, replaces `SKPaymentTransaction` in the return types of the following methods:
    - `Purchases.purchase(product:completion:)`
    - `Purchases.purchase(package:completion:)`
    - `Purchases.purchase(package:discount:completion:)`
    - `Purchases.purchase(package:discount:completion:)`
    - `PurchasesDelegate.purchases(shouldPurchasePromoProduct:defermentBlock:)`
    - `CustomerInfo.nonSubscriptionTransactions`
- `StoreProduct.PromotionalOffer` has been renamed to `StoreProduct.StoreProductDiscount`.

### Other changes: 
- There are lots of under the hood improvements. If you see any issues we'd appreciate [bug reports](https://github.com/RevenueCat/purchases-ios/issues/new?assignees=&labels=bug&template=bug_report.md&title=)!
