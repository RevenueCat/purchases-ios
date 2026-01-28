## RevenueCat SDK
### ✨ New Features
* Add Galaxy to Store Enum (#6127) via Will Taylor (@fire-at-will)
### 🐞 Bugfixes
* Making sure that the SK2 StorefrontListener only calls the delegate when the storefront identifier actually changed (#6030) via Rick (@rickvdl)
* Fix date parsing to support ISO8601 with fractional seconds (#6120) via Josh Holtz (@joshdholtz)

### 🔄 Other Changes
* Remove CircleCI M1 macOS executors  (#6132) via Rick (@rickvdl)
* Introduce adyen to CI pipeline for public API changes detection (#5484) via Facundo Menzella (@facumenzella)
* Avoid public enums (#6140) via Facundo Menzella (@facumenzella)
* Simplify ad tracking API to fire-and-forget pattern for Swift and Obj-C (#6133) via Pol Miro (@polmiro)
* Small cleanup of `PurchasesOrchestrator` (#6135) via Antonio Pallares (@ajpallares)
* Fix `Decimal` precision issue in `LocalTransactionMetadata` on iOS 14 (#6138) via Antonio Pallares (@ajpallares)
* Add `paywall_id` to paywall events and POST /receipt requests (#6087) via Antonio Pallares (@ajpallares)
* Add payload_version to POST /receipt (#6130) via Antonio Pallares (@ajpallares)
* Improve accuracy of transactions origin Part 8: sync cached local transaction metadata (#6073) via Antonio Pallares (@ajpallares)
* Fix `CodingKeys` to work correctly with snake_case key decoding strategies (#6134) via Antonio Pallares (@ajpallares)
* Improve accuracy of transactions origin Part 7: add `sdk_originated` to POST /receipt (#6091) via Antonio Pallares (@ajpallares)
* Improve accuracy of transactions origin Part 6: add `transaction_id` to POST /receipt (#6023) via Antonio Pallares (@ajpallares)
* Improve accuracy of transactions origin Part 5: keep local transaction metadata when `CustomerInfo` is computed offline (#6131) via Antonio Pallares (@ajpallares)
* Add missing APITests for Exit Offers (#6128) via Facundo Menzella (@facumenzella)
* Improve accuracy of transactions origin Part 4: store transaction metadata when `PresentedOfferingContext` or paywall info are present (#6110) via Antonio Pallares (@ajpallares)
* Improve accuracy of transactions origin Part 3: remove `PurchaseSource` from `PurchasedTransactionData` and rename it to `PostReceiptSource` (#6076) via Antonio Pallares (@ajpallares)
* Added a swiftlint rule that disallows direct use of storage directory URL related APIs (#6113) via Rick (@rickvdl)
* Improve accuracy of transactions origin Part 2: store and fetch transaction metadata (#6014) via Antonio Pallares (@ajpallares)
* Improve accuracy of transactions origin Part 1: refactor to allow caching transaction metadata (#5940) via Antonio Pallares (@ajpallares)
* Fix paywall data misattributions  (#6119) via Antonio Pallares (@ajpallares)
* Add missing data attribution to SK2 purchases in Observer Mode (#6117) via Antonio Pallares (@ajpallares)
