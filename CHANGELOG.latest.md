## RevenueCat SDK
### Remote-config
#### 🐞 Bugfixes
* fix(remote-config): Cache remote config workflows in-memory to avoid loading flash (#7213) via Rick (@rickvdl)

### 🔄 Other Changes
* Eagerly prewarm workflow assets without retaining decoded workflows (#7256) via Rick (@rickvdl)
* fix(remote-config): lazy-decode prefetched workflows (#7246) via Rick (@rickvdl)
* test(workflows): add Maestro flows for custom variable default + override (#7243) via Facundo Menzella (@facumenzella)
* fix(paywalls): restore MainActor isolation on exit-offer View helpers (#7253) via Facundo Menzella (@facumenzella)
* Chore(deps): Bump fastlane-plugin-revenuecat_internal from `dab6765` to `9e334ff` (#7255) via dependabot[bot] (@dependabot[bot])
* test(workflows): add Maestro flow for Spanish workflow localizations (#7242) via Facundo Menzella (@facumenzella)
* other(paywalls): gate workflow exit offer by step on the present(offering:) path (#7245) via Facundo Menzella (@facumenzella)
* Avoid paywall loading state when remote config is disabled through killswitch (#7251) via Rick (@rickvdl)
* Move initial paywall data seeding into purchase handler (#7239) via Rick (@rickvdl)
* Fix RemoteConfigManagerTests missing fetchContext on main (#7252) via Antonio Pallares (@ajpallares)
* fix(remote-config): throttle failed refresh attempts (#7191) via Rick (@rickvdl)
* refactor(remote-config) reduce offerings memory when using remote-config (and thus workflows) (#7220) via Rick (@rickvdl)
* Chore: Add default size to Fit sizes (#7226) via Jacob Rakidzich (@JZDesign)
* feat(remote-config): source API base host from remote-config sources (#7123) via Antonio Pallares (@ajpallares)
* Deprecate Offering.paywallComponents (#7244) via Antonio Pallares (@ajpallares)
* other(paywalls): render the default paywall when an offering has no workflow (#7240) via Facundo Menzella (@facumenzella)
* ci: run the workflow Maestro flows on every PR (#7241) via Facundo Menzella (@facumenzella)
* test(remote-config): fix integration test conformance to usesRemoteConfigAPISources (#7238) via Antonio Pallares (@ajpallares)
* feat(remote-config): add internal usesRemoteConfigAPISources dangerous setting (#7236) via Antonio Pallares (@ajpallares)
