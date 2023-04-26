### New Features
* Custom Entitlements Computation mode (#2439) via Andy Boedo (@aboedo)
* Create separate `SPM` library to enable custom entitlement computation (#2440) via NachoSoto (@NachoSoto)

### Bugfixes
* `PurchaseOrchestrator`: fix incorrect `InitiationSource` for SK1 queue transactions (#2430) via NachoSoto (@NachoSoto)

### Other Changes
* Custom Entitlement Computation: disabled authentication and attribution API via NachoSoto (@NachoSoto)
* `StoreKit1Wrapper`: added log when adding payment to queue (#2423) via NachoSoto (@NachoSoto)
* `StoreKit1Wrapper`: added debug log when transaction is removed but no callbacks to notify (#2418) via NachoSoto (@NachoSoto)
* `customEntitlementsComputation`: update the copy in the sample app to explain the new usage (#2443) via Andy Boedo (@aboedo)
* Clarify reasoning for `disfavoredOverload` in logIn (#2434) via Andy Boedo (@aboedo)
