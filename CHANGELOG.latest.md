## RevenueCat SDK
### 🐞 Bugfixes
* Fix Backwards compatibility errors introduced by new `testSDKHealthCheck` implementation (#5022) via Pol Piella Abadia (@polpielladev)
* [Paywalls v2] fixes crash when getting invalid URL from paywall components localization (#5016) via Antonio Pallares (@ajpallares)

## RevenueCatUI SDK
### Paywallv2
#### 🐞 Bugfixes
* [Paywalls v2] Fixes blank lines not showing up (#5024) via JayShortway (@JayShortway)
### Customer Center
#### 🐞 Bugfixes
* fix: Wrap viewmodel binding into another binding (#5023) via Facundo Menzella (@facumenzella)

### 🔄 Other Changes
* [Paywalls] Add new button component action for web paywall links (#5029) via Mark Villacampa (@MarkVillacampa)
* [Customer center] show manage subscriptions through purchases provider (#5025) via Antonio Pallares (@ajpallares)
* [Diagnostics] add `host` parameter to `http_request_performed` event (#4982) via Antonio Pallares (@ajpallares)
* fix compilation issues in older versions of Xcode (#5021) via Antonio Pallares (@ajpallares)
* Add load shedder integration tests for consumable and non-consumable products (#5018) via Toni Rico (@tonidero)
* Use fallback API hosts when receiving server down response (#4970) via Antonio Pallares (@ajpallares)
* feat: Introduce maestro for UI testing (#5013) via Facundo Menzella (@facumenzella)
* [Paywalls v2] Adds logs to indicate whether URLs are opened successfully (#5020) via JayShortway (@JayShortway)
* [DX-345] Update the `testSDKHealth` to use the new `/health_report` endpoint (#4979) via Pol Piella Abadia (@polpielladev)
