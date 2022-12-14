### Bugfixes
* Un-deprecate `Purchases.configure(withAPIKey:appUserID:)` and `Purchases.configure(withAPIKey:appUserID:observerMode:)` (#2129) via NachoSoto (@NachoSoto)
### Other Changes
* `ReceiptFetcherTests`: refactored tests using `waitUntilValue` (#2144) via NachoSoto (@NachoSoto)
* Added a few performance improvements for `ReceiptParser` (#2124) via NachoSoto (@NachoSoto)
* `CallbackCache`: fixed reference (#2143) via NachoSoto (@NachoSoto)
* `PostReceiptDataOperation`: clarified receipt debug log (#2128) via NachoSoto (@NachoSoto)
* `CallbackCache`: avoid exposing internal mutable cache (#2136) via NachoSoto (@NachoSoto)
* `CallbackCache`: added assertion for tests to ensure we don't leak callbacks (#2137) via NachoSoto (@NachoSoto)
* `NetworkOperation`: made `Atomic` references immutable (#2139) via NachoSoto (@NachoSoto)
* `ReceiptParser`: ensure parsing never happens in the main thread (#2123) via NachoSoto (@NachoSoto)
* `PostReceiptDataOperation`: also print receipt data with `verbose` logs (#2127) via NachoSoto (@NachoSoto)
* `BasePurchasesTests`: detecting and fixing many `DeviceCache` leaks (#2105) via NachoSoto (@NachoSoto)
* `StoreKitIntegrationTests`: added test to check applying a promotional offer during subscription (#1588) via NachoSoto (@NachoSoto)
