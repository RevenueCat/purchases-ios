## RevenueCat SDK
### 🐞 Bugfixes
* Xcode 27 Beta Compilation Fix (#6949) via Will Taylor (@fire-at-will)
* fix(workflows): Don't serve stale workflows when the backend rejects the request (#6946) via Facundo Menzella (@facumenzella)
* Fix badge stack shadow not being rendered (#6921) via Monika Mateska (@MonikaMateska)
* Don't log App Store / StoreKit messages when using a Test Store API key (#6906) via Rick (@rickvdl)

## RevenueCatUI SDK
### Paywallv2
#### ✨ New Features
* feat(workflows): persist prefetched workflow detail on disk (#6917) via Facundo Menzella (@facumenzella)
* feat(workflows): bridge workflow exit offer into PaywallViewController (#6911) via Facundo Menzella (@facumenzella)
* feat(workflows): synchronously seed workflow paywall from warm cache (#6905) via Facundo Menzella (@facumenzella)
* [PW-128] Redact text in V2 paywalls while eligibility checks are pending (#6775) via Facundo Menzella (@facumenzella)

### 🔄 Other Changes
* fix: skip RootView layout snapshot tests on iOS 15 (#6953) via Antonio Pallares (@ajpallares)
* other(workflows): Run workflow detail prefetches on a dedicated concurrent queue (#6916) via Facundo Menzella (@facumenzella)
* [AUTOMATIC][Paywalls V2] Updates commit hash of paywall-preview-resources (#6942) via RevenueCat Git Bot (@RCGitBot)
* Skip Swift Testing predicate tests on Xcode 14/15 (#6937) via Antonio Pallares (@ajpallares)
* Represent ±Infinity in test fixtures via test-only variables (#6936) via Antonio Pallares (@ajpallares)
* Add JSON Logic `min` and `max` operators (#6825) via Antonio Pallares (@ajpallares)
* Add JSON Logic iteration operators (`some`, `all`) (#6817) via Antonio Pallares (@ajpallares)
* Skip release-or-main when manual snapshot workflows run (#6935) via Antonio Pallares (@ajpallares)
* Migrate base RulesEngineInternal operator unit tests to JSON predicate fixtures (#6885) via Antonio Pallares (@ajpallares)
* docs: add PR sizing and description guidelines to AGENTS.md (#6915) via Antonio Pallares (@ajpallares)
* Update some CI jobs to Xcode 26.5 (#6555) via Antonio Pallares (@ajpallares)
* fix(tuist): add missing test target deps (#6894) via Peter Porfy (@peterporfy)
* Fix flaky tests caused by data races in MockDeviceCache (#6888) via Rick (@rickvdl)
