- Added .xcframework output to Releases, alongside the usual fat frameworks.
    https://github.com/RevenueCat/purchases-ios/pull/466
- Added PurchaseTester project, useful to test features while working on `purchases-ios`.
    https://github.com/RevenueCat/purchases-ios/pull/464
- Renamed the old `SwiftExample` project to `LegacySwiftExample` to encourage developers to use the new MagicWeather apps
    https://github.com/RevenueCat/purchases-ios/pull/461
- Updated the cache duration in background from 24 hours to 25 to prevent cache misses when the app is woken every 24 hours exactly by remote push notifications.
    https://github.com/RevenueCat/purchases-ios/pull/463
