## RevenueCat SDK
### ✨ New Features
* feat(ads): add revenuecat mediator type (#8007) via Peter Porfy (@peterporfy)
### 🐞 Bugfixes
* fix(test-store): Forward Test Store purchase attribution context (#8020) via Álvaro Marco (@amarco90)
* fix(billing plans): use product.id in log messages (#8003) via Will Taylor (@fire-at-will)
### Checkpoints
#### 🐞 Bugfixes
* fix(checkpoints): suppress callbacks for terminal checkpoint errors (#7984) via Rick (@rickvdl)
* fix(checkpoints): respect preferred locale override in local rules (#7953) via Rick (@rickvdl)

## RevenueCatUI SDK
### Customer Center
#### 🐞 Bugfixes
* Fix Customer Center purchase details and action state (#7948) via Monika Mateska (@MonikaMateska)
* fix(customer-center): stop the hang on iOS 16 and 17 when the single-purchase screen opens purchase history (#7993) via Facundo Menzella (@facumenzella)

### 🔄 Other Changes
* test: fix CI failures on main (non-UIKit test compile, offline cache key regex) (#8050) via Toni Rico (@tonidero)
* Attribute workflow purchases to their launching checkpoint (#8037) via Cesar de la Vega (@vegaro)
* test(customer-center): fix preview tests compiling on Xcode 14.3.1 (#8046) via Monika Mateska (@MonikaMateska)
* fix(checkpoints): prevent presentation conflicts from blocking future calls (#8048) via Rick (@rickvdl)
* Rename simulated error checkpoint identifier (#8047) via JayShortway (@JayShortway)
* feat(customer-center): Render isolated Customer Center preview paywalls (#8015) via Monika Mateska (@MonikaMateska)
* chore: route CODEOWNERS review requests to owning teams (#8033) via Cesar de la Vega (@vegaro)
* Link RevenueCatUI in MagicWeatherSwiftUI (#8039) via Facundo Menzella (@facumenzella)
* feat(checkpoints): add `CheckpointResult` result container (#8035) via Rick (@rickvdl)
* docs(remote-config): clarify when diagnostics are enabled (#8004) via Rick (@rickvdl)
* other(paywalls-tester): list and open flows by id (#7962) via Facundo Menzella (@facumenzella)
* fix(checkpoints): localize default error presenter messages (#8032) via Rick (@rickvdl)
* fix(checkpoints): report workflow navigation failures without ending the flow (#8031) via Rick (@rickvdl)
* fix(checkpoints): route all errors through error presenter (#7994) via Rick (@rickvdl)
* refactor(checkpoints): simplify error presenter completion (#8012) via Rick (@rickvdl)
* feat(customer-center): Add isolated Customer Center preview data and actions (#8014) via Monika Mateska (@MonikaMateska)
* Migrate existing anonymous user IDs when logging in (#8017) via Dave DeLong (@davedelong)
* Chore(deps): Bump fastlane from 2.240.1 to 2.241.0 (#8019) via dependabot[bot] (@dependabot[bot])
* feat(ads): add new capture methods (#7988) via Peter Porfy (@peterporfy)
* fix(checkpoints): log unknown checkpoint hit as informational (#7970) via Rick (@rickvdl)
