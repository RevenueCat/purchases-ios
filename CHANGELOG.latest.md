#### API updates: 

- Added new method `checkTrialOrIntroDiscountEligibility(product:)`, which allows you to check for intro or discount eligibility for a single `StoreProduct`. 
    https://github.com/RevenueCat/purchases-ios/pull/1354

- Added explicit parameter name for `checkTrialOrIntroDiscountEligibility(productIdentifiers:)`. 
The existing method without the parameter name still work, but is now deprecated. Xcode will offer an auto fix-it for it. 
    https://github.com/RevenueCat/purchases-ios/pull/1362

- Made `StoreProduct` initializers public so they can be used for testing. 

#### Other:

- Added auto-fix-it for `invalidatePurchaserInfoCache` rename
    https://github.com/RevenueCat/purchases-ios/pull/1379

- Docs improvements
- A lot of under-the-hood improvements, mainly focusing on network requests and tests.
