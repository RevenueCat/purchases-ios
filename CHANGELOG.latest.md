### Bugfixes
* `PurchaseOrchestrator`: always refresh receipt purchasing in sandbox (#2280) via NachoSoto (@NachoSoto)
* `BundleSandboxEnvironmentDetector`: always return `true` when running on simulator (#2276) via NachoSoto (@NachoSoto)
* `OfferingsManager`: ensure underlying `OfferingsManager.Error.configurationError` is logged (#2266) via NachoSoto (@NachoSoto)
### Other Changes
* `UserDefaultsDefaultTests`: fixed flaky failures (#2284) via NachoSoto (@NachoSoto)
* `BaseBackendTest`: improved test failure message (#2285) via NachoSoto (@NachoSoto)
* Updated targets and schemes for Xcode 14.2 (#2282) via NachoSoto (@NachoSoto)
* `HTTPRequest.Path.health`: don't cache using `ETagManager` (#2278) via NachoSoto (@NachoSoto)
* `EntitlementInfos.all`: fixed docstring (#2279) via NachoSoto (@NachoSoto)
* `StoreKit2StorefrontListener`: added tests to fix flaky code coverage (#2265) via NachoSoto (@NachoSoto)
* `NetworkError`: added underlying error to description (#2263) via NachoSoto (@NachoSoto)
* Created `Signing.verify(message:hasValidSignature:with:)` (#2216) via NachoSoto (@NachoSoto)
