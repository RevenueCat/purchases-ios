### New Features
* `Purchases.customerInfo()`: added overload with a new `CacheFetchPolicy` (#1608) via NachoSoto (@NachoSoto)
* `Storefront`: added `sk1CurrentStorefront` for Objective-C (#1614) via NachoSoto (@NachoSoto)

### Bug Fixes
* Fix for not being able to read receipts on watchOS (#1625) via Patrick Busch (@patrickbusch)

### Other Changes
* Added tests for `PurchasesOrchestrator` invoking `listenForTransactions` only if SK2 is enabled (#1618) via NachoSoto (@NachoSoto)
* `PurchasesOrchestrator`: removed `lazy` hack for properties with `@available` (#1596) via NachoSoto (@NachoSoto)
* `PurchasesOrchestrator.purchase(sk2Product:promotionalOffer:)`: simplified implementation with new operator (#1602) via NachoSoto (@NachoSoto)