## RevenueCat SDK
### ✨ New Features
* Expose `autoResumeDate` and `productPlanIdentifier` on `SubscriptionInfo` (#7049) via Álvaro Brey (@AlvaroBrey)
* Log reward verification failure reason (#6892) via Pol Miro (@polmiro)
* Report ad event capture method (#7020) via Pol Miro (@polmiro)

## RevenueCatUI SDK
### ✨ New Features
* Preview paywalls via deep link (#6922) via Dave DeLong (@davedelong)
### Paywallv2
#### 🐞 Bugfixes
* Extract ImageRenderPlan and add unit tests (#7069) via Alexander Repty (@alexrepty)

### 🔄 Other Changes
* fix: align RulesEngineInternal with json-logic-js (undefined & missing_some) (#7066) via Antonio Pallares (@ajpallares)
* feat(remote-config): update request and response models according to spec (#7022) via Rick (@rickvdl)
* fix(ci): install pinned xcodes prebuilt binary for visionOS support (#7065) via Antonio Pallares (@ajpallares)
* feat(workflows): add workflows_close abandonment event (#7040) via Facundo Menzella (@facumenzella)
* test(ads): add api signature test for newly exposed reward primitives (#7045) via Peter Porfy (@peterporfy)
* Model entitlement reward variant in reward verification (#7038) via Pol Miro (@polmiro)
* Chore(deps): Bump nokogiri from 1.19.3 to 1.19.4 in /Tests/InstallationTests/CocoapodsInstallation (#7063) via dependabot[bot] (@dependabot[bot])
* Chore(deps): Bump concurrent-ruby from 1.3.6 to 1.3.7 in /Tests/InstallationTests/CocoapodsInstallation (#7062) via dependabot[bot] (@dependabot[bot])
* Send `presented_workflow_id` and `presented_step_id` in post-receipt body (#7024) via Cesar de la Vega (@vegaro)
* Chore(deps): Bump nokogiri from 1.19.3 to 1.19.4 (#7061) via dependabot[bot] (@dependabot[bot])
* Chore(deps): Bump danger from 9.5.3 to 9.6.0 (#7060) via dependabot[bot] (@dependabot[bot])
* feat(remote-config): support RC Container format in network stack and use for remote-config request (#7037) via Rick (@rickvdl)
* Bump sdks-common-config orb to 4.1.0 (#7050) via Álvaro Brey (@AlvaroBrey)
* feat(remote-config): add RC Container format V1 + parser (#7030) via Rick (@rickvdl)
* Upload paywall rendering validation screenshots to Emerge in PRs (#6979) via JayShortway (@JayShortway)
* Remove unused pollRewardVerificationStatus (#7042) via Pol Miro (@polmiro)
* Add Danger check to discourage large PRs (#7041) via Toni Rico (@tonidero)
* Update baseline swiftinterface files for `main` (#7036) via RevenueCat Git Bot (@RCGitBot)
* refactor(ads): reuse SDK retry classification for poll errors (#7009) via Antonio Pallares (@ajpallares)
* Migrate update_error_codes to the outputs parameter (#7035) via Álvaro Brey (@AlvaroBrey)
* refactor(ads): move reward verification to coresdk (#6895) via Peter Porfy (@peterporfy)
