## RevenueCat SDK
### 🐞 Bugfixes
* Fix `hasFeature(RetroactiveAttribute)` check in iOS 14 (#4359) via Cesar de la Vega (@vegaro)
* Only Treat Deferred StoreKit Messages as Shown When They are Shown (#4344) via Will Taylor (@fire-at-will)
### 📦 Dependency Updates
* Bump fastlane from 2.223.1 to 2.224.0 (#4354) via dependabot[bot] (@dependabot[bot])
* Bump fastlane-plugin-revenuecat_internal from `5b2e35c` to `3b1e7cf` (#4347) via dependabot[bot] (@dependabot[bot])
### Win-back Offers
#### ✨ New Features
* CAT-1726: Support Deferring Win-Back StoreKit Messages (#4343) via Will Taylor (@fire-at-will)

## RevenueCatUI SDK
### 🐞 Bugfixes
* Fixes double callbacks when using `PaywallViewController` (#4333) via Cesar de la Vega (@vegaro)
### Customer Center
#### 🐞 Bugfixes
* Fix setting accent color in Customer Center (#4358) via Cesar de la Vega (@vegaro)
* Improve promotional offer button when pressed (#4342) via Cesar de la Vega (@vegaro)
* [CustomerCenter] Hide unknown paths (#4350) via Toni Rico (@tonidero)
* Remove access to Localization env variable in ManageSubscriptionsViewModel (#4339) via Cesar de la Vega (@vegaro)

### 🔄 Other Changes
* Update MagicWeather sample app (#4337) via nyeu (@nyeu)
* Allows enabling PAYWALL_COMPONENTS using a Local.xcconfig file. (#4341) via JayShortway (@JayShortway)
* Better logs for promotional offer view (#4336) via Cesar de la Vega (@vegaro)
* Fix Xcode 16 warnings (#4334) via Mark Villacampa (@MarkVillacampa)
* Run CI tests on iOS18/watchOS11 & Use Xcode 16 (#4295) via Will Taylor (@fire-at-will)
