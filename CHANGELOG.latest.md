### Improvements:
* Improved purchasing logs, added promotional offer information (#1725) via NachoSoto (@NachoSoto)
* `PurchasesOrchestrator`: don't log attribute errors if there are none (#1742) via NachoSoto (@NachoSoto)
* `FatalErrorUtil`: don't override `fatalError` on release builds (#1736) via NachoSoto (@NachoSoto)
* `SKPaymentTransaction`: added more context to warnings about missing properties (#1731) via NachoSoto (@NachoSoto)
* New SwiftUI Purchase Tester example (#1722) via Josh Holtz (@joshdholtz)
* update docs for `showManageSubscriptions` (#1729) via aboedo (@aboedo)
* `PurchasesOrchestrator`: unify finish transactions between SK1 and SK2 (#1704) via NachoSoto (@NachoSoto)
* `SubscriberAttribute`: converted into `struct` (#1648) via NachoSoto (@NachoSoto)
* `CacheFetchPolicy.notStaleCachedOrFetched`: added warning to docstring (#1708) via NachoSoto (@NachoSoto)
* Clear cached offerings and products after Storefront changes (2/4) (#1583) via Juanpe Catalán (@Juanpe)
* `ROT13`: optimized initialization and removed magic numbers (#1702) via NachoSoto (@NachoSoto)

### Changes:
* Replaced `CustomerInfo.nonSubscriptionTransactions` with a new non-`StoreTransaction` type (#1733) via NachoSoto (@NachoSoto)
* `Purchases.configure`: added overload taking a `Configuration.Builder` (#1720) via NachoSoto (@NachoSoto)
* Extract Attribution logic out of Purchases (#1693) via Joshua Liebowitz (@taquitos)
* Remove create alias (#1695) via Joshua Liebowitz (@taquitos)

All attribution APIs can now be accessed from `Purchases.shared.attribution`.

### Fixes:
* `logIn`/`logOut`: sync attributes before aliasing (#1716) via NachoSoto (@NachoSoto)
* `Purchases.customerInfo(fetchPolicy:)`: actually use `fetchPolicy` parameter (#1721) via NachoSoto (@NachoSoto)
* `PurchasesOrchestrator`: fix behavior dealing with `nil` `SKPaymentTransaction.productIdentifier` during purchase (#1680) via NachoSoto (@NachoSoto)
* `PurchasesOrchestrator.handlePurchasedTransaction`: always refresh receipt data (#1703) via NachoSoto (@NachoSoto)