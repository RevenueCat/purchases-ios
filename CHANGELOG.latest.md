### New Features
* Introduced `Configuration.EntitlementVerificationMode` and `VerificationResult` (#2277) via NachoSoto (@NachoSoto)
* `PurchasesDiagnostics`: added step to verify signature verification (#2267) via NachoSoto (@NachoSoto)
* `HTTPClient`: added signature verification and introduced `ErrorCode.signatureVerificationFailed` (#2272) via NachoSoto (@NachoSoto)

#### Introducing Trusted Entitlements (beta):

Fixes #1900.

This new feature prevents MitM attacks between the SDK and the RevenueCat server.
With verification enabled, the SDK ensures that the response created by the server was not modified by a third-party, and the entitlements received are exactly what was sent.
This is 100% opt-in. `EntitlementInfos` have a new `VerificationResult` property, which will indicate the validity of the responses when this feature is enabled.

```swift
let purchases = Purchases.configure(
  with: Configuration
    .builder(withAPIKey: "")
    .with(entitlementVerificationMode: .informational)
)
let customerInfo = try await purchases.customerInfo()
if customerInfo.entitlements.verification != .verified {
  print("Entitlements could not be verified")
}
```

### Other Changes
* Refactor: reorganized files in new Security and Misc folders (#2326) via NachoSoto (@NachoSoto)
* `CustomerInfo`: use same grace period logic for active subscriptions (#2327) via NachoSoto (@NachoSoto)
* `EntitlementInfo`: request date is not optional (#2325) via NachoSoto (@NachoSoto)
* `EntitlementInfo`: add a grace period limit to outdated entitlements (#2288) via NachoSoto (@NachoSoto)
* Update `CustomerInfo.requestDate` from 304 responses (#2310) via NachoSoto (@NachoSoto)
* `HTTPClient`: changed header search to be case-insensitive (#2308) via NachoSoto (@NachoSoto)
* `PurchaseTester`: added ability to reload `CustomerInfo` with a custom `CacheFetchPolicy` (#2312) via NachoSoto (@NachoSoto)
* SwiftUI: Paywall View should respond to changes on the UserView model (#2297) via ConfusedVorlon (@ConfusedVorlon)
* Deprecate `usesStoreKit2IfAvailable` (#2293) via Andy Boedo (@aboedo)
* Clarifies error messages for storekit 1 bugs (#2294) via Andy Boedo (@aboedo)