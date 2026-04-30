## RevenueCat SDK
### ✨ New Features
* Add placement and targeting rule to paywall events (#6476) via Dan Pannasch (@dpannasch)
* Move paywall analytics APIs to Internal SPI (#6700) via Monika Mateska (@MonikaMateska)
### 🐞 Bugfixes
* Replace print with Logger.debug in ISODurationFormatter (#6691) via Facundo Menzella (@facumenzella)

## RevenueCatUI SDK
### 🐞 Bugfixes
* FIX: Optimize time to load paywalls (#6694) via Jacob Rakidzich (@JZDesign)
### Paywallsv2
#### ✨ New Features
* Add explicit directional step transitions to WorkflowPaywallView (#6703) via Facundo Menzella (@facumenzella)
* Add WorkflowPaywallView for multipage workflow step rendering (#6692) via Facundo Menzella (@facumenzella)
* Add workflowTrigger to ButtonComponent.Action (#6693) via Facundo Menzella (@facumenzella)
#### 🐞 Bugfixes
* Fix WorkflowTriggerAction.stepId to be optional (String?) (#6687) via Facundo Menzella (@facumenzella)
* Fix product.currency_symbol for mismatched formatter locales (#6572) via Facundo Menzella (@facumenzella)
### Customer Center
#### ✨ New Features
* Add workflow-based paywall resolution for multipage paywalls (#6640) via Facundo Menzella (@facumenzella)
#### 🐞 Bugfixes
* Fix Customer Center showing wrong management options for expired subscribers (#6674) via Facundo Menzella (@facumenzella)
### Paywallv2
#### ✨ New Features
* Add workflow-based paywall resolution (#6675) via Facundo Menzella (@facumenzella)

### 🔄 Other Changes
* Bump nokogiri from 1.19.2 to 1.19.3 (#6705) via dependabot[bot] (@dependabot[bot])
* Align workflow trigger matching with Android: typed enums + sealed WorkflowTriggerAction (#6698) via Facundo Menzella (@facumenzella)
* [AUTOMATIC][Paywalls V2] Updates commit hash of paywall-preview-resources (#6272) via RevenueCat Git Bot (@RCGitBot)
* Expose Logger to internal consumers (#6690) via Pol Miro (@polmiro)
* Delete claude.yml workflow (#6688) via Cesar de la Vega (@vegaro)
* Decode reward payload in RewardVerification poll response (#6678) via Pol Miro (@polmiro)
* Document Tuist environment variables in AGENTS.md (#6689) via Facundo Menzella (@facumenzella)
* Add WorkflowContext to surface full workflow state from PurchaseHandler (#6685) via Facundo Menzella (@facumenzella)
* Add workflowTriggerAction environment hook for button workflow triggers (#6684) via Facundo Menzella (@facumenzella)
* Add swiftinterface API diff tracking for RevenueCatUI (#6450) via Facundo Menzella (@facumenzella)
* Add WorkflowNavigator for multipage workflow step navigation (#6680) via Facundo Menzella (@facumenzella)
* Add id to PaywallButtonComponent (#6679) via Facundo Menzella (@facumenzella)
* Rename internal SSV symbols, URL and metric to RewardVerification (#6667) via Pol Miro (@polmiro)
