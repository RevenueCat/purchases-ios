## RevenueCat SDK
### ✨ New Features
* Add workflows network layer for multipage paywalls (#6557) via Cesar de la Vega (@vegaro)
### 🐞 Bugfixes
* Resolve the issue around tab control context identity (PWENG-31) (#6634) via Alexander Repty (@alexrepty)
* Fall back to getCustomerInfo when posting unfinished receipt fails (#6650) via Rick (@rickvdl)
* fix(RevenueCatUI): legacy paywall `component_name` parity with Android (#6662) via Monika Mateska (@MonikaMateska)
* Clip carousel pages to card width to fix transient overlay artifact (#6657) via Monika Mateska (@MonikaMateska)
* Fix SPM 'unhandled file' warning for RevenueCatUIDev.xctestplan (#6625) via Rick (@rickvdl)

## RevenueCatUI SDK
### 🐞 Bugfixes
* Defer paywall dismissal after purchase callbacks (#6621) via Jacob Rakidzich (@JZDesign)
### Paywallsv2
#### 🐞 Bugfixes
* Replace fatalError with assertionFailure + throw for fallbackHeader (#6636) via Facundo Menzella (@facumenzella)

### 🔄 Other Changes
* fix: fallback_pr_lookup boolean check in Fastfile (#6672) via Antonio Pallares (@ajpallares)
* Add opt-in bump_with_fallback_pr_lookup CircleCI parameter (#6669) via Antonio Pallares (@ajpallares)
* Bump fastlane-plugin-revenuecat_internal from `b822f01` to `d24ab26` (#6670) via dependabot[bot] (@dependabot[bot])
* AdMob SSV: add `@_spi(Internal)` poll endpoint on `Purchases` (#6641) via Pol Miro (@polmiro)
* Skip CI on auto-generated snapshot branches (#6633) via Rick (@rickvdl)
* Add TUIST_LAUNCH_ARGUMENTS env var for injecting launch arguments at generation time (#6664) via Facundo Menzella (@facumenzella)
* Add workflow to re-run Danger on PR label change (#6660) via Rick (@rickvdl)
* Fix rcgitbot_please_test token permissions for PR comments (#6655) via Antonio Pallares (@ajpallares)
* Add pr:other label to auto-generated snapshot PRs (#6631) via Rick (@rickvdl)
* Add TUIST_SWIFT_CONDITIONS for injecting compiler flags at project generation time (#6661) via Facundo Menzella (@facumenzella)
* Skip SPM Release Build steps during snapshot-generation pipelines (#6659) via Antonio Pallares (@ajpallares)
* Fix iOS 15 snapshot-generation job hanging indefinitely (#6658) via Antonio Pallares (@ajpallares)
* Bump fastlane-plugin-revenuecat_internal from `e348913` to `b822f01` (#6651) via dependabot[bot] (@dependabot[bot])
* Use env-var interpolation in rcgitbot_please_test workflow (#6649) via Antonio Pallares (@ajpallares)
* Expose `apiKey` on `Purchases` via `@_spi(Internal)` (#6635) via Pol Miro (@polmiro)
* Bump fastlane from 2.232.2 to 2.233.0 (#6639) via dependabot[bot] (@dependabot[bot])
* Bump fastlane-plugin-revenuecat_internal from `a1eed48` to `e348913` (#6638) via dependabot[bot] (@dependabot[bot])
* Add @RCGitBot please test <job-name> on-demand job trigger (#6607) via Antonio Pallares (@ajpallares)
* Migrate CircleCI to dynamic configuration (#6605) via Antonio Pallares (@ajpallares)
* Bump fastlane from 2.229.1 to 2.232.2 and fix Mac Catalyst archive export (#6370) via dependabot[bot] (@dependabot[bot])
* Add automated GitHub releases for purchases-ios-admob (#6537) via Pol Miro (@polmiro)
* Add missing source files to RevenueCat.xcodeproj (#6624) via Rick (@rickvdl)
* UI events for paywall component interactions (#6523) via Monika Mateska (@MonikaMateska)
* Run paywalls V1 snapshot recording on main and release branches (#6620) via Rick (@rickvdl)
* fix(ads): remove mistake masking behavior (#6613) via Peter Porfy (@peterporfy)
* Use shared run_maestro_e2e_tests action from fastlane plugin (#6616) via Antonio Pallares (@ajpallares)
* Bump fastlane-plugin-revenuecat_internal from `20911d1` to `a1eed48` (#6618) via dependabot[bot] (@dependabot[bot])
