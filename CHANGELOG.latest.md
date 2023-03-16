### Bugfixes
* `DispatchTimeInterval` & `Date`: avoid 32-bit overflows, fix `watchOS` crashes (#2342) via NachoSoto (@NachoSoto)
* Fix issue with missing subscriber attributes if set after login but before login callback (#2313) via @tonidero

### Performance Improvements
* `AppleReceipt.mostRecentActiveSubscription`: performance optimization (#2332) via NachoSoto (@NachoSoto)

### Other Changes
* `CI`: also run tests on `watchOS` (#2340) via NachoSoto (@NachoSoto)
* `RELEASING.md`: added GitHub rate limiting parameter (#2336) via NachoSoto (@NachoSoto)
* Add additional logging on init (#2324) via Cody Kerns (@codykerns)
* Replace `iff` with `if and only if` (#2323) via @aboedo
* Fix typo in log (#2315) via @nickkohrn
* `Purchases.restorePurchases`: added docstring about successful results (#2316) via NachoSoto (@NachoSoto)
* `RELEASING.md`: fixed hotfix instructions (#2304) via NachoSoto (@NachoSoto)
* `PurchaseTester`: fixed leak when reconfiguring `Purchases` (#2311) via NachoSoto (@NachoSoto)
* `ProductsFetcherSK2`: add underlying error to description (#2281) via Chris Vasselli (@chrisvasselli)