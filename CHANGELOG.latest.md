### New Features
* Added new `ReceiptParser.fetchAndParseLocalReceipt` (#2204) via NachoSoto (@NachoSoto)
* `PurchasesReceiptParser`: added API to parse receipts from `base64` string (#2200) via NachoSoto (@NachoSoto)
### Bugfixes
* `CustomerInfo`: support parsing schema version 2 to restore SDK `v3.x` compatibility (#2213) via NachoSoto (@NachoSoto)
### Other Changes
* `JSONDecoder`: added decoding type when logging `DecodingError.keyNotFound` (#2212) via NachoSoto (@NachoSoto)
* Added `ReceiptParserTests` (#2203) via NachoSoto (@NachoSoto)
* Deploy `PurchaseTester` for `macOS` (#2011) via NachoSoto (@NachoSoto)
* `ReceiptFetcher`: refactored implementation to log error when failing to fetch receipt (#2202) via NachoSoto (@NachoSoto)
* `PostReceiptDataOperation`: replaced receipt `base64` with `hash` for cache key (#2199) via NachoSoto (@NachoSoto)
* `PurchaseTester`: small refactor to simplify `Date` formatting (#2210) via NachoSoto (@NachoSoto)
* `PurchasesReceiptParser`: improved documentation to reference `default` (#2197) via NachoSoto (@NachoSoto)
* Created `CachingTrialOrIntroPriceEligibilityChecker` (#2007) via NachoSoto (@NachoSoto)
* Update Gemfile.lock (#2205) via Cesar de la Vega (@vegaro)
* remove stalebot in favor of SLAs in Zendesk (#2196) via Andy Boedo (@aboedo)
* Update fastlane-plugin-revenuecat_internal to latest version (#2194) via Cesar de la Vega (@vegaro)
