## RevenueCat SDK
### 🐞 Bugfixes
* fix(remote-config): Fix misleading ui_config warnings for projects without paywalls (#7389) via Rick (@rickvdl)

## RevenueCatUI SDK
### 🐞 Bugfixes
* fix(paywalls): don't leave a hidden package selected by default (#7380) via Facundo Menzella (@facumenzella)
* Add accessibility labels for some paywall buttons (#7357) via Facundo Menzella (@facumenzella)
* fix(paywalls): dismiss the UIKit exit offer instead of deferring to the host (#7371) via Facundo Menzella (@facumenzella)
### Paywallsv2
#### 🐞 Bugfixes
* fix(paywalls-v2): select each tab's own default package on workflows (#7373) via Facundo Menzella (@facumenzella)

### 🔄 Other Changes
* feat(checkpoints): Add local rules evaluation foundation (#7306) via Rick (@rickvdl)
* feat(checkpoints): Resolve checkpoints from remote configuration (#7385) via Rick (@rickvdl)
* feat(checkpoints): Expand CheckpointTester use cases (#7382) via Rick (@rickvdl)
* refactor(checkpoints): Only expose APIs behind a feature flag (#7381) via Rick (@rickvdl)
* Chore: reduce component tree traversals on cache warming (#7379) via Jacob Rakidzich (@JZDesign)
* Ingest audiences config topic (#7390) via Cesar de la Vega (@vegaro)
* Chore: Create WebBundleEventBus (#7386) via Jacob Rakidzich (@JZDesign)
* Chore(deps): Bump json from 2.20.0 to 2.21.2 (#7387) via dependabot[bot] (@dependabot[bot])
* fix(checkpoints): Refine unknown checkpoint and workflow resolution (#7384) via Rick (@rickvdl)
* Ingest the checkpoints config topic (#7370) via Facundo Menzella (@facumenzella)
* feat(checkpoints): UI presentation (#7368) via Rick (@rickvdl)
* feat(checkpoints): core engine (#7365) via Rick (@rickvdl)
* feat(checkpoints): CheckpointTester app (#7375) via Rick (@rickvdl)
* feat(checkpoints): public API surface (#7361) via Rick (@rickvdl)
* Chore(deps): Bump fastlane-plugin-revenuecat_internal from `b4e1e7f` to `7fbbe66` (#7378) via dependabot[bot] (@dependabot[bot])
* test(paywalls): Maestro flow for closing the exit offer from UIKit (#7372) via Facundo Menzella (@facumenzella)
