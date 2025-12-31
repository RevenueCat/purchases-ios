## RevenueCat SDK
### 🐞 Bugfixes
* Fix translations of purchase button in Customer Center's promotional offers (#5974) via Cesar de la Vega (@vegaro)
* Fix HTTP request deduplication being non-deterministic on cache keys (#5975) via Andy Boedo (@aboedo)
* Fixed compilation of generated XCFramework because of synthesized Codable conformance in extension (#5971) via Rick (@rickvdl)
* Fix footer background image influencing footer height when using Fill / Fit mode (#5960) via Facundo Menzella (@facumenzella)

## RevenueCatUI SDK
### Paywallv2
#### 🐞 Bugfixes
* Fix Tabs component package inheritance for tabs without packages (#5929) via Facundo Menzella (@facumenzella)

### 🔄 Other Changes
* Remove `output_style` from `xcodebuild` calls in `test_revenuecatui` (#5978) via Cesar de la Vega (@vegaro)
* Updated reference snapshot for load shedder offerings response (#5973) via Rick (@rickvdl)
* Removed the use of @autoclosure from Logging methods in order to reduce binary size footprint (#5956) via Rick (@rickvdl)
