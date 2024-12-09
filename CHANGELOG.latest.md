## RevenueCat SDK
### ✨ New Features
* Adds `subscriptions` to `CustomerInfo` (#4508) via Cesar de la Vega (@vegaro)
### 🐞 Bugfixes
* [Paywalls] Fix PaywallTester compilation on Xcode 15 (#4540) via Mark Villacampa (@MarkVillacampa)
* Paywalls: Update Finnish "restore" localization (#4493) via Jeffrey Bunn (@Jethro87)

## RevenueCatUI SDK
### 🐞 Bugfixes
* Fix translucent navigation bar on paywalls by making it fully transparent (on iOS 16+) (#4543) via Josh Holtz (@joshdholtz)
* Fix build for app extensions (#4531) via Cesar de la Vega (@vegaro)
### Customer Center
#### 🐞 Bugfixes
* Adds missing revisionId to CustomerCenter impression event (#4537) via Cesar de la Vega (@vegaro)
* Customer Center deeplinks should always be opened externally (#4533) via Cesar de la Vega (@vegaro)
* Use `ManageSubscriptionsView` for users without active subscriptions (#4530) via Cesar de la Vega (@vegaro)

### 🔄 Other Changes
* run-test-ios-15 in xcode 15 to fix incompatibilities with emergetools (#4319) via Cesar de la Vega (@vegaro)
* WebPurchaseRedemption: Rename `alreadyRedeemed` result to `purchaseBelongsToOtherUser` (#4542) via Toni Rico (@tonidero)
* [Paywalls] Add previews for different combinations of vertical/horizontal alignment and flex distributions (#4538) via Mark Villacampa (@MarkVillacampa)
* Renames isDeeplink to isWebLink (#4535) via Cesar de la Vega (@vegaro)
* Update Package.resolved (#4534) via Cesar de la Vega (@vegaro)
* Add repo name (#4532) via Noah Martin (@noahsmartin)
* [Paywalls] Add Emerge Snapshot Tests (#4529) via Mark Villacampa (@MarkVillacampa)
* Adds API Test for `jwsRepresentation` in obj-c (#4526) via Andy Boedo (@aboedo)
* Create `CustomerCenterEvent` (#4392) via Cesar de la Vega (@vegaro)
* [Paywalls] Add support for gradient backgrounds (#4522) via Mark Villacampa (@MarkVillacampa)
