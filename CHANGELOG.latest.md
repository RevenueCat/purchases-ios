## RevenueCat SDK
### ✨ New Features
* Add `hasPaywall` property to `Offering` (#4847) via Antonio Pallares (@ajpallares)
### 🐞 Bugfixes
* Fix compilation issues in Xcode 16.3 beta (#4840) via Andy Boedo (@aboedo)
* Correctly set PaywallsTester app API key by the CI (#4822) via Antonio Pallares (@ajpallares)
### Customer Center
#### ✨ New Features
* feat: Add onClose handler support for CustomerCenter (#4850) via Facundo Menzella (@facumenzella)

## RevenueCatUI SDK
### 🐞 Bugfixes
* Add default refundWindowDuration to HelpPath.init (#4826) via Will Taylor (@fire-at-will)
### Paywallv2
#### 🐞 Bugfixes
* Add activity indicator to restore purchases button behavior (#4848) via Josh Holtz (@joshdholtz)
### Customer Center
#### ✨ New Features
* feat: Hide refund for purchases in trial period (#4823) via Facundo Menzella (@facumenzella)
* feat: Don't show refund if free subscription (#4805) via Facundo Menzella (@facumenzella)
* feat: Introduce refund window to control if a refund is offered for a purchase (#4784) via Facundo Menzella (@facumenzella)

### 🔄 Other Changes
* feat: disable postAttributionData requests when in UI preview mode (#4824) via Antonio Pallares (@ajpallares)
* chore: Disable EventsManagerIntegrationTests till fixed (#4852) via Facundo Menzella (@facumenzella)
* Run `all-tests` on `main` and notify Slack (#4849) via Cesar de la Vega (@vegaro)
* Fix potential wrong count on diagnosis sync (#4846) via Antonio Pallares (@ajpallares)
* [Paywalls] Always use normal stack if the relevant axis size is fit (#4842) via Mark Villacampa (@MarkVillacampa)
* Uses the remote version of `purchases-ios` for the SwiftUI sample app (#4841) via Pol Piella Abadia (@polpielladev)
* [Diagnostics] Add extra parameters to `applePurchaseAttempt` (#4835) via Antonio Pallares (@ajpallares)
* Use array instead of sets in diagnostics events (#4839) via Antonio Pallares (@ajpallares)
* chore: Add integration test for analytics events (#4830) via Facundo Menzella (@facumenzella)
* Update changelog with 4.43.3 and 4.43.4 (#4834) via Mark Villacampa (@MarkVillacampa)
* [Diagnostics] Add `requestedProductIds` and `notFoundProductIds` to `appleProductsRequest` (#4828) via Toni Rico (@tonidero)
* Add RCStoreMessageTypeWinBackOffer to Objc API Tester (#4827) via Will Taylor (@fire-at-will)
* chore: Enable force_unwrapping for SwiftLint (#4820) via Facundo Menzella (@facumenzella)
* chore: Delete .orig file and ignore in git ignore (#4821) via Facundo Menzella (@facumenzella)
* Post error test results to Slack (#4404) via Toni Rico (@tonidero)
* [Paywalls V2] Adds a note on publishing to the missing paywall error. (#4817) via JayShortway (@JayShortway)
* Adds `buildServer.json` to `.gitignore` (#4819) via JayShortway (@JayShortway)
* Empty strings in proxyURL parameters in `Local.xcconfig` (#4818) via Antonio Pallares (@ajpallares)
* [Paywalls] Use CSS linear-gradient spec to compute gradient start/end points (#4789) via Mark Villacampa (@MarkVillacampa)
* [Paywalls] Add support for shadows in image components (#4797) via Mark Villacampa (@MarkVillacampa)
* [Paywalls] Fix badge background not using the new background field instead of ba… (#4811) via Mark Villacampa (@MarkVillacampa)
* fix: workaround to allow using proxy URL in `Local.xcconfig` (#4810) via Antonio Pallares (@ajpallares)
