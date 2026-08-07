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
TUIST_SWIFT_CONDITIONS=ENABLE_CHECKPOINTS \
tuist generate CheckpointTester --no-open
```

The app configures RevenueCat before showing its root screen, so generation requires a valid public
iOS API key. `ENABLE_CHECKPOINTS` compiles the experimental checkpoint surface as regular public API, so the app
uses the same imports and call sites as an SDK consumer.
