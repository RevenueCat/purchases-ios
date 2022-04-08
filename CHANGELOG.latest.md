#### API updates:

- Added new method `setMixpanelDistinctID` as a convenience method for setting the required attribute for the Mixpanel integration #1397

- `getPromotionalOffer` has been deprecated in favor of `promotionalOffer` #1405

- `getEligiblePromotionalOffers` has been deprecated in favor of `eligiblePromotionalOffers` #1405

- `StoreProductDiscount` now includes the `numberOfPeriods` property #1428


#### Other:

- Added workaround for StoreKit 1 incorrectly reporting purchase cancellations #1450 

- MagicWeatherSwiftUI now includes an example for using `purchases(:shouldPurchasePromoProduct:defermentBlock:)` #1459

- Various documentation improvements

- Additional under-the-hood improvements, continuing to focus on network requests and tests.
