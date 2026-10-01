## RevenueCat SDK
### ✨ New Features
* refactor(ads): rename rewarded ad prompt types to AdRewardPrompt* (#7880) via Drago Crnjac (@popcorn)
* feat(ads): track rewarded ad prompt shown and accepted events (#7858) via Drago Crnjac (@popcorn)
* Allow opting in to external purchase custom links (experimental) (#7809) via Antonio Pallares (@ajpallares)
### 🐞 Bugfixes
* fix(customerinfo): notify observers when active entitlements change (#7820) via Peter Porfy (@peterporfy)
### 📦 Dependency Updates
* [RENOVATE] Update dependency revenuecat to v4.6.2 (#7847) via RevenueCat Git Bot (@RCGitBot)

## RevenueCatUI SDK
### 🐞 Bugfixes
* Fix(paywalls) Crash on logout (#7836) via Jacob Rakidzich (@JZDesign)
### Customer Center
#### 🐞 Bugfixes
* Fix Customer Center survey title wrapping on iOS 26 (#7843) via Josh Holtz (@joshdholtz)
### Paywallsv2
#### 🐞 Bugfixes
* Fix Paywalls V2 picking a random regional locale (#7835) via Jamie Holwill (@jholwill)

### 🔄 Other Changes
* Run RevenueCatUI tests on macOS (#7869) via Facundo Menzella (@facumenzella)
* Enable signature verification for web purchase redemption (#7874) via Rick (@rickvdl)
* other(workflows): route a branch trigger action to the step its audiences pick (#7853) via Facundo Menzella (@facumenzella)
* Chore(Paywalls): Add DEBUG-only JSON paywall preview renderer (#7746) via Jacob Rakidzich (@JZDesign)
* Chore(Paywalls): Apply min/max to Fill sizes only (#7770) via Jacob Rakidzich (@JZDesign)
* Fix iOS AdMob capture method (#7844) via Pol Miro (@polmiro)
* Use a positive simulator external purchase setting (#7856) via Antonio Pallares (@ajpallares)
* [SDK-4501] Add `is_synced` to `customer_info` purchase records (#7849) via Toni Rico (@tonidero)
* refactor(checkpoints): rename invite-only API SPI (#7852) via Rick (@rickvdl)
* Allow web purchases in the simulator regardless of storefront (experimental) (#7828) via Antonio Pallares (@ajpallares)
* Tell ineligible customers a web purchase is unavailable (#7831) via Antonio Pallares (@ajpallares)
* Offer no external purchase outside the storefronts the backend allows (#7791) via Antonio Pallares (@ajpallares)
* Chore(deps): Bump fastlane-plugin-sentry from 2.7.0 to 2.8.0 (#7850) via dependabot[bot] (@dependabot[bot])
* Chore(deps): Bump rubyzip from 2.4.1 to 3.4.0 in /Tests/InstallationTests/CocoapodsInstallation (#7845) via dependabot[bot] (@dependabot[bot])
* feat(remote-config): add SDK settings config provider (#7813) via Rick (@rickvdl)
* Give web checkout requests their own backend lane (#7774) via Antonio Pallares (@ajpallares)
* feat(remote-config): prewarm checkpoint rules and audiences (#7781) via Rick (@rickvdl)
* Tell the customer when they already own what the in-app checkout would sell (#7756) via Antonio Pallares (@ajpallares)
* Let a Test Store key run the in-app web checkout and Apple's flow (#7750) via Antonio Pallares (@ajpallares)
* Present the in-app web checkout when external purchases do not apply (#7749) via Antonio Pallares (@ajpallares)
