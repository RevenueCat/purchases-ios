## RevenueCat SDK
### ✨ New Features
* feat(ads): allow manual rewarded ad earned tracking (#7954) via Pol Miro (@polmiro)
### 🐞 Bugfixes
* Render lifetime period variables on Paywalls V2 (#7798) via Josh Holtz (@joshdholtz)
### Checkpoints
#### 🐞 Bugfixes
* fix(checkpoints): Prevent duplicate workflow error alerts when an error presenter is configured (#7981) via Rick (@rickvdl)

## RevenueCatUI SDK
### Paywallsv2
#### 🐞 Bugfixes
* fix: a tab switch can show the previous tab's image (#7975) via Facundo Menzella (@facumenzella)

### 🔄 Other Changes
* Stop the web checkout page flickering after the sheet is dragged (#7983) via Antonio Pallares (@ajpallares)
* other(workflows): maestro flow for the experiment variant after a log in (#7922) via Facundo Menzella (@facumenzella)
* Expose subscriber attributes publicly (#7968) via Dave DeLong (@davedelong)
* Open the in-app web checkout from the purchase button (#7862) via Antonio Pallares (@ajpallares)
* Retry a rate-limited hosted checkout status request (#7972) via Antonio Pallares (@ajpallares)
* Report a hosted checkout purchase as started (#7967) via Antonio Pallares (@ajpallares)
* Track how a hosted checkout that never opens ended (#7939) via Antonio Pallares (@ajpallares)
* Keep the web checkout usable when a step fails or its process ends (#7966) via Antonio Pallares (@ajpallares)
* Report the transaction a hosted checkout made to onPurchaseCompleted (#7940) via Antonio Pallares (@ajpallares)
* Decode the purchase a succeeded hosted checkout session made (#7937) via Antonio Pallares (@ajpallares)
* Show hosted checkout alerts from the paywall instead of the purchase button (#7928) via Antonio Pallares (@ajpallares)
* Fix crash in async PurchasesDelegateTests from MockOperationDispatcher race (#7964) via Antonio Pallares (@ajpallares)
* Bump CI to Ruby 3.3 (#7963) via Josh Holtz (@joshdholtz)
