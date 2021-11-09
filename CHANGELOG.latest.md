- Added support for Airship integration via `setAirshipChannelID`
    https://github.com/RevenueCat/purchases-ios/pull/933
- Obfuscates calls to `AdClient`, `ASIdentifierManager` and `ATTrackingManager` to prevent unnecessary rejections for kids apps when the relevant frameworks aren't used at all. 
    https://github.com/RevenueCat/purchases-ios/pull/932
