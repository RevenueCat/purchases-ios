## RevenueCat SDK
### 🐞 Bugfixes
* fix: preserve errors when Result's Success is inferred as optional (#7723) via Antonio Pallares (@ajpallares)

## RevenueCatUI SDK
### ✨ New Features
* feat(paywalls): add `offer_price_with_zero` variables (#7684) via Facundo Menzella (@facumenzella)
### 🐞 Bugfixes
* [EXTERNAL]  Announce the package selection state to VoiceOver (#7545) via @t9mike (#7701) via Facundo Menzella (@facumenzella)
* Fix original paywall footer layout on iOS 27 (#7700) via Josh Holtz (@joshdholtz)
* [EXTERNAL] Package terms as words instead of abbreviations (#7545) via @t9mike (#7698) via Facundo Menzella (@facumenzella)
* [EXTERNAL] Expose markdown links as VoiceOver custom actions (#7545) via @t9mike (#7680) via Facundo Menzella (@facumenzella)
### Paywallsv2
#### 🐞 Bugfixes
* fix: keep fixed stack size when overflow is scroll (#7652) via Facundo Menzella (@facumenzella)

### 🔄 Other Changes
* other(workflows): decode branch trigger action (#7613) via Facundo Menzella (@facumenzella)
* other: report what a checkpoint resolved to on the hit event (#7729) via Facundo Menzella (@facumenzella)
* Add the hosted checkout entry point the paywall can call (#7657) via Antonio Pallares (@ajpallares)
* Decode the hosted web checkout purchase button method (#7653) via Antonio Pallares (@ajpallares)
* Present the checkout web view in a bottom sheet (#7642) via Antonio Pallares (@ajpallares)
* Add the checkout web view host (#7623) via Antonio Pallares (@ajpallares)
* feat(checkpoints): add gate-focused checkpoint API (#7621) via Rick (@rickvdl)
* feat(checkpoints): distinguish back navigation from close actions (#7685) via Rick (@rickvdl)
* Skip StaticString tests (#7713) via Dave DeLong (@davedelong)
* refactor(checkpoints): remove checkpoint listener API (#7672) via Rick (@rickvdl)
* feat(checkpoints): Resolve the offering per workflow step (#7658) via Rick (@rickvdl)
* Warn when configure app user ID differs from cached ID (#7694) via Rick (@rickvdl)
* Apply the PaywallsTester entitlements file in the Tuist target (#7690) via Antonio Pallares (@ajpallares)
* other: echo step experiment params on workflow events (#7659) via Facundo Menzella (@facumenzella)
* Compare object keys by UTF-16 code unit in the rules engine (#7562) via Antonio Pallares (@ajpallares)
* [EXTERNAL] Add the decorative media paywall fixture and accessibility control view (#7545) via @t9mike (#7676) via Facundo Menzella (@facumenzella)
