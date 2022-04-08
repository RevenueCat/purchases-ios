#### API updates:

- Added new method `setMixpanelDistinctID` as a convenience method for setting the required attribute for the Mixpanel integration #1397

- Async promotional offer methods no longer include the `get` prefix #1405
  - `getPromotionalOffer` has been deprecated in favor of `promotionalOffer`
  - `getEligiblePromotionalOffers` has been deprecated in favor of `eligiblePromotionalOffers`

- `StoreProductDiscount` now includes the `numberOfPeriods` property #1428


#### Other:

- Added workaround for StoreKit 1 incorrectly reporting purchase cancellations #1450 

- MagicWeatherSwiftUI now includes an example for using `purchases(:shouldPurchasePromoProduct:defermentBlock:)` #1459

- Various documentation improvements

- Additional under-the-hood improvements, continuing to focus on network requests and tests.
