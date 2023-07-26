_This release is compatible with Xcode 15 beta 5 and visionOS beta 2_

### Bugfixes
* `xrOS`: fixed `SubscriptionStoreView` for visionOS beta 2 (#2884) via Josh Holtz (@joshdholtz)
### Performance Improvements
* `Perf`: update `CustomerInfo` cache before anything else (#2865) via NachoSoto (@NachoSoto)
### Other Changes
* `SimpleApp`: added support for localization (#2880) via NachoSoto (@NachoSoto)
* `TestStoreProduct`: made available on release builds (#2861) via NachoSoto (@NachoSoto)
* `Tests`: increased default logger capacity (#2870) via NachoSoto (@NachoSoto)
* `CustomEntitlementComputation`: removed `invalidateCustomerInfoCache` (#2866) via NachoSoto (@NachoSoto)
* `SimpleApp`: updates for TestFlight compatibility (#2862) via NachoSoto (@NachoSoto)
* `BasePurchasesTests`: consolidate to only initialize one `DeviceCache` (#2863) via NachoSoto (@NachoSoto)
* `Codable`: debug log entire JSON when decoding fails (#2864) via NachoSoto (@NachoSoto)
* `IntegrationTests`: replaced `Purchases.shared` with a `throw`ing property (#2867) via NachoSoto (@NachoSoto)
* `NetworkError`: 2 new tests to ensure underlying error is included in description (#2843) via NachoSoto (@NachoSoto)
* Add SPM `Package.resolved` for Xcode Cloud (#2844) via NachoSoto (@NachoSoto)
* `CustomEntitlementComputation`: added integration test for cancellations (#2849) via NachoSoto (@NachoSoto)
* `CustomEntitlementComputation`: removed `syncPurchases`/`restorePurchases` (#2854) via NachoSoto (@NachoSoto)
