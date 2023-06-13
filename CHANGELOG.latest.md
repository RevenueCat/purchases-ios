### New Features
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
