## RevenueCatUI SDK
### 🐞 Bugfixes
* Fix Paywalls V2 carousel image stuck in size-unknown state on first display (#7180) via Jacob Rakidzich (@JZDesign)
### Paywallv2
#### ✨ New Features
* feat(paywalls): support transparent sticky footers (#7188) via Álvaro Brey (@AlvaroBrey)

### 🔄 Other Changes
* test(workflows): add Maestro flow that navigates a workflow paywall to purchase (#7221) via Facundo Menzella (@facumenzella)
* ci(remote-config): run the blob health monitor (#7218) via Facundo Menzella (@facumenzella)
* test(remote-config): add a real-backend health check for CDN blob downloads (#7215) via Facundo Menzella (@facumenzella)
* feat(remote-config): send fetch_context on config endpoint requests (#7214) via Antonio Pallares (@ajpallares)
* Internal `DangerousSettings.useWorkflows` to enable remote config/workflows programmatically (#7209) via Cesar de la Vega (@vegaro)
* test(remote-config): cover downloading several config blobs at once (#7212) via Facundo Menzella (@facumenzella)
* test(remote-config): cover getOfferings delivering when a prefetch blob fails (#7211) via Facundo Menzella (@facumenzella)
* Use short timeouts for remote config blob downloads (#7210) via Rick (@rickvdl)
* perf(remote-config): give /config its own request lane so it overlaps /offerings (#7196) via Facundo Menzella (@facumenzella)
* Pass Tuist Swift conditions to local package (#7195) via Rick (@rickvdl)
* other(remote-config): stabilize flaky RemoteConfig blob integration test (#7193) via Antonio Pallares (@ajpallares)
* Chore(deps): Bump excon from 0.112.0 to 1.5.0 in /Tests/InstallationTests/CocoapodsInstallation (#7190) via dependabot[bot] (@dependabot[bot])
* fix(ci): stop mirroring main to purchases-ios-spm, tags only (#7189) via Álvaro Brey (@AlvaroBrey)
* feat(remote-config): add static fallback config endpoint (#7182) via Rick (@rickvdl)
* Chore(deps): Bump cocoapods from 1.16.2 to 1.17.0 (#7187) via dependabot[bot] (@dependabot[bot])
* Don't switch hosts on device-connectivity errors (#7176) via Antonio Pallares (@ajpallares)
* other(offerings): gate getOfferings delivery on ui_config and stale-cache paths (#7181) via Facundo Menzella (@facumenzella)
* fix(remote-config): align edge-case handling with Android implementation (#7173) via Rick (@rickvdl)
* fix(paywalls): fail decoding a present-but-malformed custom_variables (#7184) via Antonio Pallares (@ajpallares)
* Chore(deps): Bump fastlane from 2.236.1 to 2.237.0 (#7175) via dependabot[bot] (@dependabot[bot])
* fix(remote-config): bind refresh requests to identity clears (#7150) via Rick (@rickvdl)
* New IAMEnabled configuration option (#7146) via Dave DeLong (@davedelong)
