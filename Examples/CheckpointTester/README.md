# CheckpointTester

`CheckpointTester` is a Tuist-generated example for the experimental checkpoint APIs.

This base app demonstrates the application-facing integration:

- configuring `Purchases` and installing a global `CheckpointListener`;
- calling a checkpoint with custom properties;
- handling checkpoint result subclasses and paywall outcomes;
- displaying call results and a live analytics event log.

The generated app shares PaywallsTester's bundle identifier and `Products.storekit` configuration so it can use
the same local in-app purchase products and RevenueCat project.

Generate the project from the repository root:

```sh
TUIST_RC_API_KEY=appl_your_key \
tuist generate CheckpointTester --no-open
```

The app configures RevenueCat before showing its root screen, so generation requires a valid public
iOS API key. The app explicitly imports RevenueCatUI's experimental `Checkpoints` SPI; regular SDK consumers do
not see this API surface.
