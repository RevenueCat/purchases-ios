### Bug fixes

* `EntitlementInfo.isActive` returns true if `requestDate == expirationDate` (#1684) via beylmk (@beylmk)
* Fixed usages of `seealso` (#1689) via NachoSoto (@NachoSoto)
* Fixed `ROT13.string` thread-safety (#1686) via NachoSoto (@NachoSoto)
* `PurchasesOrchestrator`: replaced calls to `syncPurchases` with posting receipt for an individual product during SK2 purchases (#1666) via NachoSoto (@NachoSoto)
