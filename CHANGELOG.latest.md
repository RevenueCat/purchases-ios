### Bugfixes
* `watchOS`: fixed crash when ran on single-target apps with Xcode 14 and before `watchOS 9.0` (#1895) via NachoSoto (@NachoSoto)
* `CustomerInfoManager`/`OfferingsManager`: improved display of underlying errors (#1888) via NachoSoto (@NachoSoto)
* `Offering`: improved confusing log for `PackageType.custom` (#1884) via NachoSoto (@NachoSoto)
* `PurchasesOrchestrator`: don't log warning if `allowSharingAppStoreAccount` setting was never explicitly set (#1885) via NachoSoto (@NachoSoto)
* Introduced type-safe `PurchasesError` and fixed some incorrect returned error types (#1879) via NachoSoto (@NachoSoto)
* `CustomerInfoManager`: fixed thread-unsafe implementation (#1878) via NachoSoto (@NachoSoto)
### New Features
* Disable SK1's `StoreKitWrapper` if SK2 is enabled and available (#1882) via NachoSoto (@NachoSoto)
* `Sendable` support (#1795) via NachoSoto (@NachoSoto)
### Other Changes
* Renamed `StoreKitWrapper` to `StoreKit1Wrapper` (#1886) via NachoSoto (@NachoSoto)
* Enabled `DEAD_CODE_STRIPPING` (#1887) via NachoSoto (@NachoSoto)
* `HTTPClient`: added `X-Client-Bundle-ID` and logged on SDK initialization (#1883) via NachoSoto (@NachoSoto)
* add link to SDK reference (#1872) via Andy Boedo (@aboedo)
* Added `StoreKit2Setting.shouldOnlyUseStoreKit2` (#1881) via NachoSoto (@NachoSoto)
* Introduced `TestLogHandler` to simplify how we test logged messages (#1858) via NachoSoto (@NachoSoto)
* `Integration Tests`: added test for purchasing `StoreProduct` instead of `Package` (#1875) via NachoSoto (@NachoSoto)
* `ErrorUtils`: added test to verify that returned errors can be converted to `ErrorCode` (#1871) via NachoSoto (@NachoSoto)
