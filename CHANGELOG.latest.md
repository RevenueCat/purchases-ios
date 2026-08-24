## RevenueCat SDK
### ✨ New Features
* feat: add confirmInScene & confirmInWindow purchase params (#4779) via Will Taylor (@fire-at-will)
* feat: Expose displayName and originalPurchaseDate on NonSubscriptionTransaction (#7471) via Facundo Menzella (@facumenzella)
* Track checkpoint hits through the analytics events pipeline (#7447) via Facundo Menzella (@facumenzella)

## RevenueCatUI SDK
### Paywallsv2
#### 🐞 Bugfixes
* Remove already-subscribed logic from paywalls (#7487) via Antonio Pallares (@ajpallares)
* fix(paywalls): render `product.offer_price` with the same currency format as other prices (#7270) via Cesar de la Vega (@vegaro)
* Fix workflows ignoring `zero_decimal_place_countries` (#7474) via Cesar de la Vega (@vegaro)
### Customer Center
#### 🐞 Bugfixes
* Fix Customer Center prices for subscriptions from different Apple IDs (#7427) via Cesar de la Vega (@vegaro)

### 🔄 Other Changes
* Add a transform entry point to the rules engine (#7486) via Antonio Pallares (@ajpallares)
* Add nested variable rc.lower fixture case (#7484) via Antonio Pallares (@ajpallares)
* [CI] Collapse the two check-api-changes jobs into one (#7476) via Antonio Pallares (@ajpallares)
* Add rc.entries and rc.fromEntries custom operators (#7435) via Antonio Pallares (@ajpallares)
* Raise an error for unresolved variables instead of degrading to null (#7460) via Antonio Pallares (@ajpallares)
* Adopt shared Renovate config (#7485) via Álvaro Brey (@AlvaroBrey)
* Add unwrapped rc.length fixture case (#7483) via Antonio Pallares (@ajpallares)
* Add rc.split custom operator (#7473) via Antonio Pallares (@ajpallares)
* Inject and refresh IAM tokens (#7440) via Dave DeLong (@davedelong)
* Implement IAM Login Operations (#7439) via Dave DeLong (@davedelong)
* HTTP Paths can change their absolute path based on IAM enablement (#7422) via Dave DeLong (@davedelong)
* IAM Login part 2 (#7410) via Dave DeLong (@davedelong)
* Fix Test run for watch and tvos (#7479) via Jacob Rakidzich (@JZDesign)
* Bump sdks-common-config to 4.6.1 to cache the mise toolchain (#7478) via Antonio Pallares (@ajpallares)
* Properly publish API modifications (no add/delete) in the SDK API feed (#7451) via Álvaro Brey (@AlvaroBrey)
* Chore: Walk the workflow tree to broadcast prewarming data (#7420) via Jacob Rakidzich (@JZDesign)
* Chore(Paywalls): Invoke the warmer from the coordinator (#7469) via Jacob Rakidzich (@JZDesign)
* [CI] Build the nine platform swiftinterfaces in parallel (#6454) via Antonio Pallares (@ajpallares)
* Fix(CI): Skip tests on unsupported os versions (#7477) via Jacob Rakidzich (@JZDesign)
* Chore: Create WebBundleCachePrewarmer (#7429) via Jacob Rakidzich (@JZDesign)
* Add rc.lower and rc.upper custom operators (#7436) via Antonio Pallares (@ajpallares)
* Fix(CI): Correct type and add compiler check for old xcode version support (#7462) via Jacob Rakidzich (@JZDesign)
* Chore: Signal purchases-ui on purchases configuration (#7407) via Jacob Rakidzich (@JZDesign)
* Chore: Set up mechanism for WebView Caching (started with Clearing) (#7409) via Jacob Rakidzich (@JZDesign)
* Rename the checkpoint event's `session_id` to `app_session_id` (#7459) via Cesar de la Vega (@vegaro)
* Add rc.length operator for strings and arrays (#7437) via Antonio Pallares (@ajpallares)
