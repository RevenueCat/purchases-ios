### Bugfixes
* Fix sending presentedOfferingIdentifier in StoreKit2 (#2156) via Toni Rico (@tonidero)
* `ReceiptFetcher`: throttle receipt refreshing to avoid `StoreKit` throttle errors (#2146) via NachoSoto (@NachoSoto)
### Other Changes
* Added integration and unit tests to verify observer mode behavior (#2069) via NachoSoto (@NachoSoto)
* Created `ClockType` and `TestClock` to be able to mock time (#2145) via NachoSoto (@NachoSoto)
* Extracted `asyncWait` to poll `async` conditions in tests (#2134) via NachoSoto (@NachoSoto)
* `StoreKitRequestFetcher`: added log when starting/ending requests (#2151) via NachoSoto (@NachoSoto)
* `CI`: fixed `PurchaseTester` deployment (#2147) via NachoSoto (@NachoSoto)
