### Bugfixes
* Fix runtime crash in SK2TransactionListener in iOS < 15 (#3206) via Toni Rico (@tonidero)
### Performance Improvements
* `OperationDispatcher`: add support for "long" delays (#3168) via NachoSoto (@NachoSoto)
### Other Changes
* `Integration Tests`: add tests for ghost transfer behavior (#3135) via NachoSoto (@NachoSoto)
* `Xcode`: removed `purchases-ios` SPM reference (#3166) via NachoSoto (@NachoSoto)
* `Integration Tests`: another flaky failure (#3165) via NachoSoto (@NachoSoto)
* `Integration Tests`: fix flaky test failure due to leftover transaction (#3167) via NachoSoto (@NachoSoto)
* `Xcode 13`: removed last `Swift 5.7`  checks (#3161) via NachoSoto (@NachoSoto)
* `Integration Tests`: improve flaky tests (#3163) via NachoSoto (@NachoSoto)
* `Codable`: improved decoding errors (#3153) via NachoSoto (@NachoSoto)
* Refactor: extract `HealthOperation` (#3154) via NachoSoto (@NachoSoto)
* `Xcode 13`: remove conditional code (#3147) via NachoSoto (@NachoSoto)
* `CircleCI`: change all jobs to use `Xcode 14.x` and replace `xcode-install` with `xcodes` (#2421) via NachoSoto (@NachoSoto)
