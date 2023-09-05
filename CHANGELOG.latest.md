### Bugfixes
* `DebugViewModel`: fixed runtime crash on iOS < 16 (#3139) via NachoSoto (@NachoSoto)
### Performance Improvements
* `PurchasesOrchestrator`: return early if receipt has no transactions when checking for promo offers (#3123) via Mark Villacampa (@MarkVillacampa)
* `Purchases`: don't clear intro eligibility / purchased products cache on first launch (#3067) via NachoSoto (@NachoSoto)
### Dependency Updates
* `SPM`: update `Package.resolved` (#3130) via NachoSoto (@NachoSoto)
### Other Changes
* `ReceiptParser`: fixed SPM build (#3144) via NachoSoto (@NachoSoto)
* `carthage_installation_tests`: optimize SPM package loading (#3129) via NachoSoto (@NachoSoto)
* `CI`: add workaround for `Carthage` timing out (#3119) via NachoSoto (@NachoSoto)
* `Integration Tests`: workaround to not lose debug logs (#3108) via NachoSoto (@NachoSoto)
