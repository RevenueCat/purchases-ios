## RevenueCat SDK
### ✨ New Features
* [CIA-5346] Appstack integration to ios sdk (#6366) via Damian Rubio (@DamianRubio)
### 🐞 Bugfixes
* [CEC] Do not fallback to offline entitlements if post receipt returns error (#6393) via Mark Villacampa (@MarkVillacampa)

## RevenueCatUI SDK
### 🐞 Bugfixes
* Fix presented offering context lost in Customer Center purchases (#6375) via Antonio Pallares (@ajpallares)
### Paywallv2
#### 🐞 Bugfixes
* Fix carousel blocking vertical scroll in parent ScrollView (#6284) via Facundo Menzella (@facumenzella)
* Fix exit offer crash in MY_APP mode by propagating purchase handlers (#6391) via Toni Rico (@tonidero)

### 🔄 Other Changes
* Update to use CI commands from CircleCI orb (#6413) via Toni Rico (@tonidero)
* Bump fastlane-plugin-revenuecat_internal from `8cd957f` to `f5c099b` (#6411) via dependabot[bot] (@dependabot[bot])
* Add internal trackCustomPaywallImpression method (#6388) via Rick (@rickvdl)
* Improve Danger xcodeproj sync warning message (#6405) via Facundo Menzella (@facumenzella)
* Add default/fallback paywall UI components and assets (#6342) via Jacob Rakidzich (@JZDesign)
* Update sdks-common-config orb to 3.13.0 (#6402) via Cesar de la Vega (@vegaro)
* Fix stale PresentedOfferingContext on purchase failure or cancellation (#6387) via Antonio Pallares (@ajpallares)
* Fix CI clone failures after GitHub App migration (#6399) via Antonio Pallares (@ajpallares)
* Add Customer Center to RCT Tester app (#6386) via Antonio Pallares (@ajpallares)
* Guard switchUser against preview mode (#6371) via Monika Mateska (@MonikaMateska)
* Enable auto-merge on release PR after deploy (#6363) via Antonio Pallares (@ajpallares)
* Log warning if SK2 purchase doesnt error but returns transaction with expiration date in the past (#6374) via Will Taylor (@fire-at-will)
* Fix scheduled pipelines triggering unintended workflows (#6369) via Antonio Pallares (@ajpallares)
* Require PR approval for release tagging (#6243) via Antonio Pallares (@ajpallares)
* Update CircleCI orb sdks-common-config to 3.12.0 (#6368) via Rick (@rickvdl)
* Add PaywallWarning model and validation documentation (#6341) via Jacob Rakidzich (@JZDesign)
* Bump fastlane-plugin-revenuecat_internal from `ea6276c` to `8cd957f` (#6364) via dependabot[bot] (@dependabot[bot])
* Add app style extractor for icon color extraction (#6340) via Jacob Rakidzich (@JZDesign)
* CI: Unify CI jobs to reduce machine count (#6332) via Antonio Pallares (@ajpallares)
