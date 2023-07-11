### New Features
* `Trusted Entitlements`: re-enable public API (#2621) via NachoSoto (@NachoSoto)

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
* `Trusted Entitlements`: added link to docs in `ErrorCode.signatureVerificationFailed` (#2783) via NachoSoto (@NachoSoto)
* `Trusted Entitlements`: improved documentation (#2782) via NachoSoto (@NachoSoto)
* `Tests`: fixed flaky failure with asynchronous check (#2777) via NachoSoto (@NachoSoto)
* `Integration Tests`: re-enable signature verification tests (#2744) via NachoSoto (@NachoSoto)
* `CI`: remove `Jazzy` (#2775) via NachoSoto (@NachoSoto)
* `Signing`: inject `ClockType` to ensure hardcoded signatures don't fail when intermediate key expires (#2771) via NachoSoto (@NachoSoto)
