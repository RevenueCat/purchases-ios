## RevenueCat SDK
### ✨ New Features
* Adds ObjC inits for Paywalls-only in UIKit (#6507) via JayShortway (@JayShortway)
### 🐞 Bugfixes
* Sync ATT consent status on attribute sync (#6485) via Rick (@rickvdl)
* Use caches directory for AdEventStore and FeatureEventStore on tvOS (#6490) via Antonio Pallares (@ajpallares)
* Fix "Failed to create cache directory" error log on tvOS (#6487) via Antonio Pallares (@ajpallares)

## RevenueCatUI SDK
### 🐞 Bugfixes
* Fix alert title showing raw error domain for non-ErrorCode errors (#6512) via Toni Rico (@tonidero)
### Customer Center
#### ✨ New Features
* Feat: Restore gating in paywalls UI (#6392) via Jacob Rakidzich (@JZDesign)
#### 🐞 Bugfixes
* Fix @Published mutations off main actor in PurchaseHistoryViewModel error path (#6516) via Facundo Menzella (@facumenzella)

### 🔄 Other Changes
* security: pin GitHub Actions to SHA hashes (#6514) via Alfonso Embid-Desmet (@alfondotnet)
* Add VanillaAdTrackingSample example app (#6504) via Pol Miro (@polmiro)
* Fix CI: use SSH for private repo clones in paywall screenshot job (#6517) via Antonio Pallares (@ajpallares)
* Fix iOS 14.5 simulator runtime install hanging in CI (#6513) via Rick (@rickvdl)
* Fix flaky tvOS CI test in event store tests (#6506) via Antonio Pallares (@ajpallares)
* Bump activesupport from 7.2.2.1 to 7.2.3.1 in /Tests/InstallationTests/CocoapodsInstallation (#6509) via dependabot[bot] (@dependabot[bot])
* Bump activesupport from 7.2.2.1 to 7.2.3.1 (#6508) via dependabot[bot] (@dependabot[bot])
* Add AdMobIntegrationSample example app xcodeproj and config (#6502) via Pol Miro (@polmiro)
* Unify event store directory resolution via DirectoryHelper (#6501) via Antonio Pallares (@ajpallares)
* Replace custom tag-release-branch with orb's tag-current-branch (#6505) via Antonio Pallares (@ajpallares)
* Bump json from 2.16.0 to 2.17.1.2 (#6482) via dependabot[bot] (@dependabot[bot])
* Add AdMob adapter to release pipeline (#6486) via Pol Miro (@polmiro)
* Move AdMobIntegrationSample Tuist project to Projects/ (#6493) via Antonio Pallares (@ajpallares)
* Fix API diff check by replacing external tool with direct file comparison (#6459) via Antonio Pallares (@ajpallares)
* Bump nokogiri from 1.19.1 to 1.19.2 (#6489) via dependabot[bot] (@dependabot[bot])
* Add tvOS support to RCTTester app (#6483) via Antonio Pallares (@ajpallares)
* AdMob adapter (#6278) via Pol Miro (@polmiro)
