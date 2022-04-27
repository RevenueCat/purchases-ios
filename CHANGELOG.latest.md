## 4.3.0

#### API updates:

- Introduced new `Storefront` type to abstract SK1's `SKStorefront` and SK2's `StoreKit.Storefront`.
- Exposed `Storefront.currentStorefront`.
- Added new `ErrorCode.offlineConnectionError` to differenciate offline errors versus the more generic `.networkError`.
- Added `Purchases-setFirebaseAppInstanceID` to allow associating RevenueCat users with Firebase.
- Added `Purchases.setPushTokenString` as an overload to `Purchases.setPushToken`.
- Renamed `PurchasesDelegate.purchases(_:shouldPurchasePromoProduct:defermentBlock:)` to `PurchasesDelegate.purchases(_ purchases: Purchases, readyForPromotedProduct product: StoreProduct, purchase:)` to clarify its usage (see #1460).

#### Other:

- Many improvements to error reporting and logging to help debugging.
- Optimized StoreKit 2 purchasing by eliminating a duplicate API request.
- A lot of under-the-hood improvements, mainly focusing on networking. If you see any issues we'd appreciate [bug reports](https://github.com/RevenueCat/purchases-ios/issues/new?assignees=&labels=bug&template=bug_report.md&title=)!

