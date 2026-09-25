## RevenueCat SDK
### 🐞 Bugfixes
* Prevent subscriber attribute sync before CustomerInfo is available (#7793) via Rick (@rickvdl)

## RevenueCatUI SDK
### ✨ New Features
* [EXTERNAL] Hide decorative paywall media from VoiceOver (#7545) via @t9mike (#7702) via Facundo Menzella (@facumenzella)
### 🐞 Bugfixes
* Fix(Paywalls): Prevent Fill children from expanding the paywall root (#7782) via Jacob Rakidzich (@JZDesign)
* Fix(Paywalls) Support Web Views in looping carousels (#7688) via Jacob Rakidzich (@JZDesign)
### Paywallsv2
#### 🐞 Bugfixes
* fix: keep VoiceOver inside the bottom sheet when the paywall scrolls (#7810) via Facundo Menzella (@facumenzella)
* Fix relative discounts for workflow paywalls with plans in sheets (#7775) via Josh Holtz (@joshdholtz)

### 🔄 Other Changes
* other: maestro e2e notifications on recovery, and run the workflow flows like e2e (#7807) via Facundo Menzella (@facumenzella)
* other: Add trace_id to the checkpoint hit event (#7811) via Facundo Menzella (@facumenzella)
* Add signature verification failure context to diagnostics (#7800) via Rick (@rickvdl)
* Extract signature verification failure reasons (#7777) via Rick (@rickvdl)
* other(workflows): maestro flows for workflow experiments (#7805) via Facundo Menzella (@facumenzella)
* other(billing plans): run SKConfig unit + integration tests for billing plans (#6899) via Will Taylor (@fire-at-will)
* other(CI): introduce iOS 27 CI jobs (#7705) via Will Taylor (@fire-at-will)
* Chore(deps): Bump fastlane-plugin-sentry from 2.6.3 to 2.7.0 (#7795) via dependabot[bot] (@dependabot[bot])
* Only announce backend integration test successes on recovery (#7776) via Facundo Menzella (@facumenzella)
* Chore(deps): Bump fastlane from 2.240.0 to 2.240.1 (#7796) via dependabot[bot] (@dependabot[bot])
* Chore(deps): Bump fastlane-plugin-revenuecat_internal from `a65e499` to `9f7a03e` (#7794) via dependabot[bot] (@dependabot[bot])
* Auto-approve the next-version SNAPSHOT PR (#7792) via Álvaro Brey (@AlvaroBrey)
* Chore(deps): Bump fastlane-plugin-sentry from 2.6.1 to 2.6.3 (#7772) via dependabot[bot] (@dependabot[bot])
* fix(checkpoints): only continue flows for restores that grant access (#7771) via Rick (@rickvdl)
* feat(checkpoints): follow-up improvements (#7752) via Rick (@rickvdl)
* Upload iOS size analysis builds to Sentry (#7275) via Rick (@rickvdl)
* refactor(checkpoints): disable exit offers for checkpoint paywalls (#7761) via Rick (@rickvdl)
* feat(checkpoints): add app-owned offering presenter API (#7626) via Rick (@rickvdl)
* docs: Link the paywall interaction event reference (#7732) via Álvaro Brey (@AlvaroBrey)
