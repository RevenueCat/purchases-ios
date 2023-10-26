### New Features
* `PaywallColor`: change visibility of `Color.init(light:dark:)` to `private` (#3345) via NachoSoto (@NachoSoto)
* `Paywalls`: new `.onPurchaseCompleted` overload with `StoreTransaction` (#3323) via NachoSoto (@NachoSoto)
### RevenueCatUI
* `Paywalls`: finished template 5 (#3340) via NachoSoto (@NachoSoto)
* `Paywalls`: new `onDismiss` parameter for `presentPaywallIfNeeded` (#3342) via NachoSoto (@NachoSoto)
* `Paywalls`: add identifier to events (#3332) via Josh Holtz (@joshdholtz)
* `Paywalls`: disable shimmering on footer loading view (#3324) via NachoSoto (@NachoSoto)
### Bugfixes
* `ErrorUtils.purchasesError(withSKError:)`: handle `URLError`s (#3346) via NachoSoto (@NachoSoto)
* `Paywalls`: create new event session when paywall appears (#3330) via Josh Holtz (@joshdholtz)
### Other Changes
* `HTTPClient`: verbose logs for request IDs (#3320) via NachoSoto (@NachoSoto)
* `Paywalls Tester`: fix `macOS` build (#3341) via NachoSoto (@NachoSoto)
* `ProductFetcherSK1`: enable `TimingUtil` log (#3327) via NachoSoto (@NachoSoto)
* `Paywall Tester`: fixed paywall presentation (#3339) via NachoSoto (@NachoSoto)
* `CI`: replace Carthage build jobs with `xcodebuild` (#3338) via NachoSoto (@NachoSoto)
* `Integration Tests`: use repetition count from test plan (#3329) via NachoSoto (@NachoSoto)
* `Integration Tests`: new logs for troubleshooting flaky tests (#3328) via NachoSoto (@NachoSoto)
* `CircleCI`: change iOS 17 job to use M1 Large resource (#3322) via NachoSoto (@NachoSoto)
* `Paywalls Tester`: fix release build (#3321) via NachoSoto (@NachoSoto)
* `Paywalls`: enable all iOS 17 tests (#3331) via NachoSoto (@NachoSoto)
* `CI`: added workaround for Snapshots in `Xcode Cloud` (#2857) via NachoSoto (@NachoSoto)
* `StoreKit 1`: disabled `finishTransactions` log on observer mode (#3314) via NachoSoto (@NachoSoto)
