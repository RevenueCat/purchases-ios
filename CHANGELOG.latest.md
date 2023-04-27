### New Features
* Introduced Custom Entitlements Computation mode (#2439) via Andy Boedo (@aboedo)
* Create separate `SPM` library to enable custom entitlement computation (#2440) via NachoSoto (@NachoSoto)

This new library allows apps to use a smaller version of the RevenueCat SDK, intended for apps that will do their own entitlement computation separate from RevenueCat.

Apps using this mode rely on webhooks to signal their backends to refresh entitlements with RevenueCat.

See the [demo app for an example](https://github.com/RevenueCat/purchases-ios/tree/main/Examples/testCustomEntitlementsComputation).

### Bugfixes
* `PurchaseOrchestrator`: fix incorrect `InitiationSource` for SK1 queue transactions (#2430) via NachoSoto (@NachoSoto)

### Other Changes
* Update offerings cache when switchUser(to:) is called (#2455) via Andy Boedo (@aboedo)
* Updated example code for the sample app for Custom Entitlements (#2454) via Andy Boedo (@aboedo)
* Custom Entitlement Computation: API testers (#2452) via NachoSoto (@NachoSoto)
* Custom Entitlement Computation: avoid `getCustomerInfo` requests for cancelled purchases (#2449) via NachoSoto (@NachoSoto)
* Custom Entitlement Computation: disabled unnecessary APIs (#2442) via NachoSoto (@NachoSoto)
* `StoreKit1Wrapper`: added log when adding payment to queue (#2423) via NachoSoto (@NachoSoto)
* `StoreKit1Wrapper`: added debug log when transaction is removed but no callbacks to notify (#2418) via NachoSoto (@NachoSoto)
* `customEntitlementsComputation`: update the copy in the sample app to explain the new usage (#2443) via Andy Boedo (@aboedo)
* Clarify reasoning for `disfavoredOverload` in logIn (#2434) via Andy Boedo (@aboedo)
* Documentation: improved `async` API docs (#2432) via Kaunteya Suryawanshi (@kaunteya)
