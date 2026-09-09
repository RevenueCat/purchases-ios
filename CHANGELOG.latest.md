## RevenueCat SDK
### ✨ New Features
* feat(ads): ad tracking and rewarded ad grants beta (#7490) via Peter Porfy (@peterporfy)
### 🐞 Bugfixes
* Fix Paywall V2 rendering when components are provided by an offering (#7655) via Rick (@rickvdl)
* fix: send X-Is-Sandbox header when using a Test Store API key (#7624) via Álvaro Brey (@AlvaroBrey)
* Fix URL-open publishing on a background thread (#7631) via Rick (@rickvdl)

## RevenueCatUI SDK
### ✨ New Features
* feat(paywalls): Add onPaywallInteraction callback (#7583) via Álvaro Brey (@AlvaroBrey)
### 🐞 Bugfixes
* fix: use each rule's own badge contents (#7532) via Facundo Menzella (@facumenzella)
### Paywallsv2
#### ✨ New Features
* Run Apple's external purchase flow before opening a web purchase link (#7663) via Antonio Pallares (@ajpallares)
* Add window size conditions for paywall component overrides (#7645) via Josh Holtz (@joshdholtz)
* Feat(Paywalls): Underline text support (#5935) via Jacob Rakidzich (@JZDesign)
#### 🐞 Bugfixes
* Present sheet content only after its first layout pass (#7630) via Facundo Menzella (@facumenzella)
### Customer Center
#### ✨ New Features
* feat(customer center): show Resubscribe for cancelled subscriptions (#7617) via Facundo Menzella (@facumenzella)
#### 🐞 Bugfixes
* fix(customer center): hide refund and change plan on family-shared subs (#7605) via Facundo Menzella (@facumenzella)

### 🔄 Other Changes
* Prepare one external purchase at a time (#7671) via Antonio Pallares (@ajpallares)
* Add a dangerous setting for external purchase custom links (#7662) via Antonio Pallares (@ajpallares)
* Tell payment authorization apart from external purchase eligibility (#7667) via Antonio Pallares (@ajpallares)
* Answer canMakePayments through AppStore rather than SKPaymentQueue (#7669) via Antonio Pallares (@ajpallares)
* Remove assertion (#7665) via Dave DeLong (@davedelong)
* feat(checkpoints): log checkpoint rule evaluation (#7650) via Rick (@rickvdl)
* refactor(checkpoints): remove backend predicate results (#7603) via Rick (@rickvdl)
* fix(checkpoints): fix audience loading and missing-dimension evaluation (#7602) via Rick (@rickvdl)
* fix(checkpoints): ensure remote config reads are generation consistent (#7575) via Rick (@rickvdl)
* Chore(deps): Bump fastlane from 2.238.0 to 2.239.0 (#7654) via dependabot[bot] (@dependabot[bot])
* Skip the external purchase flow when configured with a Test Store key (#7643) via Antonio Pallares (@ajpallares)
* Add the manager that orchestrates the external purchase StoreKit calls (#7628) via Antonio Pallares (@ajpallares)
* feat(remote-config): remove the remote config session kill switch (#7524) via Rick (@rickvdl)
* Add the networking layer for starting a hosted checkout (#7627) via Antonio Pallares (@ajpallares)
* Add the networking layer for registering external purchase tokens (#7596) via Antonio Pallares (@ajpallares)
* Add an internal wrapper over StoreKit's ExternalPurchaseCustomLink (#7594) via Antonio Pallares (@ajpallares)
* feat(Checkpoints): namespace checkpoint result and context types (#7570) via Rick (@rickvdl)
* fix(Checkpoints): Fail rule resolution when the app user changes (#7554) via Rick (@rickvdl)
* feat(Checkpoints): Cache subscriber dimensions and evaluate rules against them (#7553) via Rick (@rickvdl)
* feat(Checkpoints): Add customer purchases and entitlements as rule evaluation properties (#7550) via Rick (@rickvdl)
* feat(Checkpoints): Reshape rule evaluation properties (#7544) via Rick (@rickvdl)
* feat(Checkpoints): consume canonical audience configuration (#7543) via Rick (@rickvdl)
* Remove unused shouldWarnCustomersAboutMultipleSubscriptions (#7618) via Facundo Menzella (@facumenzella)
* Expand "isAnonymous" check (#7591) via Dave DeLong (@davedelong)
* Add IAM-specific webbilling paths (#7572) via Dave DeLong (@davedelong)
* ci: bump external PR notifications workflow to v8 (#7604) via Álvaro Brey (@AlvaroBrey)
* Remove the transform entry point from the rules engine (#7576) via Antonio Pallares (@ajpallares)
* ci: notify external PRs feed on PRs from outside the org (#7601) via Álvaro Brey (@AlvaroBrey)
* Add `DangerousSettings.forceAllowTestStoreInReleaseBuilds` (#7600) via Toni Rico (@tonidero)
* Remove access token revocation (#7573) via Dave DeLong (@davedelong)
* Chore(Paywalls): Update models to support min/max sizes (#7590) via Jacob Rakidzich (@JZDesign)
* Move the shared web view code out of the paywall component folder (#7598) via Antonio Pallares (@ajpallares)
