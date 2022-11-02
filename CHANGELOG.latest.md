### New Features
* Introduced `PurchasesDiagnostics` to help diagnose SDK configuration errors (#1977) via NachoSoto (@NachoSoto)
### Bugfixes
* Avoid posting empty receipts by making`TransactionsManager` always use `SK1` implementation (#2015) via NachoSoto (@NachoSoto)
* `NetworkOperation`: workaround for iOS 12 crashes (#2008) via NachoSoto (@NachoSoto)
### Other Changes
* Makes hold job wait for installation tests to pass (#2017) via Cesar de la Vega (@vegaro)
* Update fastlane-plugin-revenuecat_internal (#2016) via Cesar de la Vega (@vegaro)
* `bug_report.md`: changed SK2 wording (#2010) via NachoSoto (@NachoSoto)
* Added `Set + Set` and `Set += Set` operators (#2013) via NachoSoto (@NachoSoto)
* fix the link to StoreKit Config file from watchOS purchaseTester (#2009) via Andy Boedo (@aboedo)
* `PurchaseTesterSwiftUI`: combined targets into one multi-platform and fixed `macOS` (#1996) via NachoSoto (@NachoSoto)
* Less Array() (#2005) via SabinaHuseinova (@SabinaHuseinova)
* Docs: fixed `logIn` references (#2002) via NachoSoto (@NachoSoto)
* CI: use `Xcode 14.1` (#1992) via NachoSoto (@NachoSoto)
* `PurchaseTesterSwiftUI`: fixed warnings and simplified code using `async` methods (#1985) via NachoSoto (@NachoSoto)
