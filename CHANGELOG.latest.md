- Second RC for RevenueCat framework v4 🎉
    100% Swift framework + ObjC support.

[Full Changelog](https://github.com/revenuecat/purchases-ios/compare/4.0.0-beta.rc.1...4.0.0-rc.2)
- See our [RevenueCat V4 API update doc](docs/V4_API_Updates.md) for API updates.

RC 2 introduces the following updates:

### API changes:

- Removed `SubscriptionPeriod.Unit.unknown`. Subscriptions with empty `SubscriptionPeriod` values will have `nil` `subscriptionPeriod` instead.
- Removed `StoreProductDiscount.none`, since it wasn't needed.
- Added `useStoreKit2IfAvailable` (Experimental) configuration option. This is disabled by default.
If enabled, the SDK will use StoreKit 2 APIs for purchases under the hood.
**This is currently in an experimental phase, and we don't recommend using it in production in this build.**

### Documentation: 

- Documentation is now using DocC and it can be found in https://revenuecat-docs.netlify.app/documentation/Revenuecat. 
- We've made several improvements to docstrings and added a few landing pages for the most important sections of the SDK. 

### Migration fixes

- Fixed a few instances where Xcode's automatic migration tools wouldn't correctly update the code.

### Other changes: 
- There are lots of under the hood improvements. If you see any issues we'd appreciate [bug reports](https://github.com/RevenueCat/purchases-ios/issues/new?assignees=&labels=bug&template=bug_report.md&title=)!

### Changes from previous RC

These changes add to all of the changes from beta RC 1, [listed here.](https://github.com/RevenueCat/purchases-ios/blob/4.0.0-rc.1/CHANGELOG.latest.md).
