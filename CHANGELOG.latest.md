### Fixes:
* `CustomerInfoResponseHandler`: return `CustomerInfo` instead of error if the response was successful (#1778) via NachoSoto (@NachoSoto)
* Error logging: `logErrorIfNeeded` no longer prints message if it's the same as the error description (#1776) via NachoSoto (@NachoSoto)
* fix another broken link in docC docs (#1777) via aboedo (@aboedo)
* fix links to restorePurchase (#1775) via aboedo (@aboedo)
* fix getProducts docs broken link (#1772) via aboedo (@aboedo)

### Improvements:
* `Logger`: wrap `message` in `@autoclosure` to avoid creating when `LogLevel` is disabled (#1781) via NachoSoto (@NachoSoto)

### Other changes:
* Lint: fixed `SubscriberAttributesManager` (#1774) via NachoSoto (@NachoSoto)