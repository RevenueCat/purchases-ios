## RevenueCat SDK
### ✨ New Features
* Add convenience method for setting PostHog User ID (#4679) via Cody Kerns (@codykerns)
### 🐞 Bugfixes
* fix: Do not lint deleted files (#4687) via Facundo Menzella (@facumenzella)
* fix: Set https urls for packages (#4669) via Facundo Menzella (@facumenzella)
* Add purchaseWithParams to PurchasesType (#4663) via Will Taylor (@fire-at-will)
* fix: Fix versions for swift-doc, snapshot-testing & nimble (#4661) via Facundo Menzella (@facumenzella)
* fix: Use custom label for CompatibilityContentUnavailableView (#4647) via Facundo Menzella (@facumenzella)
* Deprecate misnamed purchase(params) function in Obj-C (#4645) via Will Taylor (@fire-at-will)

## RevenueCatUI SDK
### ✨ New Features
* feat: Add View extension based on CompatibilityNavigationStack (#4677) via Facundo Menzella (@facumenzella)
* feat: Make CustomerCenterActionHandler optional for CustomerCenterNavigationLink (#4678) via Facundo Menzella (@facumenzella)
* feat: [CustomerCenter] Introduce CompatibilityLabeledContent (#4659) via Facundo Menzella (@facumenzella)
### Customer Center
#### ✨ New Features
* feat: [CustomerCenter] Introduce PurchaseHistory (#4686) via Facundo Menzella (@facumenzella)
* feat: [CustomerCenter] Introduce CustomerCenterNavigationLink (#4664) via Facundo Menzella (@facumenzella)
#### 🐞 Bugfixes
* fix: [CustomerCenter] Introduce NavigationOptions for custom navigation (#4682) via Facundo Menzella (@facumenzella)
* Revert changes to public Customer Center API (#4681) via Cesar de la Vega (@vegaro)
* [Customer Center]: fix navigation when embedded in `NavigationStack` (#4622) via Andy Boedo (@aboedo)
* fix: dismiss alert using binding instead of environment dismiss (#4653) via Facundo Menzella (@facumenzella)

### 🔄 Other Changes
* [Trusted Entitlements] Enable Trusted Entitlements by default (#4672) via Toni Rico (@tonidero)
* [Trusted Entitlements] Do not clear CustomerInfo upon enabling Trusted Entitlements (#4671) via Toni Rico (@tonidero)
* [Paywalls V2] Move image mask after sizing (#4675) via Josh Holtz (@joshdholtz)
* [Paywalls V2] Add masking (concave, convex, circle) and padding/margin to image (#4674) via Josh Holtz (@joshdholtz)
* [Paywalls V2] Use V1 default paywall when footers are used with V2 paywalls (#4667) via Josh Holtz (@joshdholtz)
* [Paywalls V2] Added V1 fallback paywall into Paywall V2 error logic (#4666) via Josh Holtz (@joshdholtz)
* Do not warn when using mac API keys (#4668) via Toni Rico (@tonidero)
* [Paywalls V2] Prefetch low res images (#4658) via Josh Holtz (@joshdholtz)
* [Paywalls V2] Convert Codable structs to classes (#4665) via Josh Holtz (@joshdholtz)
* [Paywalls V2] Icon Component (#4655) via Josh Holtz (@joshdholtz)
* [Paywalls] Tabs (multi-tier / toggle) component (#4648) via Josh Holtz (@joshdholtz)
* [Paywalls V2] Fix compilation errors (#4657) via Josh Holtz (@joshdholtz)
* [Paywalls V2] Accept number as font size for text (#4654) via Josh Holtz (@joshdholtz)
* [Paywalls] Add Badge Modifier (#4596) via Mark Villacampa (@MarkVillacampa)
* [Paywalls V2] Updated outdated image component properties (#4649) via Josh Holtz (@joshdholtz)
* [Paywalls V2] Updating UIConfig aliased colors to contain both light and dark (#4650) via Josh Holtz (@joshdholtz)
* [Paywalls V2] Fix vstack and hstack growing size when fit (#4646) via Josh Holtz (@joshdholtz)
* [Paywalls] Use CALayer-backed shadows and refactor Shape.swift (#4630) via Mark Villacampa (@MarkVillacampa)
* [Paywalls V2] Optionalizing padding, margin, and corner radius properties for safety (#4644) via Josh Holtz (@joshdholtz)
* [Paywalls V2] Decode rectangle corners as optional (#4640) via Josh Holtz (@joshdholtz)
