### New Features
* Add `StoreProduct.pricePerYear` (#2462) via NachoSoto (@NachoSoto)

### Bugfixes
* `HTTPClient`: don't assume error responses are JSON (#2529) via NachoSoto (@NachoSoto)
* `OfferingsManager`: return `Offerings` from new disk cache when server is down (#2495) via NachoSoto (@NachoSoto)
* `OfferingsManager`: don't consider timeouts as configuration errors (#2493) via NachoSoto (@NachoSoto)

### Performance Improvements
* Perf: `CustomerInfoManager.fetchAndCacheCustomerInfoIfStale` no longer fetches data if stale (#2508) via NachoSoto (@NachoSoto)

### Other Changes
* `Integration Tests`: workaround for `XCTest` crash after a test failure (#2532) via NachoSoto (@NachoSoto)
* `CircleCI`: save test archive on `loadshedder-integration-tests` (#2530) via NachoSoto (@NachoSoto)
* `SK2StoreProduct`: simplify `currencyCode` extraction (#2485) via NachoSoto (@NachoSoto)
* `PurchaseTesterSwiftUI`: added visual feedback for purchase success/failure (#2519) via NachoSoto (@NachoSoto)
* `PurchaseTesterSwiftUI`: fixed macOS UI (#2516) via NachoSoto (@NachoSoto)
* `MainThreadMonitor`: fixed flakiness in CI (#2517) via NachoSoto (@NachoSoto)
* Update `fastlane-plugin-revenuecat_internal` (#2511) via Cesar de la Vega (@vegaro)
* `Xcode`: fixed `.storekit` file references in schemes (#2505) via NachoSoto (@NachoSoto)
* `MainThreadMonitor`: don't monitor thread if debugger is attached (#2502) via NachoSoto (@NachoSoto)
* `Purchases`: avoid double-log when setting `delegate` to `nil` (#2503) via NachoSoto (@NachoSoto)
* `Integration Tests`: added snapshot test for `OfferingsResponse` (#2499) via NachoSoto (@NachoSoto)
* Tests: grouped all `Matcher`s into one file (#2497) via NachoSoto (@NachoSoto)
* `DeviceCache`: refactored cache keys (#2494) via NachoSoto (@NachoSoto)
* `HTTPClient`: log actual response status code (#2487) via NachoSoto (@NachoSoto)
* Generate snapshots on CI (#2472) via Josh Holtz (@joshdholtz)
* `Integration Tests`: add `MainThreadMonitor` to ensure main thread is not blocked (#2463) via NachoSoto (@NachoSoto)
* Add message indicating tag doesn't exist (#2458) via Cesar de la Vega (@vegaro)
