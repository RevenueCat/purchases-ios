## RevenueCat SDK
### 🐞 Bugfixes
* Fix SDK Compilation on Xcode 16.3/iOS 18.4 Beta 1 (#4814) via Will Taylor (@fire-at-will)
* Add prepaid as a period type (#4782) via Greenie (@greenietea)

## RevenueCatUI SDK
### 🐞 Bugfixes
* Fix paywall refreshable bug (#4793) via Antonio Pallares (@ajpallares)
### Customer Center
#### 🐞 Bugfixes
* fix: [AppUpdateWarningView] Tweak buttons bottom alignment and padding (#4807) via Facundo Menzella (@facumenzella)
* fix: Remove force unwrapping from PurchaseHistoryView (#4794) via Facundo Menzella (@facumenzella)
* fix: Remove NavigationView/NavigationStack from AppWarningView (#4792) via Facundo Menzella (@facumenzella)
### Paywallv2
#### ✨ New Features
* [Paywalls V2] Carousel component (#4722) via Josh Holtz (@joshdholtz)
#### 🐞 Bugfixes
* [Paywalls V2] Fixes parsing generic fonts. (#4801) via JayShortway (@JayShortway)
* [Paywalls V2] Scroll fix for background/padding/border (#4788) via Josh Holtz (@joshdholtz)
* [Paywalls V2] Add purchase button activity indicator (#4787) via Josh Holtz (@joshdholtz)
* [Paywalls V2] Add `visible` property to all components (and overrides to ones that were missing) (#4781) via Josh Holtz (@joshdholtz)

### 🔄 Other Changes
* UI preview mode: disable cache updates (#4809) via Antonio Pallares (@ajpallares)
* UI Preview mode: avoid intro eligibility request (#4800) via Antonio Pallares (@ajpallares)
* [Diagnostics] Fix store kit error description tracking (#4799) via Toni Rico (@tonidero)
* Add no quotes hints to build settings in `Local.xcconfig.SAMPLE` (#4808) via Antonio Pallares (@ajpallares)
* [Paywalls] Fix onRestoreComplete callback not being called (#4803) via Mark Villacampa (@MarkVillacampa)
* UI preview mode: disable log in and log out (#4804) via Antonio Pallares (@ajpallares)
* Config item rename (#4798) via Antonio Pallares (@ajpallares)
* Use RC API key for local development from local.xcconfig (#4795) via Antonio Pallares (@ajpallares)
* UI Preview Mode: mock `CustomerInfo` (#4786) via Antonio Pallares (@ajpallares)
* [Paywalls V2] Added `overflow` property to stack  (#4767) via Josh Holtz (@joshdholtz)
* Add Internal support for draft paywall previews (#4761) via Antonio Pallares (@ajpallares)
