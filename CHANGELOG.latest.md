## RevenueCat SDK
### 🐞 Bugfixes
* Fix `CustomerInfoManager` deadlock (#6276) via Cesar de la Vega (@vegaro)
* Fix xcode 14 build (#6275) via Cesar de la Vega (@vegaro)
* Remove locks on read and write UserDefaults operations in DeviceCache (#5959) via Cesar de la Vega (@vegaro)

## RevenueCatUI SDK
### Paywallv2
#### 🐞 Bugfixes
* Fix compilation error in VariableHandlerV2 offer price functions (#6283) via Cesar de la Vega (@vegaro)
* Fix displaying badge only in selected override and prevent fallback paywall for missing localizations (#6269) via Cesar de la Vega (@vegaro)
* Fix discount prices not respecting `showZeroDecimalPlacePrices` (#6261) via Cesar de la Vega (@vegaro)
* [Paywalls V2] Fix video playback glitch when URL changes (#6254) via Facundo Menzella (@facumenzella)
* Fix `product.offer_*` variables show intro offer price when ineligible (#6242) via Cesar de la Vega (@vegaro)

### 🔄 Other Changes
* Add AGENTS.md for AI coding agent guidelines (#6264) via Facundo Menzella (@facumenzella)
* Reduce parameter count in `VariableHandlerV2` and `TextComponentViewModel` (#6260) via Cesar de la Vega (@vegaro)
* Fix CI caching for xcbeautify and xcodes (#6280) via Antonio Pallares (@ajpallares)
* RCT Tester app: automate upload to TestFlight via CI (#6265) via Antonio Pallares (@ajpallares)
* Bump nokogiri from 1.18.10 to 1.19.1 (#6277) via dependabot[bot] (@dependabot[bot])
* RCT Tester app: add app icon (#6256) via Antonio Pallares (@ajpallares)
* RCT Tester app Part 4 - Add more APIs and features to the RCT Tester app (#6240) via Antonio Pallares (@ajpallares)
* RCT Tester app Part 3 - add different RevenueCat SDK integrations (#6191) via Antonio Pallares (@ajpallares)
* CI: Consolidate installation tests jobs (all but Carthage) (#6266) via Antonio Pallares (@ajpallares)
* Use existing hasPaywall property in PaywallsTester (#6270) via Facundo Menzella (@facumenzella)
* Fix PaywallsTester build errors in `CustomVariablesEditorView` (#6271) via Cesar de la Vega (@vegaro)
* Improve PaywallsTester list display and sorting (#6263) via Facundo Menzella (@facumenzella)
* CI: Unify visionOS build with tvOS/watchOS/macOS build job (#6268) via Antonio Pallares (@ajpallares)
