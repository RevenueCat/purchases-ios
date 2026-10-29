# Where to test behavior

- **Unit tests**: Logic, state changes, and serialization. Use `Tests/UnitTests/` for the core SDK, `Tests/StoreKitUnitTests/` for StoreKit, and `Tests/RevenueCatUITests/` for RevenueCatUI logic.
- **PaywallFixtures**: Paywall UI behavior with fixed data and no backend dependency. Examples include carousel pages across tabs, package selection, gestures, and accessibility. Add fixtures in `Tests/TestingApps/PaywallFixtures/` and XCUITests in `Tests/TestingApps/PaywallFixturesUITests/`.
- **Maestro**: Complete app flows, such as purchases, entitlement updates, and workflow navigation. Use the app and YAML flows in `Examples/rc-maestro/`.
- **Snapshot tests**: Visual appearance, such as layout, colors, and text styles. Use the snapshot tests in `Tests/RevenueCatUITests/`.
- **Manual checks**: Behavior that the automated tests cannot verify, such as actual VoiceOver speech and focus order.
