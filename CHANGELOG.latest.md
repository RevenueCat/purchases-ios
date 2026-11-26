## RevenueCat SDK
### ✨ New Features
* feat: Add Roku and PayPal store via Facundo Menzella (@facumenzella)
* feat: add device identifier collection mode option via Álvaro Brey (@AlvaroBrey)
* feat(entitlements): notify users about expired promotional entitlements through existing PurchasesDelegate via Peter Porfy (@peterporfy)
* feat: include app session ID in paywall and workflow events via Takeichi Kanzaki Cabrera (@tkanzakic)
### 📦 Dependency Updates
* [RENOVATE] Update dependency revenuecat to v4.14.0 via RevenueCat Git Bot (@RCGitBot)
* [RENOVATE] Update dependency revenuecat to v4.13.1 via RevenueCat Git Bot (@RCGitBot)
* [RENOVATE] Update ruby-dependencies via RevenueCat Git Bot (@RCGitBot)
* [RENOVATE] Update dependency revenuecat to v4.12.2 via RevenueCat Git Bot (@RCGitBot)
* [RENOVATE] Update dependency revenuecat to v4.10.0 via RevenueCat Git Bot (@RCGitBot)

## RevenueCatUI SDK
### 🐞 Bugfixes
* fix: keep paywall purchase confirmation in the originating window via Rick (@rickvdl)
* fix(checkpoints): Treat checkpoint identifiers as case-insensitive via Toni Rico (@tonidero)
### Paywallsv2
#### 🐞 Bugfixes
* fix(paywalls): keep the sheet selection when switching to a tab without packages via Cesar de la Vega (@vegaro)
* fix(paywalls): use the selected tab’s sheet price via Cesar de la Vega (@vegaro)
* fix(paywalls): format Paywalls V2 prices with the paywall locale via Cesar de la Vega (@vegaro)
* fix(paywalls): honor numbering system from preferredUILocaleOverride via Cesar de la Vega (@vegaro)
* fix(paywalls): format percent variables with the price locale via Cesar de la Vega (@vegaro)
* fix(paywalls): preserve visibility for text-only overrides via Cesar de la Vega (@vegaro)
* fix(paywalls): prefer WebP for iOS image placeholders via Cesar de la Vega (@vegaro)
* Fix paywall body overlap below a header image via Facundo Menzella (@facumenzella)
* fix(paywalls): pause video when a retained paywall leaves the window via Facundo Menzella (@facumenzella)
### Customer Center
#### 🐞 Bugfixes
* fix(customer-center): preserve purchase presentation context via Rick (@rickvdl)

### 🔄 Other Changes
* fix: stabilize native navigation inline sheet UI test via Rick (@rickvdl)
* [AUTOMATIC] test: sync audience fixtures from Khepri main via revenuecat-ci-cd-bot-pr-writer[bot] (@revenuecat-ci-cd-bot-pr-writer[bot])
* Allow passing a version to the CircleCI bump action via Toni Rico (@tonidero)
* feat(checkpoints): Add scene-aware presentation API via Rick (@rickvdl)
* fix(tests): separate StoreKit tests by test plan via Rick (@rickvdl)
* fix(tests): configure device identifier collection in backend tests via Rick (@rickvdl)
* refactor: pass the device identifier collection mode down instead of two Bools via Álvaro Brey (@AlvaroBrey)
* test(checkpoints): Skip workflow reappearance tests before iOS 26 via Antonio Pallares (@ajpallares)
* Chore(deps): Bump addressable from 2.9.0 to 2.9.1 in /Tests/InstallationTests/CocoapodsInstallation via dependabot[bot] (@dependabot[bot])
* ci: move Ruby gem updates to Renovate via Álvaro Brey (@AlvaroBrey)
* chore(deps): bump fastlane-plugin-revenuecat_internal to v0.3.1 via Antonio Pallares (@ajpallares)
* chore: bump Ruby to 3.3.14 for the Regexp/String security advisory via Tony Cosentini (@tonycosentini)
* feat(checkpoints): enforce hard paywalls in checkpoint workflows via Cesar de la Vega (@vegaro)
* test: use the audience fixture clock for subscription expiry via Facundo Menzella (@facumenzella)
* [AUTOMATIC] test: sync audience fixtures from Khepri main via revenuecat-ci-cd-bot-pr-writer[bot] (@revenuecat-ci-cd-bot-pr-writer[bot])
* ci: add the hotfix PR comment command via Álvaro Brey (@AlvaroBrey)
* Chore(deps): Bump fastlane-plugin-revenuecat_internal from `a862068` to `3776846` via dependabot[bot] (@dependabot[bot])
* ci: export main and release tags to the public repo with the orb's Copybara job via Antonio Pallares (@ajpallares)
* [AUTOMATIC] test: sync audience fixtures from Khepri main via revenuecat-ci-cd-bot-pr-writer[bot] (@revenuecat-ci-cd-bot-pr-writer[bot])
* refactor(paywalls): isolate image loader state on the main actor via Cesar de la Vega (@vegaro)
* Add Tuist projects for RevenueCatAds and its tests via Antonio Pallares (@ajpallares)
* test: verify audiences from Khepri #27578 via revenuecat-ci-cd-bot-pr-writer[bot] (@revenuecat-ci-cd-bot-pr-writer[bot])
* other: add an ad checkpoint sample to SampleCat via Peter Porfy (@peterporfy)
* feat(ads): add RevenueCatAds interstitial via Peter Porfy (@peterporfy)
