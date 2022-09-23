### Bugfixes
* `StoreKit 1`: changed result of cancelled purchases to be consistent with `StoreKit 2` (#1910) via NachoSoto (@NachoSoto)
* `PaymentQueueWrapper`: handle promotional purchase requests from App Store when SK1 is disabled (#1901) via NachoSoto (@NachoSoto)
### New Features
* `StoreKit 2`: enabled by default (#1922) via NachoSoto (@NachoSoto)
* Extracted `PurchasesType` and `PurchasesSwiftType` (#1912) via NachoSoto (@NachoSoto)
### Other Changes
* Fixed iOS 12 tests (#1936) via NachoSoto (@NachoSoto)
* `CacheableNetworkOperation`: fixed race condition in new test (#1932) via NachoSoto (@NachoSoto)
* `BasePurchasesTests`: changed default back to SK1 (#1935) via NachoSoto (@NachoSoto)
* `Logger`: refactored default `LogLevel` definition (#1934) via NachoSoto (@NachoSoto)
* `AppleReceipt`: refactored declarations into nested types (#1933) via NachoSoto (@NachoSoto)
* `Integration Tests`: relaunch tests when retrying failures (#1925) via NachoSoto (@NachoSoto)
* `CircleCI`: downgraded release jobs to Xcode 13.x (#1927) via NachoSoto (@NachoSoto)
* `ErrorUtils`: added test to verify that `PublicError`s can be `catch`'d as `ErrorCode` (#1924) via NachoSoto (@NachoSoto)
* `StoreKitIntegrationTests`: print `AppleReceipt` data whenever `verifyEntitlementWentThrough` fails (#1929) via NachoSoto (@NachoSoto)
* `OperationQueue`: log debug message when requests are found in cache and skipped (#1926) via NachoSoto (@NachoSoto)
* `GetCustomerInfoAPI`: avoid making a request if there's any `PostReceiptDataOperation` in progress (#1911) via NachoSoto (@NachoSoto)
* `PurchaseTester`: allow HTTP requests and enable setting `ProxyURL` (#1917) via NachoSoto (@NachoSoto)