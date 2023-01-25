### Bugfixes
* `IntroEligibilityCalculator`: fixed logic for subscriptions in same group (#2174) via NachoSoto (@NachoSoto)
* `PurchasesOrchestrator`: finish SK2 transactions from `StoreKit.Transaction.updates` after posting receipt (#2243) via NachoSoto (@NachoSoto)
### Other Changes
* `Purchases`: fixed documentation warnings (#2241) via NachoSoto (@NachoSoto)
* Code coverage (#2242) via NachoSoto (@NachoSoto)
* Improve logging for custom package durations (#2240) via Cody Kerns (@codykerns)
* `TrialOrIntroPriceEligibilityChecker`: use `TimingUtil` to log when it takes too long (#2238) via NachoSoto (@NachoSoto)
* Update `fastlane-plugin-revenuecat_internal` (#2239) via NachoSoto (@NachoSoto)
* Simplified `OperationDispatcher.dispatchOnMainActor` (#2236) via NachoSoto (@NachoSoto)
* `PurchaseTester`: added contents of `CHANGELOG.latest.md` to `TestFlight` changelog (#2233) via NachoSoto (@NachoSoto)
* `SystemInfo.isApplicationBackgrounded`: added overload for `@MainActor` (#2230) via NachoSoto (@NachoSoto)
