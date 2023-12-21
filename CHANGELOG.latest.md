### StoreKit 2 Beta

This beta introduces a new configuration option to enable full StoreKit 2 flow on the SDK and the RevenueCat backend.

We have been testing StoreKit 2 support in parallel to StoreKit 1 in our backend for a while and we believe it is ready for widespread use.

If your app is currently using StoreKit 1, it is safe to update to StoreKit 2 and it's even possible to switch back to StoreKit 1 if needed. Switching to StoreKit 2 will not prevent purchases made with StoreKit 1 from being processed.

In order to enable StoreKit 2, add `.with(storeKitVersion: .storeKit2)` to your RevenueCat configuration code:

```
Purchases.configure(with: .builder(withAPIKey: apiKey)
    .with(storeKitVersion: .storeKit2)
    .build()
```

If you were previously using the deprecated configuration option `.with(usesStoreKit2IfAvailable: true)`, it is now a deprecated alias to the new method, so we strongly recommend you remove it and switch to the new one.

⚠️ ⚠️ Important ⚠️ ⚠️

In order to validate StoreKit 2 purchases, make sure you have an In-App Purchase Key configured in your app.

Please see https://rev.cat/in-app-purchase-key-configuration for more info.

🚧🚧 Limitations 🚧🚧

- Observer Mode is not currently supported when using StoreKit 2.
- The `originalApplicationVersion` and `originalPurchaseDate` properties in `CustomerInfo` are not supported in this first beta. Please do not update if your implementation relies on them being present.

### RevenueCatUI
* `Paywalls`: add `PaywallFooterViewController` (#3486) via Toni Rico
(@tonidero)
* `Paywalls`: improve landscape support of all templates (#3471) via
NachoSoto (@NachoSoto)
* `Paywalls`: ensure footer links open in full-screen sheets (#3524) via
NachoSoto (@NachoSoto)
* `Paywalls`: improve `FooterView` text alignment (#3525) via NachoSoto
(@NachoSoto)
* Paywalls: Add dismissal method in `PaywallViewControllerDelegate`
(#3493) via Toni Rico (@tonidero) via RevenueCat Git Bot (@RCGitBot)