## RevenueCat SDK
### 🐞 Bugfixes
* Restore `rethrows` on `toPresentedOverrides` (#6419) via Facundo Menzella (@facumenzella)
* Fix reduced timeouts being used for HTTP requests when a proxy URL is configured (#6416) via Rick (@rickvdl)

## RevenueCatUI SDK
### Paywallv2
#### ✨ New Features
* [Rules] Introduce rule system (#6285) via Facundo Menzella (@facumenzella)
### Customer Center
#### ✨ New Features
* Track paywall source for Customer Center purchases (#5691) via Facundo Menzella (@facumenzella)

### 🔄 Other Changes
* Remove automatic Claude code review workflow (#6429) via Cesar de la Vega (@vegaro)
* Bump fastlane-plugin-revenuecat_internal from `f5c099b` to `e146447` (#6428) via dependabot[bot] (@dependabot[bot])
* Add slack-notify-on-fail to more CI jobs (#6328) via Antonio Pallares (@ajpallares)
* Add priority flush with rate limiting and queuing (#6408) via Rick (@rickvdl)
* Refactor ConditionContext creation and simplify presented overrides (#6423) via Facundo Menzella (@facumenzella)
* Fix PaywallsV2 label name in AGENTS.md (#6424) via Facundo Menzella (@facumenzella)
* Update sdks-common-config orb to 3.14.0 (#6417) via Antonio Pallares (@ajpallares)
* Support different modes for depending on RevenueCat when using Tuist (#5888) via Antonio Pallares (@ajpallares)
