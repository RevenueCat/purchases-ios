### Other Changes
* `ProductsFetcherSK2`: removed now redundant caching logic (#1908) via NachoSoto (@NachoSoto)
* Created `CachingProductsManager` to provide consistent caching logic when fetching products (#1907) via NachoSoto (@NachoSoto)
* Refactored `ReceiptFetcher.receiptData` (#1941) via NachoSoto (@NachoSoto)
* Abstracted conversion from `async` to completion-block APIs (#1943) via NachoSoto (@NachoSoto)
* Moved `InAppPurchase` into `AppleReceipt` (#1942) via NachoSoto (@NachoSoto)
* `Purchases+async`: combined `@available` statements into a single one (#1944) via NachoSoto (@NachoSoto)
* `Integration Tests`: don't initialize `Purchases` until the `SKTestSession` has been re-created (#1946) via NachoSoto (@NachoSoto)
* `PostReceiptDataOperation`: print receipt data if `debug` logs are enabled (#1940) via NachoSoto (@NachoSoto)
