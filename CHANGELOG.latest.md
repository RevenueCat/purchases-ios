## RevenueCat SDK
### ✨ New Features
* feat(paywalls): prewarm videos for current locale (#7915) via Sufi Gaffar (@sufigaffar)
* feat(paywalls): implement support for localized videos on iOS (#7914) via Sufi Gaffar (@sufigaffar)
### 🐞 Bugfixes
* fix(paywalls): use video size for thumbnail overlay (#7918) via Sufi Gaffar (@sufigaffar)

## RevenueCatUI SDK
### 🐞 Bugfixes
* fix(paywalls): use the passed Offering instance for matching workflow steps (#7932) via Toni Rico (@tonidero)
* FIX(Paywalls) Custom Component not rendering in iOS 27 (#7897) via Jacob Rakidzich (@JZDesign)
* Report cancelled paywall purchases even when CustomerInfo can't be fetched (#7895) via Antonio Pallares (@ajpallares)
* Remove video fade-in over the paywall thumbnail (#7905) via Cesar de la Vega (@vegaro)
### Paywallsv2
#### ✨ New Features
* FEAT(Paywalls) enable min/max sizing (#7904) via Jacob Rakidzich (@JZDesign)
#### 🐞 Bugfixes
* Honor explicit no-scroll on root z-layer paywalls (#7870) via Josh Holtz (@joshdholtz)
### Customer Center
#### 🐞 Bugfixes
* Customer Center: fix crash on iOS 17 and 18 with Xcode 27 builds (#7917) via Facundo Menzella (@facumenzella)

### 🔄 Other Changes
* other: expose StoreProduct.id internally (#7930) via Will Taylor (@fire-at-will)
* Confirm a kept hosted checkout once when its page succeeds during a buy tap (#7927) via Antonio Pallares (@ajpallares)
* Let the backend decide which hosted checkout session the customer continues (#7910) via Antonio Pallares (@ajpallares)
* Confirm a hosted checkout whose page succeeds after the sheet was closed (#7891) via Antonio Pallares (@ajpallares)
* Keep a paywall's hosted checkout so buying again carries on with it (#7890) via Antonio Pallares (@ajpallares)
* Resume a customer's previous hosted checkout session (#7889) via Antonio Pallares (@ajpallares)
* Resolve workflow offerings through a single WorkflowOfferings wrapper (#7938) via Toni Rico (@tonidero)
* Add Maestro flow for developer-provided offering filtering packages (#7934) via Toni Rico (@tonidero)
* other: send fallback_original_step_id and always send blob_ref on workflow events (#7878) via Facundo Menzella (@facumenzella)
* Add checkpoint testing to PaywallsTester (#7923) via Rick (@rickvdl)
* feat(checkpoints): resolve subscriber dimensions from config and receipts endpoints (#7919) via Rick (@rickvdl)
* feat(checkpoints): read subscriber dimensions from remote config (#7902) via Rick (@rickvdl)
* Use shared Sentry CI metadata action (#7854) via Rick (@rickvdl)
* Chore(deps): Bump fastlane-plugin-revenuecat_internal from `c3e3afe` to `4c49d48` (#7921) via dependabot[bot] (@dependabot[bot])
* feat(checkpoints): add error presenter API (#7901) via Rick (@rickvdl)
* feat(checkpoints): add presentation modes to checkpoint flows (#7894) via Rick (@rickvdl)
* other(workflows): pin each user to a variant in the experiment maestro flow (#7896) via Facundo Menzella (@facumenzella)
* other(workflows): route the first step with the workflow's initial trigger (#7879) via Facundo Menzella (@facumenzella)
* Chore(deps): Bump fastlane-plugin-revenuecat_internal from `9f7a03e` to `c3e3afe` (#7909) via dependabot[bot] (@dependabot[bot])
* Add Maestro flow for a workflow screen without text (#7899) via Facundo Menzella (@facumenzella)
* Tell the customer when the hosted checkout cannot be started (#7851) via Antonio Pallares (@ajpallares)
* Confirm hosted checkout purchases with an alert before reporting them (#7888) via Antonio Pallares (@ajpallares)
* Settle hosted checkout paywalls on what the backend confirms (#7887) via Antonio Pallares (@ajpallares)
* Poll the hosted checkout session before settling an in-app web purchase (#7886) via Antonio Pallares (@ajpallares)
* Add the hosted checkout session status endpoint (#7885) via Antonio Pallares (@ajpallares)
* Remove the hosted checkout cancel URL (#7881) via Antonio Pallares (@ajpallares)
* Title the already-owned hosted checkout alert as a purchase (#7893) via Antonio Pallares (@ajpallares)
* AGENTS.md update 2026 September (#7884) via cursor[bot] (@cursor[bot])
* feat(ads): send ad unit id to backend during reward polling (#7872) via Peter Porfy (@peterporfy)
* feat(diagnostics): configure collection from SDK settings (#7815) via Rick (@rickvdl)
* refactor(remote-config): introduce config lifecycle observers (#7875) via Rick (@rickvdl)
* other(paywalls): extract prototype skeleton UI (#7873) via Facundo Menzella (@facumenzella)
