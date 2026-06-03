## RevenueCat SDK
### ✨ New Features
* feat(test-store): Add support for free trials in Test Store (#6884) via Toni Rico (@tonidero)
* Add presented offering context to custom paywall events (#6707) via Rick (@rickvdl)
* feat(workflows): add WorkflowEvent model and wire format serialization (#6858) via Facundo Menzella (@facumenzella)
### 🐞 Bugfixes
* Fix Paywalls V2 root z-layer stacks not scrolling in bounded containers (#6873) via Monika Mateska (@MonikaMateska)
* fix(tests): add missing iOS 14/15 snapshots for BackendGetWorkflowsListTests (#6861) via Rick (@rickvdl)
### Storekit 2
#### ✨ New Features
* [Billing Plans] Support fetching & purchasing products with billing plans (#6783) via Will Taylor (@fire-at-will)

## RevenueCatUI SDK
### 🐞 Bugfixes
* Don't send interaction event for workflow trigger button actions (#6771) via Cesar de la Vega (@vegaro)
### Paywallv2
#### ✨ New Features
* feat(networking): add getWorkflows list endpoint (#6853) via Facundo Menzella (@facumenzella)
#### 🐞 Bugfixes
* fix workflow header transitions (#6880) via Facundo Menzella (@facumenzella)
* fix workflow page transitions (#6877) via Facundo Menzella (@facumenzella)

### 🔄 Other Changes
* feat(workflows): add WorkflowManager with list fetch, prefetch and offeringId resolution (#6882) via Facundo Menzella (@facumenzella)
* feat(workflows): add WorkflowsCache and disk persistence for workflows list (#6881) via Facundo Menzella (@facumenzella)
* feat(remote-config): add network scaffolding for GET /v2/config endpoint (#6854) via Rick (@rickvdl)
* Add JSON Logic string + array operators (#6793) via Antonio Pallares (@ajpallares)
* Fix flaky metadata-sync & consent-status unit tests (#6876) via Rick (@rickvdl)
* Chore(deps): Bump fastlane-plugin-revenuecat_internal from `af7bb5c` to `ce6a7ef` (#6879) via dependabot[bot] (@dependabot[bot])
* refactor: extract Offering.presentedOfferingContext helper and apply … (#6865) via Rick (@rickvdl)
* feat(ads): add rewarded-ad reward event types and AdTracker methods (#6843) via Pol Miro (@polmiro)
* Bump jwt from 2.10.1 to 3.2.0 in /Tests/InstallationTests/CocoapodsInstallation (#6848) via dependabot[bot] (@dependabot[bot])
* [AUTOMATIC][Paywalls V2] Updates commit hash of paywall-preview-resources (#6871) via RevenueCat Git Bot (@RCGitBot)
* Add JSON Logic comparison operators (<, <=, >, >=) (#6792) via Antonio Pallares (@ajpallares)
* Allow overriding PaywallsTester bundle ID via Tuist env var (#6869) via Facundo Menzella (@facumenzella)
* Add JSON Logic arithmetic operators (+, -, *, /, %) (#6791) via Antonio Pallares (@ajpallares)
* Lint: Enforce no-new-public-enums policy via SwiftLint custom rule (#6778) via Antonio Pallares (@ajpallares)
* RulesEngineInternal: add JSON Logic predicate evaluator (#6789) via Antonio Pallares (@ajpallares)
* Forbid plain `import RulesEngineInternal` via SwiftLint custom rule (#6788) via Antonio Pallares (@ajpallares)
* Add presentWorkflow for workflow (#6847) via Cesar de la Vega (@vegaro)
* Add RulesEngine skeleton module (#6787) via Antonio Pallares (@ajpallares)
