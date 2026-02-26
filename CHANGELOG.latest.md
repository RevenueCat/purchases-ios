## RevenueCat SDK
### ✨ New Features
* [EXTERNAL] Support SubscriptionStoreContentView (#6309) via @junpluse (#6320) via Rick (@rickvdl)
### 🐞 Bugfixes
* Fix extractPurchaseDates crash (#6337) via Will Taylor (@fire-at-will)
* Add compiler check for SubscriptionStoreContentView API (#6326) via Rick (@rickvdl)
* Fix millisecond precision loss in stored ad and feature events (#6304) via Pol Miro (@polmiro)

## RevenueCatUI SDK
### 🐞 Bugfixes
* FIX:  Video Low Res only on first paywall (#6307) via Jacob Rakidzich (@JZDesign)
* Fix purchase error alert not displaying when using custom purchase logic (#6330) via Rick (@rickvdl)
### Paywallv2
#### 🐞 Bugfixes
* Share PaywallPromoOfferCache between main and exit offer paywalls (#6180) via Facundo Menzella (@facumenzella)
* Fix custom variables not propagating to exit offers (#6302) via Facundo Menzella (@facumenzella)

### 🔄 Other Changes
* FIX: Update ColorComputationHelpers.swift to account for WatchOS (#6355) via Jacob Rakidzich (@JZDesign)
* Add color computation helpers for fallback paywall (#6339) via Jacob Rakidzich (@JZDesign)
* Fix snapshot generation (#6343) via Antonio Pallares (@ajpallares)
* Fix PaywallsTester macOS build (#6338) via Facundo Menzella (@facumenzella)
* Update Tuist Package.resolved after swift-snapshot-testing bump (#6336) via Antonio Pallares (@ajpallares)
* Update Tuist swift-snapshot-testing dependency to match Package.swift (#6335) via Antonio Pallares (@ajpallares)
* CI: Add daily CocoaPods trunk token keepalive (#6331) via Toni Rico (@tonidero)
* Bump fastlane-plugin-revenuecat_internal from `afc9219` to `ea6276c` (#6329) via dependabot[bot] (@dependabot[bot])
* Fix flaky PurchasesAdEventsTests (#6327) via Cesar de la Vega (@vegaro)
* CI: Use Xcode 14.3.1 for iOS 15 tests (#6297) via Antonio Pallares (@ajpallares)
* Repurpose `@RCGitBot please test` to approve CircleCI hold job (#6274) via Antonio Pallares (@ajpallares)
* Restructure CI: split PR and release workflows with gated full test suite (#6241) via Antonio Pallares (@ajpallares)
* Disable record on regular snapshot tests to prevent from passing after retry (#6303) via Cesar de la Vega (@vegaro)
* Bump swiftinterface Xcode version to 26.3 (#6321) via Rick (@rickvdl)
* Add .claude/ to .gitignore (#6324) via Facundo Menzella (@facumenzella)
* Add CI action for recording new baseline swiftinterface (#6312) via Rick (@rickvdl)
* Generating new test snapshots for `main` - revenuecatui-watchos (#6318) via RevenueCat Git Bot (@RCGitBot)
* Generating new test snapshots for `main` - revenuecatui-watchos (#6317) via RevenueCat Git Bot (@RCGitBot)
* Generating new test snapshots for `main` - ios-26 (#6306) via RevenueCat Git Bot (@RCGitBot)
* `create_snapshot_pr` when recording RevenueCatUI snapshots (#6314) via Cesar de la Vega (@vegaro)
* Remove XC-alltests test plan (#6313) via Cesar de la Vega (@vegaro)
* Bump nokogiri from 1.18.9 to 1.19.1 in /Tests/InstallationTests/CocoapodsInstallation (#6308) via dependabot[bot] (@dependabot[bot])
* Fix flaky UserDefaults tests (#6301) via Cesar de la Vega (@vegaro)
* Add tests for badge override fallback and missing localization (#6273) via Facundo Menzella (@facumenzella)
* Add code review guidelines to CLAUDE.md (#6300) via Facundo Menzella (@facumenzella)
