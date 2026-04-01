## RevenueCat SDK
### 🐞 Bugfixes
* [EXTERNAL] Fix #5549: Use entitlement identifier as title for promotional entitlements (#6530) via @cruisediary (#6539) via Cesar de la Vega (@vegaro)
* Fix: icon sizing bug - Margins calculated as padding (#6538) via Jacob Rakidzich (@JZDesign)
* Fix flaky iOS 26 UI snapshot and event tests (#6511) via Rick (@rickvdl)
* Fix xcframework installation tests to actually validate xcframeworks (#6527) via Rick (@rickvdl)
* Fix XCFramework compilation error caused by SubscriptionPeriod Codable conformance (#6526) via Rick (@rickvdl)

## RevenueCatUI SDK
### Customer Center
#### 🐞 Bugfixes
* Fix: purchaseIdentifier nil on custom action paths (including post-promo-offer dismissal) (#6488) via Facundo Menzella (@facumenzella)

### 🔄 Other Changes
* Bump fastlane-plugin-revenuecat_internal from `f11fe40` to `b5a7159` (#6540) via dependabot[bot] (@dependabot[bot])
* Skip external dependencies in tuist install on CI (#6536) via Rick (@rickvdl)
* Rollback changes in #5660 -> Didn't work, other fix in place (#6534) via Jacob Rakidzich (@JZDesign)
* Rename simulated store purchase alert to "Test Store Purchase" (#6532) via Antonio Pallares (@ajpallares)
* Bump fastlane-plugin-revenuecat_internal from `9a6911b` to `f11fe40` (#6524) via dependabot[bot] (@dependabot[bot])
