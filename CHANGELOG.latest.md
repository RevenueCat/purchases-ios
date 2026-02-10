## RevenueCat SDK
### ✨ New Features
* [CEC Mode]: Introduce isPurchaseAllowedByRestoreBehavior() (#6192) via Will Taylor (@fire-at-will)

## RevenueCatUI SDK
### Paywallv2
#### 🐞 Bugfixes
* Fix product.currency_symbol to use product currency instead of locale (#6209) via Facundo Menzella (@facumenzella)

### 🔄 Other Changes
* Cache `presentedOfferingContext` when making a purchase from a paywall (#6228) via Antonio Pallares (@ajpallares)
* Add XCFramework installation tests to the release checks (#6195) via Rick (@rickvdl)
* Deprioritize debug health check to avoid blocking user-facing requests at startup (#6230) via Antonio Pallares (@ajpallares)
