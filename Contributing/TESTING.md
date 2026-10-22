# Behavior tests

Choose the smallest test that reproduces the failure through a real production path.
Use these test types:

- **Unit tests** (`Tests/UnitTests/`, `Tests/StoreKitUnitTests/`, `Tests/RevenueCatUITests/`): Check logic, state transitions, serialization, and dependency interactions. Use a hosted SwiftUI test when view lifecycle matters and the host can expose the actual result.
- **PaywallFixtures**: Use for local UI behavior with controlled paywall data, such as carousel page restoration, package selection, layout, and accessibility. Define the fixture in `Tests/TestingApps/PaywallFixtures/` and the XCUITest in `Tests/TestingApps/PaywallFixturesUITests/`. The app renders real `PaywallView` components with no backend dependency. Its purchase and restore closures do not perform transactions.
- **Maestro** (`Examples/rc-maestro/`): Use when the failure depends on SDK configuration, fetched offerings, purchases, entitlements, or workflow presentation and navigation. Extend the app flow under `rc-maestro/Sources/rc-maestro/e2e-test-flows/` and the YAML flow under `maestro/`. Check the selected flow's API key, backend, and store requirements before execution.
- **Snapshots**: Use for visual appearance and layout in a known state. For behavior across interactions, assert the result with a behavior test.
- **Manual checks**: Use when automation cannot verify the result, such as actual VoiceOver speech. Document the limitation and the manual steps. An accessibility element query alone does not prove what VoiceOver announces.

Before you add a test:

1. Name the observable behavior and the production regression that the test must detect.
2. Check current coverage. Add another test layer only when it detects a distinct failure.
3. Exercise the real owner of the behavior. Keep fixture helpers in test code and avoid new production hooks for tests.
4. Assert results after the relevant action. For carousels, check the visible page rather than an offscreen label's existence.
5. Cover each event source that needs separate proof, such as manual swipes and automatic page advance.
6. For a bug fix, confirm failure without the fix and success with it for the intended reason.
