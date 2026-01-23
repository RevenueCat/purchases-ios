## RevenueCat SDK
### 🐞 Bugfixes
* Fix cache files visible in documents directory: Etags, offerings and product entitlements mapping  (#6020) via Rick (@rickvdl)
* Fix paywall close tracking in PaywallViewController (#6083) via Cesar de la Vega (@vegaro)

## RevenueCatUI SDK
### Paywallv2
#### 🐞 Bugfixes
* fix: Load high with high loader, load low with low loader (#6111) via Facundo Menzella (@facumenzella)
* Fix close button being tappable during transition delay (#6106) via Facundo Menzella (@facumenzella)

### 🔄 Other Changes
* Add LocalKhepri file to be able to work with local instance (#6123) via Facundo Menzella (@facumenzella)
* Fix loading in PaywallsTester when using present functions (#6109) via Cesar de la Vega (@vegaro)
* Use `SKPaymentQueue.default()` instead of initializing a new instance in PurchaseTester app (#6108) via Antonio Pallares (@ajpallares)
* Add Claude Code Review workflow configuration (#6107) via Cesar de la Vega (@vegaro)
