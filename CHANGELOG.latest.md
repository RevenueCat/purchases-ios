## RevenueCat SDK
### 🐞 Bugfixes
* Share one product cache between offerings and intro eligibility (#8085) via Antonio Pallares (@ajpallares)
* Fix product cache invalidation and shared request results (#8084) via Antonio Pallares (@ajpallares)
* Handle re-login as the same user (#8100) via Dave DeLong (@davedelong)

## RevenueCatUI SDK
### Paywallsv2
#### ✨ New Features
* 6 of 6: Support native Back and Close in paywall workflows (#8025) via Josh Holtz (@joshdholtz)
* 5 of 6: Show native paywall buttons in UIKit (#8024) via Josh Holtz (@joshdholtz)
* 4 of 6: Show native paywall buttons in SwiftUI (#8023) via Josh Holtz (@joshdholtz)
* 3 of 6: Connect native paywall buttons to existing actions (#8022) via Josh Holtz (@joshdholtz)
* 2 of 6: Register native paywall button actions (#8027) via Josh Holtz (@joshdholtz)
* 1 of 6: Add native paywall button preferences (#8021) via Josh Holtz (@joshdholtz)
#### 🐞 Bugfixes
* 8 of 8: Replace nested paywall navigation buttons (#8075) via Josh Holtz (@joshdholtz)
* 7 of 7: Hide caller Back when native paywall controls are shown (#8071) via Josh Holtz (@joshdholtz)
* fix: avoid redacting packages without applicable offers (#8074) via Antonio Pallares (@ajpallares)

### 🔄 Other Changes
* Improve intro eligibility debug logging (#8104) via Antonio Pallares (@ajpallares)
* 10 of 10: Verify native and embedded navigation analytics (#8082) via Josh Holtz (@joshdholtz)
* 9 of 9: Share paywall component traversal (#8080) via Josh Holtz (@joshdholtz)
* Remove snapshots for iOS versions no longer tested on CI (#8092) via Antonio Pallares (@ajpallares)
* Run iOS 26 tests on Xcode 26.6 with the iOS 26.2 simulator (#8090) via Antonio Pallares (@ajpallares)
* Update fallback offerings snapshot for Filipino locale (#8102) via Josh Holtz (@joshdholtz)
* Revert "Migrate existing anonymous user IDs when logging in" (#8101) via Dave DeLong (@davedelong)
