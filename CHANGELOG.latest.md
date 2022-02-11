- Third RC for RevenueCat framework v4 🎉
    100% Swift framework + ObjC support.

[Full Changelog](https://github.com/revenuecat/purchases-ios/compare/4.0.0-beta.rc.2...4.0.0-rc.3)
- See our [RevenueCat V4 API update doc](Documentation.docc/V4_API_Migration_guide.md) for API updates.

RC 3 introduces the following updates:

### API changes:

- Added `setCleverTapID`, for integration with CleverTap.
- Added `.noIntroOfferExists` as an `IntroEligibilityStatus`, for more granularity when checking for intro pricing eligibility.
- Added `StoreProductDiscount.type`, which allows you to easily tell whether a discount represents a Promo Offer or an Intro Pricing.

### Documentation: 

- Documentation can be found in https://revenuecat-docs.netlify.app/documentation/Revenuecat. 
- We've made several improvements to docstrings and added a few landing pages for the most important sections of the SDK. 

### Migration fixes

- Fixed a few instances where Xcode's automatic migration tools wouldn't automatically suggest a fix-it for updated code.

### Other changes: 
- There are lots of under the hood improvements. If you see any issues we'd appreciate [bug reports](https://github.com/RevenueCat/purchases-ios/issues/new?assignees=&labels=bug&template=bug_report.md&title=)!

### Changes from previous RC

These changes add to all of the changes from beta RC 2, [listed here.](https://github.com/RevenueCat/purchases-ios/blob/4.0.0-rc.2/CHANGELOG.latest.md).
