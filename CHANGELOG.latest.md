## RevenueCatUI SDK
### 🐞 Bugfixes
* Fallback to using variations of language code, script, and region for unknown `Locale` (ex: `zh_CN` will look for `zh_Hans`) (#4870) via Josh Holtz (@joshdholtz)

### 🔄 Other Changes
* Deprecates `CustomerCenterActionHandler` in favor of modifiers (#4844) via Cesar de la Vega (@vegaro)
* [Diagnostics] Add offerings start and result events (#4866) via Toni Rico (@tonidero)
* [Diagnostics] fix diagnostics sync retry logic (#4868) via Antonio Pallares (@ajpallares)
* Fix iOS 14 + 15 unit tests after root error issues (#4873) via Toni Rico (@tonidero)
* [Diagnostics] add `error_entering_offline_entitlements_mode` event (#4867) via Antonio Pallares (@ajpallares)
* Fix crash in SwiftUI previews (#4871) via Antonio Pallares (@ajpallares)
* chore: Remove unused key from customer center event (#4837) via Facundo Menzella (@facumenzella)
* chore: `EventsManagerIntegrationTests` working as expected (#4862) via Facundo Menzella (@facumenzella)
* [Diagnostics] add `entered_offline_entitlements_mode` event (#4865) via Antonio Pallares (@ajpallares)
* Add root error info to public error (#4680) via Toni Rico (@tonidero)
* [Diagnostics] add `clearing_diagnostics_after_failed_sync` event (#4863) via Antonio Pallares (@ajpallares)
* [Diagnostics] add `max_diagnostics_sync_retries_reached` event (#4861) via Antonio Pallares (@ajpallares)
* Update `customerInfo` from an `AsyncStream` instead of the `PurchasesDelegate` in the SwiftUI sample app (#4860) via Pol Piella Abadia (@polpielladev)
* Remove resetting `appSessionId` for customer center + add `appSessionId` and `eventId` to diagnostics events (#4855) via Toni Rico (@tonidero)
* fix: diagnostics parameter key name (#4859) via Antonio Pallares (@ajpallares)
* [Diagnostics] add missing parameter to `http_request_performed` event (#4857) via Antonio Pallares (@ajpallares)
* Create `DiagnosticsEvent.Properties` for type safe diagnostics (#4843) via Antonio Pallares (@ajpallares)
* Have snapshot tests use same encoding as SDK (#4856) via Antonio Pallares (@ajpallares)
