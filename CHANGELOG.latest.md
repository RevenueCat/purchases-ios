## RevenueCat SDK
### 🐞 Bugfixes
* Fix decode for sheet actions without inline sheet (#7158) via Monika Mateska (@MonikaMateska)
* Expose preferred UI locale override APIs to Objective-C (#7121) via Álvaro Brey (@AlvaroBrey)

## RevenueCatUI SDK
### 🐞 Bugfixes
* fix(paywalls-v2): fix package selection resetting unexpectedly when switching tabs (#7148) via Facundo Menzella (@facumenzella)

### 🔄 Other Changes
* other(workflows): unify workflows and remote config into a single gate (#7166) via Facundo Menzella (@facumenzella)
* perf(remote-config): merge blob data via byte concatenation (#7163) via Antonio Pallares (@ajpallares)
* other(paywalls): fall back to the offerings paywall when the workflow fetch fails (#7143) via Facundo Menzella (@facumenzella)
* test(remote-config): add additional regression test coverage (#7164) via Rick (@rickvdl)
* feat(remote-config): use merged blobs helper for ui config (#7153) via Rick (@rickvdl)
* other(networking): remove unused workflows OperationQueue and HTTP path cases (#7145) via Facundo Menzella (@facumenzella)
* other(networking): delete the dead workflows endpoint (#7144) via Facundo Menzella (@facumenzella)
* other(paywalls): read workflows from remote config (#7141) via Facundo Menzella (@facumenzella)
* refactor(remote-config): encapsulate topic-ready waiting on RemoteConfigManager (#7157) via Facundo Menzella (@facumenzella)
* test(remote-config): add integration test coverage with mocked API responses (#7147) via Rick (@rickvdl)
* other(paywalls): gate getOfferings on remote-config readiness (#7142) via Facundo Menzella (@facumenzella)
* feat(remote-config): add merged blob data API (#7149) via Rick (@rickvdl)
* other(remote-config): read ui_config via remote config (#7140) via Facundo Menzella (@facumenzella)
* fix(remote-config): use RemoteConfigTopic enum in disk cache tests (#7139) via Antonio Pallares (@ajpallares)
* perf(remote-config): cache persisted config in memory in RemoteConfigDiskCache (#7136) via Antonio Pallares (@ajpallares)
* feat(remote-config): add APIs for reading topic/blob data from RemoteConfigManager (#7134) via Rick (@rickvdl)
* Add SecureItemStorage (#7094) via Dave DeLong (@davedelong)
* Decode id on PaywallComponent.PackageComponent (#7135) via Facundo Menzella (@facumenzella)
* feat(remote-config): add observability logs (#7132) via Rick (@rickvdl)
* feat(remote-config): wire up remote config manager behind feature flag (#7130) via Rick (@rickvdl)
* Support multi-grant reward + moreRewards in reward verification (#7039) via Pol Miro (@polmiro)
* Add CI build step for app extension safe API checks (#7131) via Rick (@rickvdl)
* fix(remote-config): rearm exhausted blob sources + in memory knownRefs (#7120) via Rick (@rickvdl)
* feat(remote-config): disable refresh after client errors (#7118) via Rick (@rickvdl)
