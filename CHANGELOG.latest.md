## RevenueCat SDK
### 🐞 Bugfixes
* [MON-1122] Changes the rounding mode to `.down` instead of `.plain` (#5821) via Pol Piella Abadia (@polpielladev)

## RevenueCatUI SDK
### Paywallv2
#### 🐞 Bugfixes
* Select default package on `BottomSheetView` dismissal (#5797) via Cesar de la Vega (@vegaro)
* Set paywall as non-scrolling if shorter than screen (#5857) via Cesar de la Vega (@vegaro)

### 🔄 Other Changes
* Bump fastlane from 2.228.0 to 2.229.0 (#5855) via dependabot[bot] (@dependabot[bot])
* Track `connection_error_reason` property in diagnostics for HTTP errors (#5860) via Rick (@rickvdl)
* Add client side timeout logic for endpoints that support fallback URLs (#5760) via Rick (@rickvdl)
* Prevent CI from editing root Package.resolved (#5856) via Antonio Pallares (@ajpallares)
* Fixed daily integration-tests-all run missing the Circle CI context (#5853) via Rick (@rickvdl)
* Bump fastlane-plugin-revenuecat_internal from `083ced9` to `efca663` (#5854) via dependabot[bot] (@dependabot[bot])
