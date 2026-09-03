## RevenueCat SDK
### 🐞 Bugfixes
* Surface attribute sync errors when fetching offerings (#7539) via Rick (@rickvdl)
* Fall back to "en" when a workflow screen omits `default_locale` (#7523) via Monika Mateska (@MonikaMateska)
* Cache web purchase redemption CustomerInfo for the initiating App User ID (#7533) via Rick (@rickvdl)

## RevenueCatUI SDK
### 🐞 Bugfixes
* feat: Give the paywall sticky footer a bottom margin in mac and vision devices (#7560) via Facundo Menzella (@facumenzella)
* [EXTERNAL] Give the paywall sticky footer a bottom margin where there is no safe area (#7548) via @t9mike (#7559) via Facundo Menzella (@facumenzella)
* Fix(Paywalls MacOS) resolve an attribute graph cycle hang/crash (#7480) via Jacob Rakidzich (@JZDesign)
### Paywallsv2
#### ✨ New Features
* Feat(Paywalls): Web Views can observe paywall data (#7542) via Jacob Rakidzich (@JZDesign)
#### 🐞 Bugfixes
* fix: resolve the paywall video when the appearance changes (#7569) via Facundo Menzella (@facumenzella)
### Customer Center
#### 🐞 Bugfixes
* fix(customer center): show the most recent one-time purchases (#7534) via Facundo Menzella (@facumenzella)

### 🔄 Other Changes
* Share one arity check across the strict operators (#7571) via Antonio Pallares (@ajpallares)
* Add rc.regexReplace custom operator (#7558) via Antonio Pallares (@ajpallares)
* Add rc.regexExtract custom operator (#7557) via Antonio Pallares (@ajpallares)
* Add rc.regexMatch custom operator (#7556) via Antonio Pallares (@ajpallares)
* Remove the rc.length and rc.indexOf custom operators (#7568) via Antonio Pallares (@ajpallares)
* feat(Checkpoints): refine result and listener APIs (#7526) via Rick (@rickvdl)
* Index substr by UTF-16 code unit (#7552) via Antonio Pallares (@ajpallares)
* Chore(deps): Bump fastlane from 2.237.0 to 2.238.0 (#7565) via dependabot[bot] (@dependabot[bot])
* Add rc.indexOf custom operator (#7555) via Antonio Pallares (@ajpallares)
* Gate the iOS 17 scroll anchor snapshot test behind Xcode 15 (#7564) via Facundo Menzella (@facumenzella)
* Compare strings by UTF-16 code unit in the rules engine (#7518) via Antonio Pallares (@ajpallares)
* Match the separator by code unit in rc.split (#7551) via Antonio Pallares (@ajpallares)
* Add rc.let custom operator (#7506) via Antonio Pallares (@ajpallares)
* Chore(Paywalls): Create Web View Context - #7530 (#7541) via Jacob Rakidzich (@JZDesign)
* Add rc.slice custom operator (#7505) via Antonio Pallares (@ajpallares)
* Add rc.sortBy custom operator (#7504) via Antonio Pallares (@ajpallares)
* Expose access token via AuthenticationDelegate (#7536) via Dave DeLong (@davedelong)
* Unify internal authentication delegate (#7547) via Dave DeLong (@davedelong)
* Expose OIDC and Firebase identities (#7537) via Dave DeLong (@davedelong)
* Chore(deps): Bump fastlane-plugin-revenuecat_internal from `7dd9ab9` to `6db1da0` (#7540) via dependabot[bot] (@dependabot[bot])
* (Internal) Spend virtual currencies (#7507) via Dave DeLong (@davedelong)
* chore: don't run danger on main (#7503) via Cesar de la Vega (@vegaro)
* refactor(Checkpoints): remove Objective-C compatibility (#7515) via Rick (@rickvdl)
* refactor(Checkpoints): remove CheckpointParams from the public API (#7512) via Rick (@rickvdl)
