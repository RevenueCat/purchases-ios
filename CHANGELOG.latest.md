## RevenueCat SDK
### Remote-config
#### 🐞 Bugfixes
* Refresh remote config when syncing attributes and offerings (#7323) via Antonio Pallares (@ajpallares)

## RevenueCatUI SDK
### ✨ New Features
* feat: add onURLOpened to paywall listener surfaces (#7320) via Toni Rico (@tonidero)
### Paywallsv2
#### ✨ New Features
* Enable support for multipage paywalls (#7327) via Facundo Menzella (@facumenzella)
#### 🐞 Bugfixes
* Send `paywall_id` and `trace_id` on post receipt (#7311) via Cesar de la Vega (@vegaro)

### 🔄 Other Changes
* fix(remote-config): clear last attempt timestamp for cooldown after successful response (#7328) via Rick (@rickvdl)
* fix(maestro): tap the relabeled Continue buttons in the workflow flows (#7332) via Antonio Pallares (@ajpallares)
* chore: align 5.82.0 changelog entry for #7233 with release notes (#7326) via Antonio Pallares (@ajpallares)
* feat(remote-config): force the config kill-switch via query param in E2E tests (#7317) via Antonio Pallares (@ajpallares)
* Send `paywall_id`, `workflow_id` and `trace_id` on paywall events (#7322) via Cesar de la Vega (@vegaro)
* Re-resolve pruned offerings when the config kill switch trips (#7321) via Antonio Pallares (@ajpallares)
* feat(remote-config): use the server clock for X-RC-Last-Refresh-Time (#7314) via Rick (@rickvdl)
* test(paywalls): drop the nested background landscape test (#7319) via Facundo Menzella (@facumenzella)
* refactor: model ForceServerErrorStrategy interception as a single Action enum (#7315) via Antonio Pallares (@ajpallares)
