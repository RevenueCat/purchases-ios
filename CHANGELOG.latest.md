## RevenueCat SDK
### 🐞 Bugfixes
* Support non-JSON object decodable values in `getMetadataValue` (#4555) via Cody Kerns (@codykerns)

## RevenueCatUI SDK
### Customer Center
#### ✨ New Features
* Support toggling update warnings & show update in restore flow (#4571) via Will Taylor (@fire-at-will)
* Add feedback survey option chosen event (#4528) via Cesar de la Vega (@vegaro)
* Expose Customer Center to UIKit (#4560) via Will Taylor (@fire-at-will)
* [Customer Center] Slight improvement to the Customer Center Promotional Offer view (#4554) via Andy Boedo (@aboedo)
#### 🐞 Bugfixes
* Always reload customerInfo when Customer Center is loaded (#4575) via Will Taylor (@fire-at-will)
* Make presentCustomerCenter's onDismiss optional (#4573) via Will Taylor (@fire-at-will)
* Fix hardcoded title in WrongPlatformView (#4569) via Cesar de la Vega (@vegaro)
* Fix wrong discriminator on `CustomerCenterAnswerSubmittedEvent` (#4566) via Cesar de la Vega (@vegaro)

### 🔄 Other Changes
* Refactors the creation of the subscription details in Customer Center (#4515) via Cesar de la Vega (@vegaro)
* [Paywals] Update paywalls tester Package.resolved (#4570) via Mark Villacampa (@MarkVillacampa)
* [Paywalls] Fix iOS 13/14 tests (#4568) via Mark Villacampa (@MarkVillacampa)
* Customer Center DocC updates (#4564) via Will Taylor (@fire-at-will)
* Fix paywalls tester build in `main` (#4565) via Cesar de la Vega (@vegaro)
* Hide mode from public init in `CustomerCenterView` (#4563) via Cesar de la Vega (@vegaro)
* [EXTERNAL] Polished the Polish translation (#4496) via @miszu (#4556) via JayShortway (@JayShortway)
* Revert "Remove PaywallsTesterTests" (#4557) via Cesar de la Vega (@vegaro)
