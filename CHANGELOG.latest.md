### Bugfixes
* `PurchasesOrchestrator`: fixed callback not invoked regression during downgrades (#3028) via NachoSoto (@NachoSoto)
* `TransactionPoster`: don't finish transactions for non-subscriptions if they're not processed (#2841) via NachoSoto (@NachoSoto)
### Performance Improvements
* `StoreKit 2`: only listen to `StoreKit.Transaction.updates` when SK2 is enabled (#3032) via NachoSoto (@NachoSoto)
* `CustomerInfoManager`: post transactions in parallel to POST receipts only once (#2954) via NachoSoto (@NachoSoto)
### Other Changes
* `PostedTransactionCache`: remove implementation (#3030) via NachoSoto (@NachoSoto)
* `Integration Tests`: improved `testCanPurchaseMultipleSubscriptions` (#3025) via NachoSoto (@NachoSoto)
* `GitHub`: improved `ISSUE_TEMPLATE` (#3022) via NachoSoto (@NachoSoto)
* `TransactionPoster`: added transaction ID and Date to log (#3026) via NachoSoto (@NachoSoto)
* `TransactionPoster`: fix iOS 12 test (#3018) via NachoSoto (@NachoSoto)
* `SystemInfo`: added `ClockType` (#3014) via NachoSoto (@NachoSoto)
* `Integration Tests`: begin tests with `UIApplication.willEnterForegroundNotification` to simulate a real app (#3015) via NachoSoto (@NachoSoto)
* `Integration Tests`: add tests to verify `CustomerInfo`+`Offerings` request de-dupping (#3013) via NachoSoto (@NachoSoto)
* `SwiftLint`: disable `unneeded_synthesized_initializer` (#3010) via NachoSoto (@NachoSoto)
* Added `internal` `NonSubscriptionTransaction.storeTransactionIdentifier` (#3009) via NachoSoto (@NachoSoto)
* `Integration Tests`: added tests for non-renewing and non-consumable packages (#3008) via NachoSoto (@NachoSoto)
* Expanded `EnsureNonEmptyArrayDecodable` to `EnsureNonEmptyCollectionDecodable` (#3002) via NachoSoto (@NachoSoto)
