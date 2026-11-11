## RevenueCat SDK
### 🐞 Bugfixes
* Revert CocoaPods migration warning (#8203) (#8239) via Antonio Pallares (@ajpallares)
* feat(checkpoints): gate rewarded ad steps on an earned reward (#8232) via Peter Porfy (@peterporfy)
### 📦 Dependency Updates
* [RENOVATE] Update dependency revenuecat to v4.8.0 (#8240) via RevenueCat Git Bot (@RCGitBot)
### Paywallsv2
#### 🐞 Bugfixes
* fix: reduce peak memory during workflow web component prewarming (#8192) via Rick (@rickvdl)

## RevenueCatUI SDK
### 🐞 Bugfixes
* Clear custom paywall purchase loading state after completion (#8277) via Antonio Pallares (@ajpallares)
* fix(workflows): Prevent redraws due to injected closures (#8265) via Jacob Rakidzich (@JZDesign)
### Paywallsv2
#### ✨ New Features
* Add API to forward promotional offers to paywall purchase handlers (#8275) via Antonio Pallares (@ajpallares)
#### 🐞 Bugfixes
* fix(Paywalls): Conditionally observe text override triggers when applicable (#8266) via Jacob Rakidzich (@JZDesign)
* fix(Paywalls): Preserve identity of the package context across redraws (#8267) via Jacob Rakidzich (@JZDesign)
* fix(paywalls): clip the background media without re-rendering the content (#8264) via Jacob Rakidzich (@JZDesign)
* ONC-50 | Use paywall text color for markdown links (#8243) via Rosie Watson (@RosieWatson)
* ONC-34: Fix tab-button discount package context (#8187) via Facundo Menzella (@facumenzella)
### Checkpoints
#### ✨ New Features
* feat(checkpoints): client-reported rewards for ad steps (#8225) via Drago Crnjac (@popcorn)

### 🔄 Other Changes
* chore(paywalls): skip disk check for images already in memory (#8253) via Jacob Rakidzich (@JZDesign)
* chore(paywalls): cache rendered markdown (#8252) via Jacob Rakidzich (@JZDesign)
* chore(paywalls): Memoize getLocalization (#8251) via Jacob Rakidzich (@JZDesign)
* refactor(checkpoints): rename client_reported reward verification to none (#8269) via Drago Crnjac (@popcorn)
* Lint AutomatedSDKTestsApp and fix 2 repo config paths (#8194) via Facundo Menzella (@facumenzella)
* Chore(deps): Bump nokogiri from 1.19.4 to 1.19.5 in /Tests/InstallationTests/CocoapodsInstallation (#8268) via dependabot[bot] (@dependabot[bot])
* Add missing RevenueCatUI snapshots (#8261) via Rick (@rickvdl)
* fix(checkpoints): close workflow after restore grants an entitlement (#7952) via Rick (@rickvdl)
* [EXTERNAL] docs: clarify isAnonymous documentation (#8241) via @tkanzakic (#8249) via Antonio Pallares (@ajpallares)
* Revert "build: don't block releases on CocoaPods publishing" (#8236) via Antonio Pallares (@ajpallares)
* Reduce fixture UI test time in CI (#8244) via Facundo Menzella (@facumenzella)
* feat(ads): cache customer info from verified reward polls instead of refetching (#8166) via Peter Porfy (@peterporfy)
* Stabilize pending purchase and renewal integration test (#8224) via Rick (@rickvdl)
* Restrict GitHub tokens to the jobs that need them (#8242) via Antonio Pallares (@ajpallares)
* ci: merge gate that tightens once the full suite is approved (#8235) via Álvaro Brey (@AlvaroBrey)
