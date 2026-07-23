## RevenueCatUI SDK
### Paywallsv2
#### 🐞 Bugfixes
* Preserve background audio after videos close (#7197) via Cesar de la Vega (@vegaro)
* Reset bottom sheet content identity when switching sheets (#7216) via Cesar de la Vega (@vegaro)

### 🔄 Other Changes
* Rename workflow event names to singular (#7099) via Cesar de la Vega (@vegaro)
* Add `DangerousSettings(autoSyncPurchases:uiPreviewMode:useWorkflows:)` init (#7276) via Cesar de la Vega (@vegaro)
* Fix xcodeproj remove stale `PaywallWebViewAPI` references (#7277) via Cesar de la Vega (@vegaro)
* Remove unused draft paywall components (#7271) via Rick (@rickvdl)
* test: fix RevenueCatUI test compilation on older Xcode versions (#7272) via Cesar de la Vega (@vegaro)
* Retry `@RCGitBot please test` approval while CircleCI setup is still running (#7268) via Antonio Pallares (@ajpallares)
* refactor(paywalls): WebViewOrigin value type for origin gating (#7266) via Antonio Pallares (@ajpallares)
* fix(paywalls): open web_view bridge channel only after init is delivered (#7269) via Antonio Pallares (@ajpallares)
* feat(paywalls): web_view component view + view model, not yet wired (6/7) (#7232) via Jacob Rakidzich (@JZDesign)
* Deduplicate workflow font install during prewarming (#7259) via Rick (@rickvdl)
* feat(paywalls): web_view bridge session with document-reset lifecycle (5/7) (#7231) via Jacob Rakidzich (@JZDesign)
* Support Xcode 27 in Tuist-generated projects (#7208) via Antonio Pallares (@ajpallares)
* Chore(deps): Bump fastlane-plugin-revenuecat_internal from `9b928b6` to `b52fca5` (#7263) via dependabot[bot] (@dependabot[bot])
* Support Carthage from-source builds on Xcode 27 (#7051) via Antonio Pallares (@ajpallares)
* feat(paywalls): web_view schema component, not yet registered (4/7) (#7230) via Jacob Rakidzich (@JZDesign)
* feat(paywalls): web_view navigation/origin policy (3/7) (#7229) via Jacob Rakidzich (@JZDesign)
* feat(paywalls): add web_view wire envelope (2/7) (#7228) via Jacob Rakidzich (@JZDesign)
* fix(danger): don't crash on renamed production Swift files (#7262) via Antonio Pallares (@ajpallares)
* test(workflows): cover offline config behavior (default paywall cold, cached workflow warm) (#7250) via Facundo Menzella (@facumenzella)
* Chore(deps): Bump fastlane-plugin-revenuecat_internal from `9e334ff` to `9b928b6` (#7261) via dependabot[bot] (@dependabot[bot])
* feat(paywalls): internal web_view JSON value type (#7227) via Jacob Rakidzich (@JZDesign)
