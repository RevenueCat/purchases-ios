## RevenueCat SDK
### 🐞 Bugfixes
* Fix offerings not being returned in the `offerings` property of the SDK Health Report (#5043) via Pol Piella Abadia (@polpielladev)
### Customer Center
#### ✨ New Features
* Add management URL to PurchaseInformation (#5080) via Facundo Menzella (@facumenzella)
* feat: Show subscription list instead of only the active subscription (#5050) via Facundo Menzella (@facumenzella)
#### 🐞 Bugfixes
* Split `PurchaseInformation.price` into `pricePaid` and `renewalPrice` (#5069) via Cesar de la Vega (@vegaro)
### Paywallv2
#### 🐞 Bugfixes
* Fix sheet view in v2 paywall not covering bottom safe area (#5064) via Antonio Pallares (@ajpallares)

## RevenueCatUI SDK
### Paywallv2
#### ✨ New Features
* Allow custom url on purchase button (#5092) via Josh Holtz (@joshdholtz)
### Customer Center
#### ✨ New Features
* Add support for cross product promotional offers (#5031) via Cesar de la Vega (@vegaro)
* feat: Introducing billing information for PurchaseInformation in CustomerCenter (#5066) via Facundo Menzella (@facumenzella)

### 🔄 Other Changes
* Move RevenueCatUI CustomerCenter mocks from test target to RevenueCatUI (#5103) via Facundo Menzella (@facumenzella)
* Bump fastlane-plugin-emerge from 0.10.6 to 0.10.8 (#5099) via dependabot[bot] (@dependabot[bot])
* Introduce ScrollViewWithOSBackground to reuse in Customer Center Views (#5102) via Facundo Menzella (@facumenzella)
* Add billingInformation for PurchaseInformation (#5100) via Facundo Menzella (@facumenzella)
* Fix watchOS tests (#5098) via Cesar de la Vega (@vegaro)
* PurchaseInformation conforms to Identifiable & Hashable (#5095) via Facundo Menzella (@facumenzella)
* Introduce SubscriptionDetailViewModel & BaseManageSubscriptionViewModel (#5091) via Facundo Menzella (@facumenzella)
* Fix some flaky tests (#5082) via Antonio Pallares (@ajpallares)
* Allow previews of paywalls without offerings previews (#4968) via Antonio Pallares (@ajpallares)
* Introduce PurchaseInformationCardView (#5090) via Facundo Menzella (@facumenzella)
* Compute active subscriptions for CustomerCenter (#5089) via Facundo Menzella (@facumenzella)
* Fix build issue of PaywallsTester app in visionOS (#5087) via Antonio Pallares (@ajpallares)
* Use dateFormatter inside PurchaseInformation (#5088) via Facundo Menzella (@facumenzella)
* Add expirationDate and renewalDate to PurchaseInformation (#5085) via Facundo Menzella (@facumenzella)
* Improve mock interface for CustomerCenterConfigData (#5079) via Facundo Menzella (@facumenzella)
* Fix build of RevenueCatUI from Xcode workspace (#5075) via Antonio Pallares (@ajpallares)
* Fix flakiness of `uuid` implementation (#5074) via Antonio Pallares (@ajpallares)
* revert 4087a9c (#5078) via Facundo Menzella (@facumenzella)
* Fix build issue in Xcode 14.3 (#5071) via Antonio Pallares (@ajpallares)
* Revert CircleCI machine type to medium (#5065) via Mark Villacampa (@MarkVillacampa)
* Split logic between webBilling and stripe (#5057) via Cesar de la Vega (@vegaro)
